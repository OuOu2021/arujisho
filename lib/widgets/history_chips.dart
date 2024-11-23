import 'package:arujisho/providers/search_history_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HistoryChips extends StatefulWidget {
  final Function(String item) setText;
  const HistoryChips({super.key, required this.setText});

  @override
  HistoryChipsState createState() => HistoryChipsState();
}

class HistoryChipsState extends State<HistoryChips> {
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
    return ListView(
      scrollDirection: Axis.horizontal,
      children: notifier.history.asMap().entries.take(20).map((entry) {
        final index = entry.key;
        final historyItem = entry.value;
        final color = switch (index % 3) {
          0 => Theme.of(context).colorScheme.primaryContainer.withOpacity(.7),
          1 => Theme.of(context).colorScheme.secondaryContainer.withOpacity(.7),
          2 => Theme.of(context).colorScheme.tertiaryContainer.withOpacity(.7),
          int() => throw UnimplementedError(),
        };
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0),
          child: GestureDetector(
              onTap: () {
                if (_isDeleteMode) {
                  // notifier.remove(historyItem);
                } else {
                  widget.setText(historyItem);
                }
              },
              onLongPress: () {
                setState(() {
                  _isDeleteMode = !_isDeleteMode;
                });
              },
              child: Container(
                constraints: const BoxConstraints(minWidth: 35),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      width: 1.5,
                      color: Theme.of(context).primaryColor.withOpacity(.7)),
                  // color: Theme.of(context).colorScheme.primaryContainer,
                  color: color,
                ),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(historyItem, style: const TextStyle(fontSize: 13)),
                      if (_isDeleteMode)
                        GestureDetector(
                          onTap: () {
                            notifier.remove(historyItem);
                          },
                          child: const Icon(Icons.close, size: 12),
                        ),
                    ]),
              )),
        );
      }).toList(),
    );
  }
}
