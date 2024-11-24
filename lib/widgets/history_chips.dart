import 'package:arujisho/providers/search_history_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HistoryChips extends StatefulWidget {
  final Function(String item) setText;
  // final EdgeInsets padding;
  const HistoryChips({
    super.key,
    required this.setText,
    // this.padding = EdgeInsets.zero,
  });

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
      physics: const AlwaysScrollableScrollPhysics(),
      scrollDirection: Axis.horizontal,
      children: notifier.history.asMap().entries.take(20).map((entry) {
        final index = entry.key;
        final historyItem = entry.value;
        final contColor = switch (index % 3) {
          0 => Theme.of(context).colorScheme.primaryContainer.withOpacity(.9),
          1 => Theme.of(context).colorScheme.secondaryContainer.withOpacity(.9),
          2 => Theme.of(context).colorScheme.tertiaryContainer.withOpacity(.9),
          int() => throw UnimplementedError(),
        };
        final bordColor = switch (index % 3) {
          0 => Theme.of(context).colorScheme.primary.withOpacity(.9),
          1 => Theme.of(context).colorScheme.secondary.withOpacity(.9),
          2 => Theme.of(context).colorScheme.tertiary.withOpacity(.9),
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
                constraints: const BoxConstraints(minWidth: 40),
                padding:
                    const EdgeInsets.symmetric(horizontal: 6.0, vertical: 0.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    width: 1.5,
                    color: bordColor,
                  ),
                  // color: Theme.of(context).colorScheme.primaryContainer,
                  color: contColor,
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
