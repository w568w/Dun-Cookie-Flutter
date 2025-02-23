import 'dart:async';
import 'dart:io';

import 'package:dun_cookie_flutter/common/tool/color_theme.dart';
import 'package:dun_cookie_flutter/common/tool/package_info.dart';
import 'package:dun_cookie_flutter/page/error/main.dart';
import 'package:dun_cookie_flutter/page/main/home/main_list_widget.dart';
import 'package:dun_cookie_flutter/page/main/more/more_list_widget.dart';
import 'package:dun_cookie_flutter/page/main/terminal/terminal_page_widget.dart';
import 'package:dun_cookie_flutter/model/ceobecanteen_data.dart';
import 'package:dun_cookie_flutter/page/screeninfo/open_screen_info.dart';
import 'package:dun_cookie_flutter/provider/setting_provider.dart';
import 'package:dun_cookie_flutter/request/info_request.dart';
import 'package:dun_cookie_flutter/router/router.dart';
import 'package:fk_user_agent/fk_user_agent.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobpush_plugin/mobpush_plugin.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Dialog/UpdataDialog.dart';
import 'common/constant/main.dart';
import 'dialog/TapStarDialog.dart';
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

  await SettingProvider.getInstance().readAppSetting();

  await FkUserAgent.init();
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
      Permission.notification.request();
    }else{
      if (Platform.isIOS) {
        MobpushPlugin.setCustomNotification();
        // 开发环境 false, 线上环境 true
        MobpushPlugin.setAPNsForProduction(true);
      }
    }
    _checkVersion();
  }

  // 判断版本号，强制更新&更新日志
  _checkVersion() async {
    String nowVersion = await PackageInfoPlus.getVersion();
    DunApp newApp = await InfoRequest.getAppVersionInfo();
    SharedPreferences sp = await SharedPreferences.getInstance();
    String? lastShowedVersion = sp.getString("update_dialog_showed_version");
    if (Platform.isIOS) {
      int? openNumber = sp.getInt("number_of_openings");
      if (openNumber != null) {
        if (openNumber > 0) {
          sp.setInt("number_of_openings", openNumber + 1);
        }
        if (openNumber == 10) {
          showDialog(context: context, builder: (_) => TapStartDialog());
          // 先不用重置 统计一下吧
          // sp.setInt("number_of_openings",-1);
        }
      } else {
        sp.setInt("number_of_openings", 1);
      }
    }
    if (lastShowedVersion != null && nowVersion != lastShowedVersion) {
      DunApp nowApp = await InfoRequest.getAppVersionInfo(version: nowVersion);
      showDialog(
          context: context,
          builder: (_) => UpdataInfoDialog(
                version: nowApp.version,
                description: nowApp.description,
              ));
      sp.setString("update_dialog_showed_version", nowVersion);
    }
    if (PackageInfoPlus.isVersionHigher(newApp.lastForceVersion, nowVersion)) {
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => UpdataDialog(
                oldVersion: nowVersion,
                newApp: newApp,
                isFocus: true,
              ));
    } else if (PackageInfoPlus.isVersionHigher(newApp.version, nowVersion)) {
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => UpdataDialog(
                oldVersion: nowVersion,
                newApp: newApp,
                isFocus: false,
              ));
    }
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
              return const Center(child: CircularProgressIndicator(
                color: DunColors.DunColor,
              ));
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
    double paddingBottom = MediaQuery.of(context).padding.bottom;

    return [
      Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          padding: EdgeInsets.only(bottom: paddingBottom),
          height: 60 + paddingBottom,
          decoration: const BoxDecoration(color: white, boxShadow: [
            BoxShadow(
              color: Colors.black38,
              offset: Offset(0.0, 0.0),
              blurRadius: 15.0,
              spreadRadius: 1.0,
            )
          ]),
          child: Container(
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
          )),
        ),
      ),
      Container(
          padding: EdgeInsets.only(bottom: paddingBottom),
          child: Align(
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
                    color: _currentController == 1 ? yellow : gray_2,
                    width: 2,
                  ),
                  color: _currentController == 1 ? yellow : white,
                ),
                child: Center(
                  child: Image.asset(
                    'assets/icon/main_list_icon.png',
                    width: 57,
                    height: 48,
                    color: _currentController == 1 ? white : gray_2,
                  ),
                ),
              ),
            ),
          ))
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
