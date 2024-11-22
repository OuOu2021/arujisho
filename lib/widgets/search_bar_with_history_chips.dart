import 'package:arujisho/providers/search_history_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SearchBarWithHistoryChips extends StatefulWidget {
  final TextEditingController controller;
  const SearchBarWithHistoryChips({super.key, required this.controller});

  @override
  SearchBarWithHistoryChipsState createState() =>
      SearchBarWithHistoryChipsState();
}

class SearchBarWithHistoryChipsState extends State<SearchBarWithHistoryChips> {
  final FocusNode _focusNode = FocusNode();
  bool _isDeleteMode = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() {
          _isDeleteMode = false;
        });
      } else {
        // 这里我们需要等待一段时间来检测是否真的离开了Chip区域
        Future.delayed(const Duration(milliseconds: 50), () {
          if (!_focusNode.hasFocus) {
            setState(() {
              _isDeleteMode = false;
            });
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifier = Provider.of<SearchHistoryNotifier>(context);
    return ClipRect(
      child: Align(
        alignment: Alignment.topLeft,
        child: Container(
          constraints: BoxConstraints(
            // minWidth: MediaQuery.of(context).size.width * 0.6,
            // 不与右边的返回按钮重叠
            maxWidth: MediaQuery.of(context).size.width - 90,
            maxHeight: 80,
          ),
          padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 15.0),
          child: Wrap(
            spacing: 4.0, // 调整间距，使Chip尽可能小巧
            runSpacing: 4.0,
            children: notifier.history.take(20).map((historyItem) {
              return GestureDetector(
                  onTap: () {
                    if (_isDeleteMode) {
                      notifier.remove(historyItem);
                    } else {
                      widget.controller.text = historyItem;
                    }
                  },
                  onLongPress: () {
                    setState(() {
                      _isDeleteMode = !_isDeleteMode;
                    });
                  },
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 35),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            width: 2.0,
                            color: Theme.of(context).colorScheme.primary),
                        color: Theme.of(context).colorScheme.primaryContainer,
                      ),
                      child: Wrap(
                          children: _isDeleteMode
                              ? [
                                  Text(historyItem,
                                      style: const TextStyle(fontSize: 16)),
                                  GestureDetector(
                                      onTap: () {
                                        if (_isDeleteMode) {
                                          notifier.remove(historyItem);
                                        } else {
                                          widget.controller.text = historyItem;
                                        }
                                      },
                                      child: const Icon(Icons.close, size: 12))
                                ]
                              : [
                                  Text(historyItem,
                                      style: const TextStyle(fontSize: 16))
                                ]),
                    ),
                  ));
            }).toList(),
          ),
        ),
      ),
    );
  }
}
