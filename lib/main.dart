import 'dart:async';
import 'dart:io';

import 'package:dun_cookie_flutter/common/tool/color_theme.dart';
import 'package:dun_cookie_flutter/common/tool/package_info.dart';
import 'package:dun_cookie_flutter/component/group_num_button.dart';
import 'package:dun_cookie_flutter/main_page/main_list/main_list_widget.dart';
import 'package:dun_cookie_flutter/main_page/more_list/more_list_widget.dart';
import 'package:dun_cookie_flutter/main_page/terminal_page/terminal_page_widget.dart';
import 'package:dun_cookie_flutter/model/ceobecanteen_data.dart';
import 'package:dun_cookie_flutter/model/user_settings.dart';
import 'package:dun_cookie_flutter/page/error/main.dart';
import 'package:dun_cookie_flutter/page/info/open_screen_info.dart';
import 'package:dun_cookie_flutter/page/update/main.dart';
import 'package:dun_cookie_flutter/provider/setting_provider.dart';
import 'package:dun_cookie_flutter/request/info_request.dart';
import 'package:dun_cookie_flutter/router/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobpush_plugin/mobpush_plugin.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Dialog/UpdataDialog.dart';
import 'common/constant/main.dart';
import 'dialog/UpdataInfoDialog.dart';
import 'provider/common_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  earlyInit().then((_) => runApp(const CeobeCanteenApp()));
}

Future<void> earlyInit() async {
  //沉浸式状态栏
  if (Platform.isAndroid) {
    SystemUiOverlayStyle systemUiOverlayStyle = const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // 状态栏颜色设置为透明
      statusBarIconBrightness: Brightness.dark, // 状态栏图标文字颜色设置为黑色
    );
    SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
  }

  if (Platform.isIOS) {
    await MobpushPlugin.setCustomNotification();

    // 开发环境 false, 线上环境 true
    await MobpushPlugin.setAPNsForProduction(true);
  }

  await SettingProvider.getInstance().readAppSetting();
}

class CeobeCanteenApp extends StatefulWidget {
  const CeobeCanteenApp({Key? key}) : super(key: key);

  @override
  State<CeobeCanteenApp> createState() => _CeobeCanteenAppState();
}

class _CeobeCanteenAppState extends State<CeobeCanteenApp> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<CommonProvider>(create: (_) => CommonProvider()),
        ChangeNotifierProvider.value(value: SettingProvider.getInstance()),
        ChangeNotifierProvider<CeobecanteenData>(
            create: (_) => CeobecanteenData()),
      ],
      child: MaterialApp(
        title: '小刻食堂',
        routes: DunRouter.routes,
        initialRoute: "/",
        onUnknownRoute: (settings) => MaterialPageRoute(
          builder: (context) => DunError(error: "404"),
        ),
      ),
    );
  }
}

//底部导航栏组件
class BottomNavBar extends StatefulWidget {
  const BottomNavBar({Key? key}) : super(key: key);

  @override
  _BottomNaacBarState createState() => _BottomNaacBarState();
}

class _BottomNaacBarState extends State<BottomNavBar> {
  /// ===========================先把旧代码copy过来start====================================
  @override
  void initState() {
    _init();
    super.initState();
  }

  _init() async {
    // 初始化设置
    _readData();
  }

