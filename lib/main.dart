import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:arujisho/prividers/tts_cache_provider.dart';
import 'package:arujisho/word_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:clipboard_listener/clipboard_listener.dart';
import 'package:kana_kit/kana_kit.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:expandable/expandable.dart';
import 'package:provider/provider.dart';

import 'package:arujisho/splash_screen.dart';
import 'package:arujisho/ffi.io.dart';
import 'package:arujisho/cjconvert.dart';
import 'package:arujisho/ruby_text/ruby_text.dart';
import 'package:arujisho/ruby_text/ruby_text_data.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // make navigation bar transparent
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  // make flutter draw behind navigation bar
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (_) => ThemeNotifier(),
      ),
      ChangeNotifierProvider(create: (_) => DisplayItemCountNotifier()),
      ChangeNotifierProvider(create: (_) => ExpandedItemCountNotifier()),
      Provider<Logger>(
          create: (_) => Logger(printer: PrettyPrinter(), level: Level.debug
              // filter: DevelopmentFilter(),
              )),
      Provider<TtsCacheProvider>(
        create: (_) => TtsCacheProvider(),
      )
    ],
    child: const MyApp(),
  ));
}

class ThemeNotifier extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  static const String _themeModeKey = 'themeMode';

  ThemeMode get themeMode => _themeMode;

  ThemeNotifier() {
    _init();
  }

  Future<void> _init() async {
    await _loadThemeMode();
    notifyListeners(); // Notify listeners after loading the theme mode
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _saveThemeMode();
    notifyListeners();
  }

  Future<void> _saveThemeMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(_themeModeKey, _themeMode.name);
  }

  Future<void> _loadThemeMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? themeModeName = prefs.getString(_themeModeKey);
    if (themeModeName != null) {
      switch (themeModeName) {
        case 'system':
          _themeMode = ThemeMode.system;
          break;
        case 'light':
          _themeMode = ThemeMode.light;
          break;
        case 'dark':
          _themeMode = ThemeMode.dark;
          break;
      }
    } else {
      _themeMode = ThemeMode.system;
    }
  }
}

const int myInf = 999;

class DisplayItemCountNotifier extends ChangeNotifier {
  int _displayItemCount = myInf;
  static const String _displayItemCountKey = 'displayItemCount';

  int get displayItemCount => _displayItemCount;

  DisplayItemCountNotifier() {
    _init();
  }

  Future<void> _init() async {
    await _loadDisplayItemCount();
    notifyListeners(); // Notify listeners after loading the theme mode
  }

  Future<void> setDisplayItemCount(int i) async {
    _displayItemCount = i;
    await _saveDisplayItemCount();
    notifyListeners();
  }

  Future<void> _saveDisplayItemCount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt(_displayItemCountKey, _displayItemCount);
  }

  Future<void> _loadDisplayItemCount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int displayItemCount = prefs.getInt(_displayItemCountKey)!;
    _displayItemCount = displayItemCount;
  }
}

class ExpandedItemCountNotifier extends ChangeNotifier {
  int _expandedItemCount = 3;
  static const String _expandedItemCountKey = 'expandedItemCount';

  int get expandedItemCount => _expandedItemCount;

  ExpandedItemCountNotifier() {
    _init();
  }

  Future<void> _init() async {
    await _loadExpandedItemCount();
    notifyListeners(); // Notify listeners after loading the theme mode
  }

  Future<void> setExpandedItemCount(int i) async {
    _expandedItemCount = i;
    await _saveExpandedItemCount();
    notifyListeners();
  }

  Future<void> _saveExpandedItemCount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt(_expandedItemCountKey, _expandedItemCount);
  }

  Future<void> _loadExpandedItemCount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int expandedItemCount = prefs.getInt(_expandedItemCountKey)!;
    _expandedItemCount = expandedItemCount;
  }
}

