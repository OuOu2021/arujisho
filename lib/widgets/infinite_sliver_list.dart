import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

typedef RequestWithSizeFn<T> = Future<List<T>> Function(
    int nextIndex, int pageSize);
typedef ItemBuilder<T> = Widget Function(
    BuildContext context, T item, int index);

class InfiniteSliverList<T> extends StatefulWidget {
  final RequestWithSizeFn<T> onRequest;
  final ItemBuilder<T> itemBuilder;

  const InfiniteSliverList({
    super.key,
    required this.onRequest,
    required this.itemBuilder,
  });

  @override
  InfiniteSliverListState<T> createState() => InfiniteSliverListState<T>();
}

class InfiniteSliverListState<T> extends State<InfiniteSliverList<T>> {
  static const _pageSize = 20;
  final PagingController<int, T> _pagingController =
      PagingController(firstPageKey: 0);
  // late ScrollController _scrollController; // 用于监听滚动

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
  }

  @override
  void dispose() {
    super.dispose();
    // _scrollController.dispose();
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final newItems = await widget.onRequest(pageKey, _pageSize);
      final isLastPage = newItems.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(newItems);
      } else {
        final nextPageKey = pageKey + newItems.length;
        _pagingController.appendPage(newItems, nextPageKey);
      }
    } catch (e) {
      _pagingController.error = e;
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PagedSliverList<int, T>(
      pagingController: _pagingController,
      builderDelegate: PagedChildBuilderDelegate<T>(
        itemBuilder: (context, item, index) =>
            widget.itemBuilder(context, item, index),
        noItemsFoundIndicatorBuilder: (context) => const Center(
            child: Text(
          '一致する検索結果はありません',
          style: TextStyle(fontSize: 18),
        )),
        noMoreItemsIndicatorBuilder: (context) => const Padding(
          padding: EdgeInsets.only(top: 10, bottom: 120),
          child: Center(child: Text('以上です')),
        ),
        firstPageErrorIndicatorBuilder: (context) => Padding(
          padding: const EdgeInsets.all(40.0),
          child: Text(
            "Invalid input exception: \n ${_pagingController.error}",
            style: const TextStyle(fontSize: 16),
          ),
        ),
        animateTransitions: true,
      ),
    );
  }
}
