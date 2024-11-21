import 'package:flutter/material.dart';

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
