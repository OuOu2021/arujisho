import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:arujisho/cjconvert.dart';
import 'package:arujisho/providers/display_item_notifier.dart';
import 'package:arujisho/providers/extended_item_notifier.dart';
import 'package:arujisho/providers/search_history_notifier.dart';
import 'package:arujisho/providers/theme_notifier.dart';
import 'package:arujisho/widgets/dictionary_term.dart';
import 'package:arujisho/widgets/infinite_list.dart';
import 'package:arujisho/pages/word_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'package:clipboard_listener/clipboard_listener.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:provider/provider.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  late TextEditingController _controller;
  late SearchHistoryNotifier _searchNotifier;

  int _searchMode = 0;
  Timer? _historyTimer;
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
    if (_controller.text.isEmpty) {
      if (_searchNotifier.isEmpty || _searchNotifier.last.isNotEmpty) {
        _searchNotifier.add("");
      }
      return;
    }
    if (_searchNotifier.isEmpty || _searchNotifier.last != _controller.text) {
      if (_historyTimer != null && _historyTimer!.isActive) {
        _historyTimer!.cancel();
        _searchNotifier.removeLast();
      }
      if (_searchNotifier.isNotEmpty && _searchNotifier.last.isEmpty) {
        _searchNotifier.removeLast();
      }
      // 查看5秒以上的单词才加入历史
      _historyTimer = Timer(const Duration(seconds: 3), () {});
      // if (_searchNotifier.isNotEmpty && _searchNotifier.last.isEmpty) {
      //   _searchNotifier.removeLast();
      // }
      _searchNotifier.add(_controller.text);
    }
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
    _controller = TextEditingController();
    _searchNotifier = SearchHistoryNotifier();
    _controller.addListener(() {
      setState(() {
        _search(0);
      });
    });
    ClipboardListener.addListener(_cpListener);
  }

  @override
  void dispose() {
    _historyTimer?.cancel();
    _historyTimer = null;
    _controller.dispose();
    ClipboardListener.removeListener(_cpListener);
    _searchNotifier.dispose();
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
        if (_historyTimer != null && _historyTimer!.isActive) {
          _historyTimer!.cancel();
          _historyTimer = null;
          _searchNotifier.removeLast();
          if (_searchNotifier.isEmpty) {
            _setSearchContent("");
          }
        }
        if (_searchNotifier.isEmpty) return true;
        while (_searchNotifier.last == _controller.text &&
            _searchNotifier.length > 1) {
          _searchNotifier.removeLast();
        }
        final temp = _searchNotifier.last;
        _searchNotifier.removeLast();
        _setSearchContent(temp);
        return false;
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: PreferredSize(
          preferredSize: Size(MediaQuery.of(context).size.width, 55),
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: AppBar(
                title: const Text(
                  "ある辞書",
                ),
                centerTitle: true,
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withOpacity(0.8),
                // surfaceTintColor: Colors.transparent,
                surfaceTintColor:
                    Theme.of(context).colorScheme.primaryContainer,
                // backgroundColor: Theme.of(context).colorScheme.surface,
                shadowColor: Theme.of(context).colorScheme.primaryContainer,
                // shadowColor: Colors.transparent,
                // shadowColor: Colors.black,
                scrolledUnderElevation: 2.0,
                elevation: 0.0,
              ),
            ),
          ),
        ),
        // 添加Drawer
        drawer: _buildDrawer(context),
        body: Stack(children: [
          ListenableBuilder(
            listenable: _searchNotifier,
            builder: (BuildContext ctx, _) {
              if (_searchNotifier.isEmpty || _searchNotifier.last == "") {
                return const Center(child: Text("ご参考になりましたら幸いです"));
              }
              final logger = Logger();
              logger.d("${_searchNotifier.history}");
              final last = _searchNotifier.last;
              final searchData = last
                  .replaceAll("\\pc", "\\p{Han}")
                  .replaceAll("\\ph", "\\p{Hiragana}")
                  .replaceAll("\\pk", "\\p{Katakana}")
                  .split('')
                  .map<String>((c) => cjdc.containsKey(c) ? cjdc[c]! : c)
                  .join();
              Future<List<Map<String, dynamic>>> queryAuto(
                  int nextIndex) async {
                const pageSize = 18;
                if (nextIndex % pageSize != 0) return [];

                final db = await database;
                String searchField = 'word';
                String method = "MATCH";
                List<Map<String, dynamic>> result = [];
                final searchQuery = searchData.toLowerCase();

                if (RegExp(r'^[a-z]+$').hasMatch(searchQuery)) {
                  searchField = 'romaji';
                } else if (RegExp(r'^[ぁ-ゖー]+$').hasMatch(searchQuery)) {
                  searchField = 'yomikata';
                } else if (RegExp(r'[\.\+\[\]\*\^\$\?]')
                    .hasMatch(searchQuery)) {
                  method = 'REGEXP';
                } else if (RegExp(r'[_%]').hasMatch(searchQuery)) {
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
                      'ORDER BY _rowid_ LIMIT $nextIndex,${2 * pageSize}'
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
                    qRow.forEach((key, value) => map[key] = value);
                    return map;
                  }).toList();

                  int balancedWeight(Map<String, dynamic> item, int bLen) {
                    return (item['freqRank'] *
                            (item[searchField].startsWith(searchQuery) &&
                                    _searchMode == 0
                                ? 100
                                : 500) *
                            pow(1.5 + item['yomikata'].length / bLen,
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
                            'expanded': true
                          }
                        ]
                      : [];
                }
              }

              final displayItemCountNotifier =
                  Provider.of<DisplayItemCountNotifier>(context, listen: false);
              // 考虑displayItemCountNotifier的值
              final displayCount = displayItemCountNotifier.displayItemCount;
              final expandedItemCountProvider =
                  Provider.of<ExpandedItemCountNotifier>(context,
                      listen: false);
              final expandedItemCount =
                  expandedItemCountProvider.expandedItemCount;
              return Padding(
                padding: const EdgeInsets.all(4.0),
                child: InfiniteList<Map<String, dynamic>>(
                  onRequest: queryAuto,
                  itemBuilder: (context, item, index) {
                    final imiTmp =
                        jsonDecode(item['imi']) as Map<String, dynamic>;

                    final imi = {
                      for (var entry in imiTmp.entries.take(displayCount))
                        entry.key: entry.value
                    };

                    final pitchData = item['pitchData'] != ''
                        ? jsonDecode(item['pitchData'])
                            .map((x) =>
                                x <= 20 ? '⓪①②③④⑤⑥⑦⑧⑨⑩⑪⑫⑬⑭⑮⑯⑰⑱⑲⑳'[x] : '?')
                            .toList()
                            .join()
                        : '';
                    final word = item['origForm'] == ''
                        ? item['word']
                        : item['origForm'];

                    return ListTile(
                      // initiallyExpanded:
                      //     item.containsKey('expanded') && item['expanded'],
                      title: Text(word == item['orig']
                          ? word
                          : '$word →〔${item['orig']}〕'),
                      subtitle: Text("${item['yomikata']}$pitchData"),
                      trailing: Text((item['freqRank']).toString()),
                      // onExpansionChanged: (expanded) {
                      //   FocusManager.instance.primaryFocus?.unfocus();
                      //   setState(() => item['expanded'] = expanded);
                      // },
                      onTap: () {
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
                                imi[dictName].asMap().entries.map((entry) {
                                  // final index2 = entry.key;
                                  final simi = entry.value;
                                  return <Widget>[
                                    DictionaryTerm(
                                      dictName: dictName,
                                      imi: simi,
                                      queryWord: _setSearchContent,
                                      initialExpanded:
                                          index1 < expandedItemCount,
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
                ),
              );
            },
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: BottomAppBar(
              color: Colors.transparent,
              child: ClipRRect(
                // 匹配searchBar的默认圆角大小
                borderRadius: BorderRadius.circular(28.0),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                  child: SearchBar(
                      leading: const Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: Icon(Icons.search, size: 20)),
                      backgroundColor: WidgetStatePropertyAll(Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withOpacity(.7)),
                      side: WidgetStatePropertyAll(BorderSide(
                          width: 2.0, color: Theme.of(context).primaryColor)),
                      elevation: const WidgetStatePropertyAll(0.0),
                      hintText: "言葉を入力して検索する",
                      controller: _controller,
                      trailing: searchBarTrailing),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // 构建Drawer
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.64,
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: const Text(
              '設定',
              style: TextStyle(
                fontSize: 24,
              ),
            ),
          ),
          // 主题模式设置
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text('テーマモード設定'),
            subtitle: Consumer<ThemeNotifier>(
              builder: (context, themeProvider, child) {
                return DropdownButtonFormField<ThemeMode>(
                  value: themeProvider.themeMode,
                  items: const [
                    DropdownMenuItem<ThemeMode>(
                      value: ThemeMode.system,
                      child: Text('システムに従う'),
                    ),
                    DropdownMenuItem<ThemeMode>(
                      value: ThemeMode.light,
                      child: Text('明るいモード'),
                    ),
                    DropdownMenuItem<ThemeMode>(
                      value: ThemeMode.dark,
                      child: Text('暗いモード'),
                    ),
                  ],
                  onChanged: (ThemeMode? value) {
                    if (value != null) {
                      themeProvider.setThemeMode(value);
                    }
                  },
                );
              },
            ),
          ),
          // 显示条目数
          ListTile(
            leading: const Icon(Icons.list),
            // title: const Text('表示件数'),
            subtitle: Consumer<DisplayItemCountNotifier>(
              builder: (context, displayProvider, child) {
                return DropdownButtonFormField<int>(
                  value: displayProvider.displayItemCount,
                  decoration: const InputDecoration(
                    labelText: '表示件数',
                  ),
                  items: [
                    const DropdownMenuItem<int>(
                      value: myInf,
                      child: Text('すべて表示'),
                    ),
                    ...List.generate(6, (index) {
                      int value = index + 1;
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text('$value'),
                      );
                    }),
                  ],
                  onChanged: (int? value) {
                    if (value != null) {
                      displayProvider.setDisplayItemCount(value);
                    }
                  },
                );
              },
            ),
          ),

          // 详细显示条目数
          ListTile(
            leading: const Icon(Icons.list_alt),
            // title: const Text('展開件数'),
            subtitle: Consumer<ExpandedItemCountNotifier>(
              builder: (context, expendedProvider, child) {
                return DropdownButtonFormField<int?>(
                  value: expendedProvider.expandedItemCount,
                  decoration: const InputDecoration(
                    labelText: '展開件数',
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: myInf,
                      child: Text('すべて展開表示'),
                    ),
                    ...List.generate(6, (index) {
                      int value = index + 1;
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text('$value'),
                      );
                    }),
                  ],
                  onChanged: (int? value) {
                    if (value != null) {
                      expendedProvider.setExpandedItemCount(value);
                    }
                  },
                );
              },
            ),
          ),
          // 关于
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('アプリについて'),
            onTap: () {
              Navigator.pop(context); // 关闭Drawer
              Navigator.pushNamed(context, '/about');
            },
          ),
        ],
      ),
    );
  }
}
