// 添加 About 页面
import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  static const routeName = '/about';
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 使用 Scaffold 提供返回按钮
    return Scaffold(
      appBar: AppBar(
        title: const Text('アプリについて'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                '作者: emc2314, OuOu2021',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              const Text(
                // TODO: 找原作者确定开源协议
                'License: Unknown',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              const Text(
                // TODO: 找原作者确定开源协议
                'ヘルプ: input \'help\' in searchBar to get help',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  // 这里可以实现打开GitHub主页的功能，例如使用 url_launcher 包
                },
                child: const Text(
                  'GitHub主页: https://github.com/OuOu2021/arujisho',
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue,
                      decoration: TextDecoration.underline),
                ),
              ),
              const SizedBox(height: 200),
            ],
          ),
        ),
      ),
    );
  }
}
