import 'package:arujisho/providers/search_history_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SearchBarWithHistoryChips extends StatefulWidget {
  final Function(String item) setText;
  const SearchBarWithHistoryChips({super.key, required this.setText});

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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        scrollDirection: Axis.horizontal,
        children: notifier.history.take(20).map((historyItem) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: GestureDetector(
                onTap: () {
                  if (_isDeleteMode) {
                    notifier.remove(historyItem);
                  } else {
                    widget.setText(historyItem);
                    // widget.controller.text = historyItem;
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
                          width: 2.0, color: Theme.of(context).primaryColor),
                      color: Theme.of(context).colorScheme.primaryContainer,
                    ),
                    child: Wrap(
                        children: _isDeleteMode
                            ? [
                                Text(historyItem,
                                    style: const TextStyle(fontSize: 14)),
                                GestureDetector(
                                    onTap: () {
                                      if (_isDeleteMode) {
                                        notifier.remove(historyItem);
                                      } else {
                                        widget.setText(historyItem);
                                        // widget.controller.text = historyItem;
                                      }
                                    },
                                    child: const Icon(Icons.close, size: 12))
                              ]
                            : [
                                Text(historyItem,
                                    style: const TextStyle(fontSize: 14))
                              ]),
                  ),
                )),
          );
        }).toList(),
      ),
    );
  }
}