  _readData() async {
    var settingData = Provider.of<SettingProvider>(context, listen: false);
    Constant.mobRId = settingData.appSetting.rid;
    bool? notOnce = settingData.appSetting.notOnce;
    if (notOnce!) {
      bool result = false;
      final completer = Completer<bool>();
      // 延迟到下一帧执行
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.push(context,
                MaterialPageRoute(builder: (context) => const OpenScreenInfo()))
            .then((value) => completer.complete(value));
      });
      result = await completer.future;
      if (!result) return;
      //申请权限
      if (await Permission.notification.request().isGranted) {
        // Either the permission was already granted before or the user just granted it.
        var status = await Permission.notification.status;
        print("Permission: " + status.toString());
      }
    }
    _checkVersion(notOnce);
  }

  // 判断版本号，强制更新&更新日志
  _checkVersion(bool notOnce) async {
    String nowVersion = await PackageInfoPlus.getVersion();
    DunApp nowApp = await InfoRequest.getAppVersionInfo(version: nowVersion);
    DunApp newApp = await InfoRequest.getAppVersionInfo();
    SharedPreferences sp = await SharedPreferences.getInstance();
    String? lastShowedVersion = sp.getString("update_dialog_showed_version");
    if (notOnce) {
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => UpdataDialog(
              oldVersion: nowApp.version,
              version: newApp.version,
              description: nowApp.description));
    }
    if (PackageInfoPlus.isVersionHigher(nowVersion, newApp.lastFocusVersion)) {
      Navigator.pushNamed(context, DunUpdate.routerName, arguments: newApp);
    } else {
      if (lastShowedVersion == null ||
          lastShowedVersion != nowVersion &&
              PackageInfoPlus.isVersionHigher(nowVersion, lastShowedVersion)) {
        if (nowApp.version?.isNotEmpty == true &&
            nowApp.description?.isNotEmpty == true) {
          showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => UpdataDialog(
                  oldVersion: nowApp.version,
                  version: newApp.version,
                  description: nowApp.description));
          sp.setString("update_dialog_showed_version", nowVersion);
        }
      }
    }
  }

  Widget _buildVersionUpdateDialog(String? version, String? description) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              "更新日志",
              style: TextStyle(
                color: Colors.orange,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text("版本号：$version"),
          const SizedBox(height: 8),
          const Text("本次更新内容："),
          Text(description ?? ""),
          const SizedBox(height: 16),
          const Center(child: GroupNumButton()),
        ],
      ),
    );
  }

  List<QuickJump> shortcutMenu = [];

  /// ===========================先把旧代码copy过来end====================================

  // 点击导航时显示指定内容
  List<Widget> list = [
    const MoreListWidget(),
    const MainListWidget(),
    const TerminalPageWidget()
  ];

  // 当前点击的导航下标
  int _currentController = 1;

  @override
  Widget build(BuildContext context) {
    double paddingTop = MediaQuery.of(context).padding.top;
    return Scaffold(
      //页面显示的主体内容
      body: Container(
        color: gray_3,
        padding: EdgeInsets.only(top: paddingTop),
        child: Selector<SettingProvider, bool>(
          selector: (context, provider) =>
              provider.appSetting.datasourceSetting != null,
          builder: (_, isDatasourceAvailable, __) {
            // TODO: 也可以传递 loading 布尔参数给子控件，让子控件自己显示进度条
            // 相应的，子控件的载入过程应该推迟到 didUpdateWidget() 时
            if (!isDatasourceAvailable) {
              return const Center(child: CircularProgressIndicator());
            }
            return Stack(
              children: [
                list[_currentController],
                ..._buildBottomBar(),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildBottomBar() {
    return [
      Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          height: 60,
          decoration: const BoxDecoration(color: white, boxShadow: [
            BoxShadow(
              color: Colors.black38,
              offset: Offset(0.0, 0.0),
              blurRadius: 15.0,
              spreadRadius: 1.0,
            )
          ]),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _currentController = 0),
                  child: Image.asset(
                    'assets/icon/more_list_icon.png',
                    width: 30,
                    height: 30,
                    color: _currentController == 0 ? yellow : gray_2,
                  ),
                ),
              ),
              const Expanded(child: SizedBox()),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _currentController = 2),
                  child: Image.asset(
                    'assets/icon/terminal_page_icon.png',
                    width: 30,
                    height: 30,
                    color: _currentController == 2 ? yellow : gray_2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      Align(
        alignment: Alignment.bottomCenter,
        child: GestureDetector(
          onTap: () => setState(() => _currentController = 1),
          child: Container(
            width: 83,
            height: 83,
            margin: const EdgeInsets.only(bottom: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: yellow,
                width: 2,
              ),
              color: _currentController == 1 ? yellow : white,
            ),
            child: Center(
              child: Image.asset(
                'assets/icon/main_list_icon.png',
                width: 57,
                height: 48,
                color: _currentController == 1 ? white : yellow,
              ),
            ),
          ),
        ),
      )
    ];
  }
}

class DunMain extends StatefulWidget {
  const DunMain({Key? key}) : super(key: key);

  @override
  State<DunMain> createState() => _DunMainState();
}

class _DunMainState extends State<DunMain> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider<CommonProvider>(
              create: (_) => CommonProvider()),
          ChangeNotifierProvider.value(value: SettingProvider.getInstance()),
          ChangeNotifierProvider<CeobecanteenData>(
              create: (_) => CeobecanteenData()),
        ],
        child: Consumer<SettingProvider>(
            builder: (context, settingModeProvider, _) {
          ThemeMode? themeMode;

          if (settingModeProvider.appSetting.darkMode == 1) {
            themeMode = ThemeMode.light;
          } else if (settingModeProvider.appSetting.darkMode == 2) {
            themeMode = ThemeMode.dark;
          } else {
            themeMode = null;
          }
          return MaterialApp(
            title: "小刻食堂",
            routes: DunRouter.routes,
            builder: (ctx, child) {
              return child!;
            },
            theme: DunTheme.themeList[0],
            darkTheme: DunTheme.darkThemeList[0],
            themeMode: themeMode,
            onUnknownRoute: (settings) =>
                MaterialPageRoute(builder: (context) => DunError(error: "404")),
            initialRoute: "/",
          );
        }));
  }
}
