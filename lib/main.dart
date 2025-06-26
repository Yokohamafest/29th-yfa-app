import 'package:flutter/material.dart';
import 'package:flutter_app_yfa/main_scaffold.dart'; // 作成したファイルをインポート

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '29th Yokohama Festival',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // アプリの最初の画面としてMainScaffoldを指定
      home: const MainScaffold(),
    );
  }
}