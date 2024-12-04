import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:arujisho/models/word.dart';
import 'package:arujisho/providers/db_provider.dart';
import 'package:arujisho/providers/search_history_notifier.dart';
import 'package:arujisho/utils/dictionary_util.dart';
import 'package:arujisho/widgets/search_help_card.dart';
import 'package:arujisho/widgets/home_drawer.dart';
import 'package:arujisho/widgets/infinite_sliver_list.dart';
import 'package:arujisho/widgets/history_chips.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  late TextEditingController textController;
  bool showScrollToTopButton = false;
  late ScrollController scrollController;
  bool isStart = true;

  int minRank = 0;

  /// 搜索新值前，处理搜索历史
  Future<void> search(int mode) async {
    minRank = mode;
  }

  void setSearchContent(String text) {
    textController.value = TextEditingValue(
        text: text,
        selection:
            TextSelection.fromPosition(TextPosition(offset: text.length)));
  }

  Future<void> cpListener() async {
    final clipboardData = await Clipboard.getData('text/plain');
    if (clipboardData == null) return; // 如果剪贴板中没有数据，直接返回

    final text = clipboardData.text;
    if (text == null || text.isEmpty) return; // 如果粘贴的内容不是文本或为空，直接返回

    const int maxTextLength = 15; // 设置一个最大文本长度阈值
    if (text.length > maxTextLength) return; // 如果粘贴的文本长度超过阈值，直接返回

    if (text == textController.text) return; // 如果粘贴的内容与当前输入框内容相同，直接返回

    setSearchContent(text); // 处理粘贴的文本内容
  }

  @override
  void initState() {
    super.initState();

    textController = TextEditingController();
    textController.addListener(() {
      // setState(() {
      search(0);
      // });
    });

    if (widget.initialInput == null) {
      Future.microtask(() async {
        final prefs = await SharedPreferences.getInstance();
        if (prefs.containsKey('searchHistory')) {
          final history = prefs.getStringList('searchHistory')!;
          textController.text = history.firstOrNull ?? 'help';
        }
      });
    } else {
      textController.text = widget.initialInput ?? 'help';
    }
    // _search(0);

    ClipboardListener.addListener(cpListener);
    scrollController = ScrollController(initialScrollOffset: 0);
    scrollController.addListener(scrollListener);
  }

  void scrollListener() {
    if (scrollController.offset > 1) {
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

  void scrollToTop() {
    scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    textController.dispose();
    ClipboardListener.removeListener(cpListener);
    scrollController.removeListener(scrollListener);
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final historyNotifier = Provider.of<SearchHistoryNotifier>(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: const HomeDrawer(),
      body: Stack(children: [
        NestedScrollView(
          controller: scrollController,
          floatHeaderSlivers: true,
          headerSliverBuilder:
              (BuildContext context, bool innerBoxIsScrolled) => <Widget>[
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: SliverAppBar(
                // stretch: true,
                floating: true,
                pinned: true,
                snap: true,
                expandedHeight: 75,
                forceElevated: innerBoxIsScrolled,
                flexibleSpace: FlexibleSpaceBar(
                  background: BackdropFilter(
                    filter:
                        ImageFilter.blur(sigmaX: 3.0, sigmaY: 2.0), // 设置模糊强度
                    child: Container(
                      color: Colors.transparent,
                    ),
                  ),
                  // stretchModes: [StretchMode.fadeTitle],
                  title: const Text(
                    "ある辞書",
                  ),
                  centerTitle: true,
                  expandedTitleScale: 1.4,
                ),
                actions: [
                  if (historyNotifier.isNotEmpty)
                    IconButton(
                      onPressed: () {
                        historyNotifier.clear();
                      },
                      tooltip: '履歴を全部削除',
                      icon: const Icon(Icons.cleaning_services),
                      iconSize: 24,
                    )
                ],
                backgroundColor:
                    Theme.of(context).colorScheme.surface.withOpacity(0.8),
                // surfaceTintColor: Theme.of(context).colorScheme.primaryContainer,
                shadowColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                scrolledUnderElevation: 4.0,
                elevation: 0.0,
              ),
            ),
            // _buildSliverAppBar(context, innerBoxIsScrolled),
          ],
          body: Builder(
            builder: (BuildContext context) {
              final innerScrollController = PrimaryScrollController.of(context);

              return CupertinoScrollbar(
                controller: innerScrollController,
                child: CustomScrollView(
                  // physics: const NeverScrollableScrollPhysics(),
                  // controller: _scrollController,
                  slivers: <Widget>[
                    // header是SliverAppBar是不需要显式写Injector

                    // SliverOverlapInjector(
                    //   // 这里注入SliverOverlapAbsorberHandle来处理重叠
                    //   handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                    //       context),
                    // ),
                    // if (historyNotifier.isNotEmpty)
                    SliverPersistentHeader(
                      pinned: true,
                      floating: true,
                      delegate: StickyHeaderDelegate(
                        // vsync: this,
                        minHeight: 120.0,
                        maxHeight: 120.0,
                        child: Padding(
                          padding: const EdgeInsets.only(
                              top: 95.0, left: 8.0, right: 8.0),
                          child: HistoryChips(
                            setText: (item) {
                              setSearchContent(item);
                            },
                          ),
                        ),
                      ),
                    ),

                    ListenableBuilder(
                      listenable: textController,
                      builder: (BuildContext ctx, _) {
                        switch (textController.text) {
                          case "":
                            return const SliverToBoxAdapter(
                                child: Center(
                                    child: Padding(
                              padding: EdgeInsets.only(top: 200.0),
                              child: Text(
                                "ご参考になりましたら幸いです",
                                style: TextStyle(fontSize: 18),
                              ),
                            )));
                          case "help" || "?":
                            return const SliverToBoxAdapter(
                              child: SearchHelpCard(),
                            );
                          default:
                            return InfiniteSliverList<Word>(
                              // itemExtent: 50.0,
                              onRequest: (nextIndex, pageSize) async {
                                final db =
                                    await Provider.of<DbProvider>(context)
                                        .database;
                                return DictionaryUtil.getWords(
                                  db,
                                  textController.text,
                                  nextIndex,
                                  pageSize,
                                  minRank,
                                );
                              },
                              itemBuilder: (context, item, index) {
                                final pitchData = item.pitchData.isNotEmpty
                                    ? jsonDecode(item.pitchData)
                                        .map((x) => x <= 20
                                            ? '⓪①②③④⑤⑥⑦⑧⑨⑩⑪⑫⑬⑭⑮⑯⑰⑱⑲⑳'[x]
                                            : '?')
                                        .toList()
                                        .join()
                                    : '';
                                final word = item.origForm.isEmpty
                                    ? item.word
                                    : item.origForm;

                                if (index == 0 &&
                                    isStart &&
                                    widget.initialInput != null) {
                                  isStart = false;
                                  historyNotifier.remove(textController.text);
                                  historyNotifier
                                      .addToHead(textController.text);
                                  item.showDetailedWordInModalBottomSheet(
                                      context, item);
                                }

                                return ListTile(
                                  title: Text(word == item.orig
                                      ? word
                                      : '$word →〔${item.orig}〕'),
                                  subtitle: Text("${item.yomikata}$pitchData"),
                                  trailing: Text((item.freqRank).toString()),
                                  onTap: () {
                                    historyNotifier.remove(textController.text);
                                    historyNotifier
                                        .addToHead(textController.text);
                                    item.showDetailedWordInModalBottomSheet(
                                        context, item);
                                  },
                                );
                              },
                              key: ValueKey('${textController.text}_$minRank'),
                            );
                        }
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
                height: 80,
                child: ClipRRect(
                  // 匹配searchBar的默认圆角大小
                  borderRadius: BorderRadius.circular(32.0),
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
                            .withOpacity(.7),
                      ),
                      side: WidgetStatePropertyAll(
                        BorderSide(
                          width: 2.0,
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.5),
                        ),
                      ),
                      padding: const WidgetStatePropertyAll(
                          EdgeInsets.symmetric(horizontal: 6.0)),
                      elevation: const WidgetStatePropertyAll(0.0),
                      hintText: "言葉を入力して検索する",
                      controller: textController,
                      trailing: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: InkWell(
                            onTap: () => search(-1),
                            onLongPress: () => showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: const Text('頻度コントロール'),
                                  content: TextField(
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                          RegExp("[0-9]"))
                                    ],
                                    onChanged: (value) {
                                      final v = int.tryParse(value);
                                      if (v != null && v > 0) {
                                        setState(() => minRank = v);
                                      }
                                    },
                                    decoration: const InputDecoration(
                                        hintText: "頻度ランク（正整数）"),
                                  ),
                                );
                              },
                            ),
                            child: const Icon(BootstrapIcons.sort_down_alt),
                          ),
                        ),
                        if (textController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () =>
                                setState(() => textController.clear()),
                          )
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 20.0),
                child: AnimatedOpacity(
                  opacity: showScrollToTopButton ? 0.9 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: FloatingActionButton(
                    onPressed: () {
                      if (showScrollToTopButton) scrollToTop();
                    },
                    child: const Icon(Icons.arrow_upward),
                  ),
                ),
              ),
            ),
          ],
        ),
      ]),
    );
  }
}

class StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double minHeight;
  final double maxHeight;
  // @override
  // final TickerProvider vsync;
  StickyHeaderDelegate({
    required this.child,
    required this.minHeight,
    required this.maxHeight,
    // required this.vsync,
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
    return false;
  }
}