class MyApp extends StatelessWidget {
  static const isRelease = true;

  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    const font = "NotoSansJP";
    const indigo = Colors.indigo;
    return MaterialApp(
      title: 'ある辞書',
      theme: ThemeData(
        drawerTheme: DrawerThemeData(
          surfaceTintColor: indigo[200],
        ),
        fontFamily: font,
        brightness: Brightness.light,
        colorSchemeSeed: indigo,
        // appBarTheme: AppBarTheme(
        //     scrolledUnderElevation: 6.0, surfaceTintColor: Colors.transparent),
        // shadowColor: Colors.transparent,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        drawerTheme: DrawerThemeData(surfaceTintColor: indigo[800]),
        fontFamily: font,
        colorSchemeSeed: indigo,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      themeMode: themeNotifier.themeMode,
      initialRoute: '/splash',
      routes: {
        '/': (context) => const MyHomePage(),
        '/splash': (context) => const SplashScreen(),
        '/about': (context) => const AboutPage(),
      },
    );
  }
}

typedef RequestFn<T> = Future<List<T>> Function(int nextIndex);
typedef ItemBuilder<T> = Widget Function(
    BuildContext context, T item, int index);

class InfiniteList<T> extends StatefulWidget {
  final RequestFn<T> onRequest;
  final ItemBuilder<T> itemBuilder;

  const InfiniteList({
    Key? key,
    required this.onRequest,
    required this.itemBuilder,
  }) : super(key: key);

  @override
  InfiniteListState<T> createState() => InfiniteListState<T>();
}

class InfiniteListState<T> extends State<InfiniteList<T>> {
  List<T> items = [];
  bool end = false;
  bool showScrollToTopButton = false; // 控制返回顶部按钮的显示
  late ScrollController _scrollController; // 用于监听滚动

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener); // 添加滚动监听器
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
  }

  void _scrollListener() {
    if (_scrollController.offset > 150) {
      if (!showScrollToTopButton) {
        Future.microtask(() => {setState(() => showScrollToTopButton = true)});
      }
    } else {
      if (showScrollToTopButton) {
        Future.microtask(() => {setState(() => showScrollToTopButton = false)});
      }
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _getMoreItems() async {
    final moreItems = await widget.onRequest(items.length);
    if (!mounted) return;

    if (moreItems.isEmpty) {
      setState(() => end = true);
      return;
    }
    setState(() => items = [...items, ...moreItems]);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Scrollbar(
        thickness: 8.0,
        radius: const Radius.circular(6.0),
        child: ListView.builder(
          padding: const EdgeInsets.only(bottom: 120, top: 83),
          controller: _scrollController, // 绑定滚动控制器
          itemBuilder: (context, index) {
            if (index < items.length) {
              return widget.itemBuilder(context, items[index], index);
            } else if (index == items.length && end) {
              if (items.isEmpty) {
                return const Center(child: Text('一致する検索結果はありません'));
              } else {
                return const Center(child: Text('以上です'));
              }
            } else {
              _getMoreItems();
              return const Center(child: CircularProgressIndicator());
            }
          },
          itemCount: items.length + 1,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        ),
      ),
      Positioned(
        bottom: 100,
        right: 16,
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
    ]);
  }
}

class DictionaryTerm extends StatefulWidget {
  final String dictName;
  final String imi;
  final Function(String) queryWord;
  final bool initialExpanded;

  const DictionaryTerm({
    Key? key,
    required this.dictName,
    required this.imi,
    required this.queryWord,
    this.initialExpanded = false,
  }) : super(key: key);

  @override
  DictionaryTermState createState() => DictionaryTermState();
}

class DictionaryTermState extends State<DictionaryTerm> {
  late final ExpandableController _expandControl;
  List<List<Map<String, String>>>? tokens;
  bool showFurigana = false;
  static const _kanaKit = KanaKit();

  @override
  void initState() {
    super.initState();
    _expandControl =
        ExpandableController(initialExpanded: widget.initialExpanded);
  }

  @override
  void dispose() {
    _expandControl.dispose();
    super.dispose();
  }

  Future<void> _doMorphAnalyze() async {
    final sp = path.join(
        (await getApplicationSupportDirectory()).path, "sudachi.json");
    final t = <List<Map<String, String>>>[];
    for (final row in widget.imi.split('\n')) {
      if (row.isNotEmpty) {
        final tt = <Map<String, String>>[];
        if (!_kanaKit.isRomaji(row)) {
          final lls = await sudachiAPI.parse(data: row, configPath: sp);
          for (final token in lls) {
            tt.add({
              "begin": token[0],
              "end": token[1],
              "POS": token[2],
              "surface": token[3],
              "norm": token[4],
              "reading": _kanaKit.toHiragana(token[5])
            });
          }
        } else {
          tt.add({
            "begin": '0',
            "end": (row.length - 1).toString(),
            "POS": "",
            "surface": row,
            "norm": ""
          });
        }
        t.add(tt);
      }
    }
    setState(() => tokens = t);
  }

