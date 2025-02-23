import 'package:animate_do/animate_do.dart';
import 'package:dun_cookie_flutter/common/tool/color_theme.dart';
import 'package:dun_cookie_flutter/model/terra_comic_model.dart';
import 'package:dun_cookie_flutter/request/cookie_request.dart';
import 'package:flutter/material.dart';

import '../error/main.dart';
import 'ui/mange_list_card.dart';

class MangaListPage extends StatefulWidget {
  const MangaListPage({Key? key}) : super(key: key);
  static String routerName = "/manga";

  @override
  State<MangaListPage> createState() => _MangaListPageState();
}

class _MangaListPageState extends State<MangaListPage> {
  List<TerraComicModel> comicsList = [];

  //  加载状态 0一切正常 1正在加载 2加载失败
  int loadDataType = 0;

  @override
  void initState() {
    _getData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: gray_3,
      appBar: AppBar(
        //官方漫画页面
        backgroundColor: Colors.white,

        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => {Navigator.of(context).pop('刷新')}),
        leadingWidth: 50,
        iconTheme: const IconThemeData(
          color: DunColors.DunColor,
        ),

        titleTextStyle:
            const TextStyle(color: DunColors.DunColor, fontSize: 20),
        titleSpacing: 0,

        title: const Text("官方漫画"),
      ),
      body: Container(
        color: gray_3,
        child: loadDataType == 0
            ? ListView.builder(
                itemCount: comicsList.length,
                itemBuilder: (ctx, index) {
                  return FadeIn(
                      duration: const Duration(milliseconds: 1000),
                      child: MangaListCard(comicsList[index]));
                })
            : loadDataType == 1
                ? const Center(
                    child: Text("这是精美的加载动画"),
                  )
                : GestureDetector(
                    onTap: () {
                      _getData();
                    },
                    child: const Center(
                      child: Text("这是难受的报错动画"),
                    ),
                  ),
      ),
    );
  }

  //  获取数据
  _getData() async {
    setState(() {
      loadDataType = 1;
    });
    var data = await CookiesApi.getTerraComicList();
    if (data.isNotEmpty) {
      setState(() {
        comicsList = data;
        loadDataType = 0;
      });
    } else {
      setState(() {
        loadDataType = 2;
      });
      DunError(error: "漫画服务器断开");
    }
  }
}
