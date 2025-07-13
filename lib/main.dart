import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_app_yfa/main_scaffold.dart'; // 作成したファイルをインポート

Future<void> main() async {
  // 3. Flutterの準備が整うのを保証するおまじない
  WidgetsFlutterBinding.ensureInitialized();

  // 4. 日本語ロケールの日付書式を初期化する
  await initializeDateFormatting('ja_JP');

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