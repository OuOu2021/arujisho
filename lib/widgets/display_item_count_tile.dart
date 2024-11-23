import 'package:arujisho/providers/item_count_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DisplayItemCountTile extends StatelessWidget {
  const DisplayItemCountTile({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.list),
      subtitle: Consumer<ItemCountNotifier>(
        builder: (context, displayProvider, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '表示件数: ${displayProvider.displayItemCount == myInf ? 'すべて' : '${displayProvider.displayItemCount}'}',
                style: const TextStyle(fontSize: 16),
              ),
              Slider(
                value: displayProvider.displayItemCount == myInf
                    ? 10.0
                    : displayProvider.displayItemCount.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                label: displayProvider.displayItemCount == myInf
                    ? 'すべて表示'
                    : '${displayProvider.displayItemCount}',
                onChanged: (double value) {
                  int intValue = value.toInt();
                  displayProvider
                      .setDisplayItemCount(intValue == 10 ? myInf : intValue);
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
