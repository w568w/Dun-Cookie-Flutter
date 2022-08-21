import 'package:animate_do/animate_do.dart';
import 'package:dun_cookie_flutter/common/tool/color_theme.dart';
import 'package:dun_cookie_flutter/model/ceobecanteen_data.dart';
import 'package:dun_cookie_flutter/page/tool/tool_countdown.dart';
import 'package:dun_cookie_flutter/page/tool/tool_grid.dart';
import 'package:dun_cookie_flutter/page/tool/tool_resource.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DunTool extends StatefulWidget {
  const DunTool({Key? key}) : super(key: key);
  static String routeName = "/tool";

  @override
  State<DunTool> createState() => _DunToolState();
}

class _DunToolState extends State<DunTool> {
  bool? checkedBoxValue = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FadeIn(
      child: Consumer<CeobecanteenData>(
        builder: (context, data, child) {
          if (data.ceobecanteenInfo != null) {
            CeobecanteenData ceobecanteenInfo = data.ceobecanteenInfo!;
            return Column(
              children: [
                // ToolAnnouncement(ceobecanteenInfo.list!),
                Expanded(
                  child: ListView(
                    children: [
                      if (ceobecanteenInfo.app == null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text(
                              "以下数据为离线数据",
                              style: DunStyles.text16C,
                            ),
                          ],
                        ),
                      // 物资是否开放
                      ToolResource(ceobecanteenInfo.dayInfo),
                      // 倒计时
                      if (ceobecanteenInfo.dayInfo != null &&
                          ceobecanteenInfo.dayInfo!.countdown != null)
                        ToolCountdown(ceobecanteenInfo.dayInfo!.countdown!),
                      // 官方源
                      if (ceobecanteenInfo.sourceInfo != null)
                        ToolGrid(
                          "饼的发源地",
                          linkInfo: ceobecanteenInfo.sourceInfo,
                        ),
                      // 快捷工具
                      if (ceobecanteenInfo.quickJump != null)
                        ToolGrid(
                          "在线第三方工具",
                          linkInfo: ceobecanteenInfo.quickJump,
                        ),
                      //推荐视频
                      if (ceobecanteenInfo.btnList != null)
                        ToolGrid("视频推荐",
                            type: 1, videoInfo: ceobecanteenInfo.btnList)
                    ],
                  ),
                )
              ],
            );
          }
          return const Center(
            child: Text("正在获取，请稍后"),
          );
        },
      ),
    );
  }
}
