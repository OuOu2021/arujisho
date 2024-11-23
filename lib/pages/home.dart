import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:arujisho/cjconvert.dart';
import 'package:arujisho/providers/item_count_notifier.dart';
import 'package:arujisho/providers/search_history_notifier.dart';
import 'package:arujisho/widgets/dictionary_term.dart';
import 'package:arujisho/pages/word_detail_page.dart';
import 'package:arujisho/widgets/home_drawer.dart';
import 'package:arujisho/widgets/infinite_sliver_list.dart';
import 'package:arujisho/widgets/history_chips.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'package:clipboard_listener/clipboard_listener.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:provider/provider.dart';

class MyHomePage extends StatefulWidget {
  static const routeName = '/';
  final String? initialInput;
  const MyHomePage({super.key, this.initialInput});

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  late TextEditingController _controller;
  bool showScrollToTopButton = false;
  late ScrollController _scrollController;

  int _searchMode = 0;
  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;

    final databasesPath = await getDatabasesPath();
    final p = path.join(databasesPath, "arujisho.db");

    _db = await openDatabase(p, readOnly: true);
    return _db!;
  }

  /// 搜索新值前，处理搜索历史
  Future<void> _search(int mode) async {
    _searchMode = mode;
  }

  void _setSearchContent(String text) {
    _controller.value = TextEditingValue(
        text: text,
        selection:
            TextSelection.fromPosition(TextPosition(offset: text.length)));
  }

  Future<void> _cpListener() async {
    final clipboardData = await Clipboard.getData('text/plain');
    if (clipboardData == null) return; // 如果剪贴板中没有数据，直接返回

    final text = clipboardData.text;
    if (text == null || text.isEmpty) return; // 如果粘贴的内容不是文本或为空，直接返回

    const int maxTextLength = 15; // 设置一个最大文本长度阈值
    if (text.length > maxTextLength) return; // 如果粘贴的文本长度超过阈值，直接返回

    if (text == _controller.text) return; // 如果粘贴的内容与当前输入框内容相同，直接返回

    _setSearchContent(text); // 处理粘贴的文本内容
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialInput);
    _controller.addListener(() {
      setState(() {
        _search(0);
      });
    });
    _search(0);
    ClipboardListener.addListener(_cpListener);
    _scrollController = ScrollController(initialScrollOffset: 0);
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.offset > 1) {
      if (!showScrollToTopButton) {
        setState(() => showScrollToTopButton = true);
      }
    } else {
      if (showScrollToTopButton) {
        setState(() => showScrollToTopButton = false);
      }
    }
    // Logger().d('${_scrollController.position.pixels}}');
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    ClipboardListener.removeListener(_cpListener);
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var searchBarTrailing = <Widget>[
      Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: InkWell(
          onTap: () => _search(-1),
          onLongPress: () => showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('頻度コントロール'),
                content: TextField(
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp("[0-9]"))
                  ],
                  onChanged: (value) {
                    final v = int.tryParse(value);
                    if (v != null && v > 0) {
                      setState(() => _searchMode = v);
                    }
                  },
                  decoration: const InputDecoration(hintText: "頻度ランク（正整数）"),
                ),
              );
            },
          ),
          child: const Icon(BootstrapIcons.sort_down_alt),
        ),
      ),
    ];
    if (_controller.text.isNotEmpty) {
      searchBarTrailing.add(IconButton(
        icon: const Icon(Icons.clear, size: 20),
        onPressed: () => _controller.clear(),
      ));
    }

    return WillPopScope(
      onWillPop: () async {
        // final historyNotifier = Provider.of<SearchHistoryNotifier>(context, listen: false);
        // if (historyNotifier.isEmpty) return true;
        // final temp = historyNotifier.last;
        // historyNotifier.removeLast();
        // _setSearchContent(temp);
        return true;
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        drawer: buildDrawer(context),
        body: Stack(children: [
          NestedScrollView(
            controller: _scrollController,
            floatHeaderSlivers: true,
            headerSliverBuilder:
                (BuildContext context, bool innerBoxIsScrolled) => [
              SliverOverlapAbsorber(
                handle:
                    NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                sliver: _buildSliverAppBar(context, innerBoxIsScrolled),
              ),
              if (Provider.of<SearchHistoryNotifier>(context).isNotEmpty)
                SliverPersistentHeader(
                  pinned: true,
                  floating: true,
                  delegate: _StickyHeaderDelegate(
                    vsync: this,
                    minHeight: 70.0,
                    maxHeight: 120.0,
                    child: HistoryChips(
                      padding: const EdgeInsets.only(top: 85),
                      setText: (item) {
                        _setSearchContent(item);
                      },
                    ),
                  ),
                ),
            ],
            body: Builder(
              builder: (BuildContext context) {
                final innerScrollController =
                    PrimaryScrollController.of(context);

                return CupertinoScrollbar(
                  controller: innerScrollController,
                  child: CustomScrollView(
                    // physics: const NeverScrollableScrollPhysics(),
                    // controller: _scrollController,
                    slivers: [
                      // header是SliverAppBar是不需要显式写Injector

                      // SliverOverlapInjector(
                      //   // 这里注入SliverOverlapAbsorberHandle来处理重叠
                      //   handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                      //       context),
                      // ),

                      ListenableBuilder(
                        listenable: _controller,
                        builder: (BuildContext ctx, _) {
                          Widget body;

                          if (_controller.text.isEmpty) {
                            body = const SliverToBoxAdapter(
                                child: Center(
                                    child: Padding(
                              padding: EdgeInsets.only(top: 200.0),
                              child: Text(
                                "ご参考になりましたら幸いです",
                                style: TextStyle(fontSize: 18),
                              ),
                            )));
                          } else {
                            final searchData = _controller.text
                                .replaceAll("\\pc", "\\p{Han}")
                                .replaceAll("\\ph", "\\p{Hiragana}")
                                .replaceAll("\\pk", "\\p{Katakana}")
                                .split('')
                                .map<String>(
                                    (c) => cjdc.containsKey(c) ? cjdc[c]! : c)
                                .join();
                            Future<List<Map<String, dynamic>>> queryAuto(
                                int nextIndex, int pageSize) async {
                              if (nextIndex % pageSize != 0) return [];

                              final db = await database;
                              String searchField = 'word';
                              String method = "MATCH";
                              List<Map<String, dynamic>> result = [];
                              final searchQuery = searchData.toLowerCase();

                              if (RegExp(r'^[a-z]+$').hasMatch(searchQuery)) {
                                searchField = 'romaji';
                              } else if (RegExp(r'^[ぁ-ゖー]+$')
                                  .hasMatch(searchQuery)) {
                                searchField = 'yomikata';
                              } else if (RegExp(r'[\.\+\[\]\*\^\$\?]')
                                  .hasMatch(searchQuery)) {
                                method = 'REGEXP';
                              } else if (RegExp(r'[_%]')
                                  .hasMatch(searchQuery)) {
                                method = 'LIKE';
                              }

                              try {
                                if (method == "MATCH") {
                                  result = List.of(await db.rawQuery(
                                    'SELECT tt.word,tt.yomikata,tt.pitchData,'
                                    'tt.origForm,tt.freqRank,tt.idex,tt.romaji,imis.imi,imis.orig '
                                    'FROM (imis JOIN (SELECT * FROM jpdc '
                                    'WHERE ($searchField MATCH "$searchQuery*" OR r$searchField '
                                    'MATCH "${String.fromCharCodes(searchQuery.runes.toList().reversed)}*") '
                                    '${(_searchMode > 0 ? "AND _rowid_ >=$_searchMode" : "")} '
                                    'ORDER BY _rowid_ LIMIT $nextIndex, $pageSize'
                                    ') AS tt ON tt.idex=imis._rowid_)',
                                  ));
                                } else {
                                  result = List.of(await db.rawQuery(
                                    'SELECT tt.word,tt.yomikata,tt.pitchData,'
                                    'tt.origForm,tt.freqRank,tt.idex,tt.romaji,imis.imi,imis.orig '
                                    'FROM (imis JOIN (SELECT * FROM jpdc '
                                    'WHERE (word $method "$searchQuery" '
                                    'OR yomikata $method "$searchQuery" '
                                    'OR romaji $method "$searchQuery") '
                                    '${(_searchMode > 0 ? "AND _rowid_ >=$_searchMode" : "")} '
                                    'ORDER BY _rowid_ LIMIT $nextIndex,$pageSize'
                                    ') AS tt ON tt.idex=imis._rowid_)',
                                  ));
                                }

                                result = result.map((qRow) {
                                  final map = <String, dynamic>{};
                                  qRow.forEach(
                                      (key, value) => map[key] = value);
                                  return map;
                                }).toList();

                                int balancedWeight(
                                    Map<String, dynamic> item, int bLen) {
                                  return (item['freqRank'] *
                                          (item[searchField].startsWith(
                                                      searchQuery) &&
                                                  _searchMode == 0
                                              ? 100
                                              : 500) *
                                          pow(
                                              1.5 +
                                                  item['yomikata'].length /
                                                      bLen,
                                              _searchMode == 0 ? 2.5 : 0))
                                      .round();
                                }

                                int bLen = 1 << 31;
                                for (var w in result) {
                                  if (w['yomikata'].length < bLen) {
                                    bLen = w['yomikata'].length;
                                  }
                                }
                                result.sort((a, b) => balancedWeight(a, bLen)
                                    .compareTo(balancedWeight(b, bLen)));
                                return result;
                              } catch (e) {
                                return nextIndex == 0
                                    ? [
                                        {
                                          'word': 'EXCEPTION',
                                          'yomikata': '以下の説明をご覧ください',
                                          'pitchData': '',
                                          'freqRank': -1,
                                          'idex': -1,
                                          'romaji': '',
                                          'orig': 'EXCEPTION',
                                          'origForm': '',
                                          'imi': jsonEncode({
                                            'ヘルプ': [
                                              "LIKE 検索:\n"
                                                  "    _  任意の1文字\n"
                                                  "    %  任意の0文字以上の文字列\n"
                                                  "\n"
                                                  "REGEX 検索:\n"
                                                  "    .  任意の1文字\n"
                                                  "    .*  任意の0文字以上の文字列\n"
                                                  "    .+  任意の1文字以上の文字列\n"
                                                  "    \\pc	任意漢字\n"
                                                  "    \\ph	任意平仮名\n"
                                                  "    \\pk	任意片仮名\n"
                                                  "    []	候補。[]で括られた中の文字は、その中のどれか１つに合致する訳です\n"
                                                  "\n"
                                                  "例えば：\n"
                                                  " \"ta%_eru\" は、食べる、訪ねる、立ち上げる 等\n"
                                                  " \"[\\pc][\\pc\\ph]+る\" は、出来る、聞こえる、取り入れる 等\n"
                                            ],
                                            'Debug': [e.toString()],
                                          }),
                                        }
                                      ]
                                    : [];
                              }
                            }

                            final itemCountNotifier =
                                Provider.of<ItemCountNotifier>(context,
                                    listen: false);
                            // 考虑displayItemCountNotifier的值
                            final displayCount =
                                itemCountNotifier.displayItemCount;
                            final expandedItemCount =
                                itemCountNotifier.expandedItemCount;
                            body = InfiniteSliverList<Map<String, dynamic>>(
                              // itemExtent: 50.0,
                              onRequest: queryAuto,
                              itemBuilder: (context, item, index) {
                                final imiTmp = jsonDecode(item['imi'])
                                    as Map<String, dynamic>;

                                final imi = {
                                  for (var entry
                                      in imiTmp.entries.take(displayCount))
                                    entry.key: entry.value
                                };

                                final pitchData = item['pitchData'] != ''
                                    ? jsonDecode(item['pitchData'])
                                        .map((x) => x <= 20
                                            ? '⓪①②③④⑤⑥⑦⑧⑨⑩⑪⑫⑬⑭⑮⑯⑰⑱⑲⑳'[x]
                                            : '?')
                                        .toList()
                                        .join()
                                    : '';
                                final word = item['origForm'] == ''
                                    ? item['word']
                                    : item['origForm'];

                                return ListTile(
                                  title: Text(word == item['orig']
                                      ? word
                                      : '$word →〔${item['orig']}〕'),
                                  subtitle:
                                      Text("${item['yomikata']}$pitchData"),
                                  trailing: Text((item['freqRank']).toString()),
                                  onTap: () {
                                    final historyNotifier =
                                        Provider.of<SearchHistoryNotifier>(
                                            context,
                                            listen: false);
                                    historyNotifier.remove(_controller.text);
                                    historyNotifier.addToHead(_controller.text);
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      builder: (_) => WordDetailPage(
                                        word: word == item['orig']
                                            ? word
                                            : '$word →〔${item['orig']}〕',
                                        idex: item["idex"],
                                        yomikata: item["yomikata"],
                                        freqRank: item["freqRank"],
                                        details: List.from(imi.keys)
                                            .asMap()
                                            .entries
                                            .map<List<Widget>>((s) {
                                          final index1 = s.key;
                                          final dictName = s.value;
                                          return List<List<Widget>>.from(
                                            imi[dictName]
                                                .asMap()
                                                .entries
                                                .map((entry) {
                                              // final index2 = entry.key;
                                              final simi = entry.value;
                                              return <Widget>[
                                                DictionaryTerm(
                                                  dictName: dictName,
                                                  imi: simi,
                                                  queryWord: _setSearchContent,
                                                  initialExpanded: index1 <
                                                      expandedItemCount,
                                                )
                                              ];
                                            }),
                                          ).reduce((a, b) => a + b);
                                        }).reduce((a, b) => a + b),
                                      ),
                                    );
                                  },
                                );
                              },
                              key: ValueKey('${searchData}_$_searchMode'),
                            );
                          }
                          return body;
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Column(
            verticalDirection: VerticalDirection.up,
            children: [
              Align(
                alignment: Alignment.bottomCenter,
                child: BottomAppBar(
                  color: Colors.transparent,
                  // height: 80,
                  child: Column(
                    verticalDirection: VerticalDirection.up,
                    children: [
                      ClipRRect(
                        // 匹配searchBar的默认圆角大小
                        borderRadius: BorderRadius.circular(28.0),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 2.0),
                          child: SearchBar(
                              leading: const Padding(
                                  padding: EdgeInsets.only(left: 8.0),
                                  child: Icon(Icons.search, size: 20)),
                              backgroundColor: WidgetStatePropertyAll(
                                  Theme.of(context)
                                      .colorScheme
                                      .primaryContainer
                                      .withOpacity(.7)),
                              side: WidgetStatePropertyAll(BorderSide(
                                  width: 2.0,
                                  color: Theme.of(context).primaryColor)),
                              elevation: const WidgetStatePropertyAll(0.0),
                              hintText: "言葉を入力して検索する",
                              controller: _controller,
                              trailing: searchBarTrailing),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 20.0),
                  child: AnimatedOpacity(
                    opacity: showScrollToTopButton ? 1.0 : 0.0, // 使用透明度控制显隐
                    duration: const Duration(milliseconds: 300), // 动画时长
                    curve: Curves.easeInOut,
                    child: Visibility(
                      // visible: showScrollToTopButton,
                      child: Opacity(
                        opacity: 0.92,
                        child: FloatingActionButton(
                          onPressed: () {
                            if (showScrollToTopButton) _scrollToTop();
                          },
                          child: const Icon(Icons.arrow_upward),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ]),
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(
      BuildContext context, bool innerBoxIsScrolled) {
    return SliverAppBar(
      floating: true,
      pinned: true,
      snap: true,
      expandedHeight: 80,
      forceElevated: innerBoxIsScrolled,
      flexibleSpace: FlexibleSpaceBar(
        background: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 2.0), // 设置模糊强度
          child: Container(
            color: Colors.transparent,
          ),
        ),
        title: const Text(
          "ある辞書",
        ),
        centerTitle: true,
        expandedTitleScale: 1.3,
      ),
      actions: [
        IconButton(
          onPressed: () {
            Provider.of<SearchHistoryNotifier>(context, listen: false).clear();
          },
          tooltip: '履歴を全部削除',
          icon: const Icon(Icons.cleaning_services),
          iconSize: 24,
        )
      ],
      backgroundColor:
          Theme.of(context).colorScheme.primaryContainer.withOpacity(0.7),
      surfaceTintColor: Theme.of(context).colorScheme.primaryContainer,
      shadowColor: Theme.of(context).colorScheme.primaryContainer,
      scrolledUnderElevation: 2.0,
      elevation: 0.0,
    );
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double minHeight;
  final double maxHeight;
  @override
  final TickerProvider vsync;
  _StickyHeaderDelegate({
    required this.child,
    required this.minHeight,
    required this.maxHeight,
    required this.vsync,
  });

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => maxHeight;
  @override
  double get minExtent => minHeight;
  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }

  @override
  FloatingHeaderSnapConfiguration get snapConfiguration =>
      FloatingHeaderSnapConfiguration(
        curve: Curves.linear,
        duration: const Duration(milliseconds: 100),
      );
}
