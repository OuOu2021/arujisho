import 'dart:async';
import 'dart:math';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as Path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:clipboard_listener/clipboard_listener.dart';
import 'package:html/parser.dart' show parse;
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:kana_kit/kana_kit.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:crypto/crypto.dart' show sha256;
import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:icofont_flutter/icofont_flutter.dart';
import 'package:expandable/expandable.dart';

import 'package:arujisho/splash_screen.dart';
import 'package:arujisho/ffi.io.dart';
import 'package:arujisho/cjconvert.dart';
import 'package:arujisho/ruby_text/ruby_text.dart';
import 'package:arujisho/ruby_text/ruby_text_data.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  static const isRelease = true;

  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'ある辞書',
        theme: isRelease
            ? ThemeData(
                primarySwatch: Colors.blue,
                primaryColorLight: Colors.blue,
                primaryColorDark: Colors.blue,
                appBarTheme: const AppBarTheme(
                  backgroundColor: Colors.blue,
                ),
                inputDecorationTheme: const InputDecorationTheme(
                  fillColor: Colors.white,
                ),
                fontFamily: "NotoSansJP")
            : ThemeData(
                colorScheme: ColorScheme.fromSwatch().copyWith(
                  primary: Colors.pink[300],
                  secondary: Colors.pinkAccent[100],
                ),
                fontFamily: "NotoSansJP"),
        darkTheme: ThemeData(
            primarySwatch: Colors.blue,
            brightness: Brightness.dark,
            primaryColorDark: Colors.blue,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.black,
            ),
            // 配置深色主题
            scaffoldBackgroundColor: Colors.white12,
            fontFamily: "NotoSansJP"
            // 其他主题属性
            ),
        themeMode: ThemeMode.system,
        initialRoute: '/splash',
        routes: {
          '/': (context) => const MyHomePage(),
          '/splash': (context) => const SplashScreen(),
        });
  }
}

typedef RequestFn<T> = Future<List<T>> Function(String data, int nextIndex);
typedef ItemBuilder<T> = Widget Function(
    BuildContext context, T item, int index);

class InfiniteList<T> extends StatefulWidget {
  final RequestFn<T> onRequest;
  final ItemBuilder<T> itemBuilder;
  final ValueNotifier<String> textNotifier;

  const InfiniteList({
    Key? key,
    required this.onRequest,
    required this.itemBuilder,
    required this.textNotifier,
  }) : super(key: key);

  @override
  InfiniteListState<T> createState() => InfiniteListState<T>();
}

class InfiniteListState<T> extends State<InfiniteList<T>> {
  List<T> items = [];
  bool end = false;
  late String _displayText;

  _getMoreItems() async {
    final moreItems = await widget.onRequest(_displayText, items.length);
    if (!mounted) return;

    if (moreItems.isEmpty) {
      setState(() => end = true);
      return;
    }
    setState(() => items = [...items, ...moreItems]);
  }

