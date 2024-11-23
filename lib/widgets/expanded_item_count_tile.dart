import 'package:arujisho/providers/item_count_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ExpandedItemCountTile extends StatelessWidget {
  const ExpandedItemCountTile({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.list_alt),
      subtitle: Consumer<ItemCountNotifier>(
        builder: (context, displayProvider, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '展開表示件数: ${displayProvider.expandedItemCount == myInf ? 'すべて' : '${displayProvider.expandedItemCount}'}',
                style: const TextStyle(fontSize: 16),
              ),
              Slider(
                value: displayProvider.expandedItemCount == myInf
                    ? 10.0
                    : displayProvider.expandedItemCount.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                label: displayProvider.expandedItemCount == myInf
                    ? 'すべて表示'
                    : '${displayProvider.expandedItemCount}',
                onChanged: (double value) {
                  int intValue = value.toInt();
                  displayProvider
                      .setExpandedItemCount(intValue == 10 ? myInf : intValue);
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