  void _switchFurigana() {
    if (tokens == null) {
      _doMorphAnalyze();
    }
    setState(() => showFurigana = !showFurigana);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 0, bottom: 10),
      child: ExpandablePanel(
        theme: const ExpandableThemeData(
          iconPadding: EdgeInsets.zero,
          // iconSize: Theme.of(context).textTheme.titleLarge?.fontSize,
          expandIcon: Icons.arrow_drop_down,
          collapseIcon: Icons.arrow_drop_up,
          // iconColor: Theme.of(context).unselectedWidgetColor,
          headerAlignment: ExpandablePanelHeaderAlignment.center,
        ),
        controller: _expandControl,
        header: Wrap(children: [
          Padding(
            padding: const EdgeInsets.only(left: 6.0),
            child: InkWell(
              onTap: _switchFurigana,
              child: Container(
                decoration: BoxDecoration(
                  color: (MyApp.isRelease ^ (showFurigana && tokens == null))
                      ? Colors.red[600]
                      : Colors.blue[400],
                  borderRadius: const BorderRadius.all(Radius.circular(4)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                  child: Text(
                    widget.dictName,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ]),
        collapsed: const SizedBox.shrink(),
        expanded: Padding(
          padding: const EdgeInsets.only(top: 2, left: 10, bottom: 4),
          child: showFurigana && tokens != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: tokens!
                      .map<RubyText>((sentence) => RubyText(
                            style: const TextStyle(fontSize: 13.5),
                            sentence.map<RubyTextData>((token) {
                              if (token['POS']!.contains('記号') ||
                                  token['POS']!.contains('空白') ||
                                  _kanaKit.isRomaji(token['surface']!)) {
                                return RubyTextData(token['surface']!);
                              } else if (_kanaKit.isKana(token['surface']!)) {
                                return RubyTextData(token['surface']!,
                                    onTap: () =>
                                        widget.queryWord(token['norm']!));
                              }
                              return RubyTextData(token['surface']!,
                                  ruby: token['reading'],
                                  onTap: () =>
                                      widget.queryWord(token['norm']!));
                            }).toList(),
                          ))
                      .toList(),
                )
              : SelectableText(widget.imi,
                  style: const TextStyle(fontSize: 12),
                  toolbarOptions:
                      const ToolbarOptions(copy: true, selectAll: false)),
        ),
      ),
    );
  }
}

class SearchHistoryNotifier extends ChangeNotifier {
  final List<String> _history = [""];

  List<String> get history => List.unmodifiable(_history);
  bool get isEmpty => _history.isEmpty;
  bool get isNotEmpty => _history.isNotEmpty;
  String get last => _history.last;
  int get length => _history.length;

  void add(String item) {
    _history.add(item);
    notifyListeners();
  }

  void clear() {
    _history.clear();
    notifyListeners();
  }

  void removeLast() {
    if (_history.isNotEmpty) {
      _history.removeLast();
      notifyListeners();
    }
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  late TextEditingController _controller;
  late SearchHistoryNotifier _searchNotifier;

  static const _kanaKit = KanaKit();
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
              logger.d("${_searchNotifier._history}");
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
                  value: themeProvider._themeMode,
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

// 添加 About 页面
class AboutPage extends StatelessWidget {
  const AboutPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 使用 Scaffold 提供返回按钮
    return Scaffold(
      appBar: AppBar(
        title: const Text('アプリについて'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: <Widget>[
            const Text(
              '作者: emc2314, OuOu2021',
              style: TextStyle(fontSize: 18),
            ),
            // const SizedBox(height: 10),
            // const Text(
            //   // TODO: 找原作者确定开源协议
            //   'Version: ${await getAppVersion()}',
            //   style: TextStyle(fontSize: 18),
            // ),
            const SizedBox(height: 10),
            const Text(
              // TODO: 找原作者确定开源协议
              'License: Unknown',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                // 这里可以实现打开GitHub主页的功能，例如使用 url_launcher 包
              },
              child: const Text(
                'GitHub主页: https://github.com/OuOu2021/arujisho',
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue,
                    decoration: TextDecoration.underline),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
