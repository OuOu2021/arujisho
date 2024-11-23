import 'package:arujisho/pages/about.dart';
import 'package:arujisho/providers/theme_notifier.dart';
import 'package:arujisho/widgets/display_item_count_tile.dart';
import 'package:arujisho/widgets/expanded_item_count_tile.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

Widget buildDrawer(BuildContext context) {
  return Drawer(
    width: MediaQuery.of(context).size.width * 0.64,
    child: ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        DrawerHeader(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
          ),
          child: const Text(
            '設定',
            style: TextStyle(
              fontSize: 24,
            ),
          ),
        ),
        // 主题模式设置
        ListTile(
          leading: const Icon(Icons.brightness_6),
          title: const Text(
            'テーマモード設定',
            style: TextStyle(fontSize: 16),
          ),
          subtitle: Consumer<ThemeNotifier>(
            builder: (context, themeProvider, child) {
              return DropdownButtonFormField<ThemeMode>(
                value: themeProvider.themeMode,
                items: const [
                  DropdownMenuItem<ThemeMode>(
                    value: ThemeMode.system,
                    child: Text(
                      'システムに従う',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  DropdownMenuItem<ThemeMode>(
                    value: ThemeMode.light,
                    child: Text(
                      '明るいモード',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  DropdownMenuItem<ThemeMode>(
                    value: ThemeMode.dark,
                    child: Text(
                      '暗いモード',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    themeProvider.setThemeMode(value);
                  }
                },
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        // 显示条目数
        const DisplayItemCountTile(),
        const SizedBox(height: 10),
        // 详细显示条目数
        const ExpandedItemCountTile(),
        const SizedBox(height: 10),
        // 关于
        ListTile(
          leading: const Icon(Icons.info),
          title: const Text('アプリについて'),
          onTap: () {
            context.push(AboutPage.routeName);
          },
        ),
      ],
    ),
  );
}