  @override
  void initState() {
    super.initState();
    // 初始化时同步 textNotifier 的初始值
    _displayText = widget.textNotifier.value;
    // 监听 textNotifier 的变化并更新 WidgetB 的状态
    widget.textNotifier.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.textNotifier.removeListener(_onTextChanged); // 移除监听器
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _displayText = widget.textNotifier.value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemBuilder: (context, index) {
        if (index < items.length) {
          return widget.itemBuilder(context, items[index], index);
        } else if (index == items.length && end) {
          return const Center(child: Text('以上です'));
        } else {
          _getMoreItems();
          return const SizedBox(
            child: Center(
                child: Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator())),
          );
        }
      },
      itemCount: items.length + 1,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    );
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
    _expandControl = ExpandableController(
      initialExpanded: widget.initialExpanded,
    );
  }

  @override
  void dispose() {
    _expandControl.dispose();
    super.dispose();
  }

  _doMorphAnalyze() async {
    String sp = Path.join(
        (await getApplicationSupportDirectory()).path, "sudachi.json");
    List<List<Map<String, String>>> t = [];
    for (String row in widget.imi.split('\n')) {
      if (row.isNotEmpty) {
        List<Map<String, String>> tt = [];
        if (!_kanaKit.isRomaji(row)) {
          var lls = await sudachiAPI.parse(data: row, configPath: sp);
          for (var token in lls) {
            var j = {
              "begin": token[0],
              "end": token[1],
              "POS": token[2],
              "surface": token[3],
              "norm": token[4],
              "reading": _kanaKit.toHiragana(token[5])
            };
            tt.add(j);
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
    setState(() {
      tokens = t;
    });
  }

  _switchFurigana() async {
    if (tokens == null) {
      _doMorphAnalyze();
    }
    setState(() {
      showFurigana = !showFurigana;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 0,
        bottom: 10,
      ),
      child: ExpandablePanel(
        theme: ExpandableThemeData(
          iconPadding: EdgeInsets.zero,
          iconSize: Theme.of(context).textTheme.titleLarge?.fontSize,
          expandIcon: Icons.arrow_drop_down,
          collapseIcon: Icons.arrow_drop_up,
          iconColor: Theme.of(context).unselectedWidgetColor,
          headerAlignment: ExpandablePanelHeaderAlignment.center,
        ),
        controller: _expandControl,
        header: Wrap(children: [
          InkWell(
              onTap: _switchFurigana,
              child: Container(
                  decoration: BoxDecoration(
                      color:
                          (MyApp.isRelease ^ (showFurigana && tokens == null))
                              ? Colors.red[600]
                              : Colors.blue[400],
                      borderRadius: const BorderRadius.all(Radius.circular(4))),
                  child: Padding(
                      padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                      child: Text(
                        widget.dictName,
                        style: const TextStyle(color: Colors.white),
                      ))))
        ]),
        collapsed: const SizedBox.shrink(),
        expanded: Padding(
            padding: const EdgeInsets.only(
              top: 2,
              left: 10,
              bottom: 4,
            ),
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
                                    onTap: () {
                                  widget.queryWord(token['norm']!);
                                });
                              }
                              return RubyTextData(token['surface']!,
                                  ruby: token['reading'], onTap: () {
                                widget.queryWord(token['norm']!);
                              });
                            }).toList()))
                        .toList())
                : SelectableText(widget.imi,
                    style: const TextStyle(fontSize: 12),
                    toolbarOptions:
                        const ToolbarOptions(copy: true, selectAll: false))),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  final TextEditingController _controller = TextEditingController();
  late ValueNotifier<String> _textNotifier;
  final List<String> _history = [''];
  final Map<int, String?> _hatsuonCache = {};
  static const _kanaKit = KanaKit();
  int _searchMode = 0;
  Timer? _debounce;
  static Database? _db;
  Future<Database> get database async {
    if (_db != null) return _db!;

    var databasesPath = await getDatabasesPath();
    var path = Path.join(databasesPath, "arujisho.db");

    _db = await openDatabase(path, readOnly: true);
    return _db!;
  }

  _search(int mode) async {
    if (_controller.text.isEmpty) {
      _controller.text = "";
      return;
    }
    if (_history.isEmpty || _history.last != _controller.text) {
      _history.add(_controller.text);
    }
    _searchMode = mode;
    String s = _controller.text;
    s = s.replaceAll("\\pc", "\\p{Han}");
    s = s.replaceAll("\\ph", "\\p{Hiragana}");
    s = s.replaceAll("\\pk", "\\p{Katakana}");
    s = s
        .split('')
        .map<String>((c) => (cjdc.containsKey(c) ? cjdc[c]! : c))
        .join();
    _controller.text = s;
  }

  void _hatsuon(Map item) async {
    Map<String, String> burpHeader = {
      "Sec-Ch-Ua":
          "\"Chromium\";v=\"104\", \" Not A;Brand\";v=\"99\", \"Google Chrome\";v=\"104\"",
      "Dnt": "1",
      "Sec-Ch-Ua-Mobile": "?0",
      "User-Agent":
          "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/104.0.0.0 Safari/537.36",
      "Sec-Ch-Ua-Platform": "\"Windows\"",
      "Content-Type": "application/x-www-form-urlencoded",
      "Accept": "*/*",
      "Sec-Fetch-Site": "none",
      "Sec-Fetch-Mode": "cors",
      "Sec-Fetch-Dest": "empty",
      "Accept-Encoding": "gzip, deflate",
      "Accept-Language":
          "en-US,en;q=0.9,zh-TW;q=0.8,zh-CN;q=0.7,zh;q=0.6,ja;q=0.5",
      "Connection": "close"
    };
    String? url;
    if (_hatsuonCache.containsKey(item['idex'])) {
      url = _hatsuonCache[item['idex']];
    }
    if (url == null) {
      try {
        var resp = await http.post(
            Uri.parse(
                'https://www.japanesepod101.com/learningcenter/reference/dictionary_post'),
            headers: burpHeader,
            body: {
              "post": "dictionary_reference",
              "match_type": "exact",
              "search_query": item['word'],
              "vulgar": "true"
            });
        var dom = parse(resp.body);
        for (var row in dom.getElementsByClassName('dc-result-row')) {
          try {
            var audio = row.getElementsByTagName('audio')[0];
            var kana = row.getElementsByClassName('dc-vocab_kana')[0].text;
            if (_kanaKit.toKatakana(item['yomikata']) ==
                    _kanaKit.toKatakana(kana) ||
                _kanaKit.toHiragana(kana) == item['yomikata']) {
              url =
                  "https://assets.languagepod101.com/dictionary/japanese/audiomp3.php?kanji=${item['word']}&kana=$kana";
              setState(() {
                item['loading'] = true;
              });
              try {
                var file = await DefaultCacheManager()
                    .getSingleFile(url, headers: burpHeader);
                var hash = await sha256.bind(file.openRead()).first;
                if (hash.toString() ==
                    'ae6398b5a27bc8c0a771df6c907ade794be15518174773c58c7c7ddd17098906') {
                  throw const FormatException("NOT IMPLEMENTED");
                }
              } catch (_) {
                url = audio.getElementsByTagName('source')[0].attributes['src'];
              }
              break;
            }
          } catch (_) {}
        }
      } catch (_) {}
      setState(() {
        item['loading'] = false;
      });
    }
    if (url == null) {
      try {
        var resp = await http.get(
            Uri.parse("https://forvo.com/word/${item['word']}/#ja"),
            headers: burpHeader);
        var dom = parse(resp.body);
        var ja = dom.getElementById('language-container-ja');
        var pronunciation =
            ja!.getElementsByClassName('pronunciations-list')[0];
        String play = pronunciation
            .getElementsByClassName('play')[0]
            .attributes['onclick']!;
        RegExp exp = RegExp(r"Play\(\d+,'.+','.+',\w+,'([^']+)");
        String? match = exp.firstMatch(play)?.group(1);
        if (match != null && match.isNotEmpty) {
          match = utf8.decode(base64.decode(match));
          url = 'https://audio00.forvo.com/audios/mp3/$match';
        } else {
          exp = RegExp(r"Play\(\d+,'[^']+','([^']+)");
          match = exp.firstMatch(play)?.group(1);
          match = utf8.decode(base64.decode(match!));
          url = 'https://audio00.forvo.com/ogg/$match';
        }
      } catch (_) {
        url = null;
      }
    }
    if (url != null && url.isNotEmpty) {
      setState(() {
        item['loading'] = true;
      });
      try {
        final player = AudioPlayer();
        var file =
            await DefaultCacheManager().getSingleFile(url, headers: burpHeader);
        await player.setFilePath(file.path);
        player.play();
      } catch (_) {
        url = null;
      }
    }
    setState(() {
      _hatsuonCache[item['idex']] = url;
      item['loading'] = false;
    });
  }

  _setSearchContent(String text) {
    _controller.value = TextEditingValue(
        text: text,
        selection:
            TextSelection.fromPosition(TextPosition(offset: text.length)));
  }

  _cpListener() async {
    String cp = (await Clipboard.getData('text/plain'))!.text ?? '';
    if (cp == _controller.text) {
      return;
    }
    _setSearchContent(cp);
  }

  @override
  void initState() {
    super.initState();
    _textNotifier = ValueNotifier('');
    _controller.addListener(() {
      _textNotifier.value = _controller.text;
    });
    // _controller.addListener(() {
    //   if (_debounce?.isActive ?? false) return;
    //   _debounce = Timer(const Duration(milliseconds: 300), () {
    //     setState(() {
    //       _search(0);
    //     });
    //   });
    // });
    database;
    ClipboardListener.addListener(_cpListener);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _textNotifier.dispose();
    ClipboardListener.removeListener(_cpListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          if (_history.isEmpty) return true;
          while (_history.last == _controller.text && _history.length > 1) {
            _history.removeLast();
          }
          String temp = _history.last;
          _history.removeLast();
          _setSearchContent(temp);
          return false;
        },
        child: Scaffold(
            appBar: AppBar(
              title: const Text("ある辞書",
                  style: TextStyle(color: Colors.white, fontSize: 20)),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48.0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(left: 12.0, bottom: 8.0),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 2.0),
                          borderRadius: BorderRadius.circular(24.0),
                        ),
                        child: TextFormField(
                          controller: _controller,
                          textAlignVertical: TextAlignVertical.center,
                          decoration: InputDecoration(
                            hintText: "調べたい言葉をご入力してください",
                            contentPadding:
                                const EdgeInsets.fromLTRB(20, 12, 12, 12),
                            border: InputBorder.none,
                            suffixIcon: _controller.text.isEmpty
                                ? null
                                : IconButton(
                                    icon: const Icon(Icons.clear, size: 20),
                                    onPressed: () {
                                      setState(() => _controller.clear());
                                    },
                                  ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: SizedBox(
                            width: 48,
                            height: 48,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _search(0);
                                });
                              },
                              onLongPress: () => showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: const Text('頻度コントロール'),
                                      content: TextField(
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(
                                              RegExp("[0-9]")),
                                        ],
                                        onChanged: (value) {
                                          int v = int.parse(value);
                                          setState(() {
                                            _searchMode = v;
                                          });
                                        },
                                        decoration: const InputDecoration(
                                            hintText: "頻度ランク（正整数）"),
                                      ),
                                    );
                                  }),
                              child: Ink(
                                  child: const Icon(
                                // BootstrapIcons.sort_down_alt,
                                Icons.search,
                                color: Colors.white,
                              )),
                            )))
                  ],
                ),
              ),
            ),
            body: Container(
              margin: const EdgeInsets.all(8.0),
              child: InfiniteList<Map>(
                textNotifier: _textNotifier,
                onRequest: (String data, int nextIndex) async {
                  const pageSize = 18;
                  if (nextIndex % pageSize != 0) {
                    return [];
                  }
                  Database db = await database;
                  String searchField = 'word';
                  String method = "MATCH";
                  List<Map> result = <Map>[];
                  if (data.toLowerCase().contains(RegExp(r'^[a-z]+$'))) {
                    searchField = 'romaji';
                  } else if (data.contains(RegExp(r'^[ぁ-ゖー]+$'))) {
                    searchField = 'yomikata';
                  } else if (data.contains(RegExp(r'[\.\+\[\]\*\^\$\?]'))) {
                    method = 'REGEXP';
                  } else if (data.contains(RegExp(r'[_%]'))) {
                    method = 'LIKE';
                  }
                  try {
                    if (method == "MATCH") {
                      result = List.of(await db.rawQuery(
                        'SELECT tt.word,tt.yomikata,tt.pitchData,'
                        'tt.origForm,tt.freqRank,tt.idex,tt.romaji,imis.imi,imis.orig '
                        'FROM (imis JOIN (SELECT * FROM jpdc '
                        'WHERE ($searchField MATCH "$data*" OR r$searchField '
                        'MATCH "${String.fromCharCodes(data.runes.toList().reversed)}*") '
                        '${(_searchMode > 0 ? "AND _rowid_ >= $_searchMode" : "")} '
                        'ORDER BY _rowid_ LIMIT $nextIndex, ${2 * pageSize}'
                        ') AS tt ON tt.idex=imis._rowid_)',
                      ));
                    } else {
                      result = List.of(await db.rawQuery(
                        'SELECT tt.word,tt.yomikata,tt.pitchData,'
                        'tt.origForm,tt.freqRank,tt.idex,tt.romaji,imis.imi,imis.orig '
                        'FROM (imis JOIN (SELECT * FROM jpdc '
                        'WHERE (word $method "$data" '
                        'OR yomikata $method "$data" '
                        'OR romaji $method "$data") '
                        '${(_searchMode > 0 ? "AND _rowid_ >= $_searchMode" : "")} '
                        'ORDER BY _rowid_ LIMIT $nextIndex, $pageSize'
                        ') AS tt ON tt.idex=imis._rowid_)',
                      ));
                    }
                    result = result.map((qRow) {
                      Map map = {};
                      qRow.forEach((key, value) => map[key] = value);
                      return map;
                    }).toList();
                    int balancedWeight(Map item, int bLen) {
                      return (item['freqRank'] *
                              (item[searchField].startsWith(data) &&
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
                },
                itemBuilder: (context, item, index) {
                  Map<String, dynamic> imi = jsonDecode(item['imi']);
                  final String pitchData = item['pitchData'] != ''
                      ? jsonDecode(item['pitchData'])
                          .map(
                              (x) => x <= 20 ? '⓪①②③④⑤⑥⑦⑧⑨⑩⑪⑫⑬⑭⑮⑯⑰⑱⑲⑳'[x] : '?')
                          .toList()
                          .join()
                      : '';
                  final word =
                      item['origForm'] == '' ? item['word'] : item['origForm'];

                  return ListTileTheme(
                      dense: true,
                      child: ExpansionTile(
                          initiallyExpanded:
                              item.containsKey('expanded') && item['expanded'],
                          title: Text(word == item['orig']
                              ? word
                              : '$word →〔${item['orig']}〕'),
                          trailing: item.containsKey('expanded') &&
                                  item['freqRank'] != -1 &&
                                  item['expanded']
                              ? Container(
                                  padding: const EdgeInsets.all(0.0),
                                  width: 35.0,
                                  child: item.containsKey('loading') &&
                                          item['loading']
                                      ? const CircularProgressIndicator()
                                      : IconButton(
                                          icon: _hatsuonCache.containsKey(
                                                      item['idex']) &&
                                                  _hatsuonCache[item['idex']] ==
                                                      null
                                              ? const Icon(Icons.error_outline)
                                              : const Icon(
                                                  IcoFontIcons.soundWaveAlt),
                                          onPressed: () => _hatsuon(item)))
                              : Text((item['freqRank'] + 1).toString()),
                          subtitle: Text("${item['yomikata']} "
                              "$pitchData"),
                          children: List.from(imi.keys)
                              .asMap()
                              .entries
                              .map<List<Widget>>((s) {
                            int index1 = s.key;
                            final cont = s.value;
                            return List<List<Widget>>.from(
                              imi[cont].asMap().entries.map((entry) {
                                int index2 = entry.key;
                                final simi = entry.value;
                                return <Widget>[
                                  DictionaryTerm(
                                    dictName: cont,
                                    imi: simi,
                                    queryWord: _setSearchContent,
                                    initialExpanded: index1 < 3,
                                  )
                                ];
                              }),
                            ).reduce((a, b) => a + b);
                          }).reduce((a, b) => a + b),
                          onExpansionChanged: (expanded) {
                            FocusManager.instance.primaryFocus?.unfocus();
                            setState(() => item['expanded'] = expanded);
                          }));
                },
                key: ValueKey('$_controller.text $_searchMode'),
              ),
            )));
  }
}
