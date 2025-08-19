import 'package:flutter/material.dart';
import 'dart:async';
import '../utils/app_colors.dart';
import 'screens/loading_screen.dart';

// ここにFirebaseの初期化コードが入る
// ignore: unused_element
Future<void> _firebaseMessagingBackgroundHandler(dynamic message) async {
  // バックグラウンドで通知を受け取った際の処理
  debugPrint("Handling a background message: ${message.messageId}");
}


// main関数から async と await を削除
void main() {
  // WidgetsFlutterBinding.ensureInitialized(); // これも不要になることが多い
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '29th Yokohama Festival App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        fontFamily: 'NotoSansJP',
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.secondary,
          foregroundColor: Colors.white,
          titleTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
        ),
      ),
      // ■ 最初の画面を新しいLoadingScreenに変更
      home: const LoadingScreen(),
    );
  }
}

