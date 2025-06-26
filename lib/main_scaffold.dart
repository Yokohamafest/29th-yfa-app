import 'package:flutter/material.dart';
import 'package:flutter_app_yfa/screens/event_list_screen.dart';
import 'package:flutter_app_yfa/screens/favorites_screen.dart';
import 'package:flutter_app_yfa/screens/home_screen.dart';
import 'package:flutter_app_yfa/screens/map_screen.dart';
import 'package:flutter_app_yfa/screens/timetable_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  // 現在選択されているタブのインデックスを管理する変数
  int _selectedIndex = 0;

  // 各タブに対応する画面のリスト
  final List<Widget> _screens = [
    const HomeScreen(),
    const TimetableScreen(),
    const MapScreen(),
    const EventListScreen(),
    const FavoritesScreen(),
  ];

  // タブがタップされたときに呼ばれる関数
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 本体の部分。選択されたインデックスに応じて画面を切り替える
      body: _screens[_selectedIndex],

      // 画面下部のボトムナビゲーションバー
      bottomNavigationBar: BottomNavigationBar(
        // 各タブのアイテム（アイコンとラベル）のリスト
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'ホーム'),
          BottomNavigationBarItem(icon: Icon(Icons.schedule), label: 'タイムテーブル'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'マップ'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: '企画一覧'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'お気に入り'),
        ],
        // 現在選択されているタブのインデックス
        currentIndex: _selectedIndex,
        // 選択されたアイテムの色
        selectedItemColor: const Color.fromARGB(255, 15, 114, 175),
        // 選択されていないアイテムの色
        unselectedItemColor: Colors.grey,
        // タップされたときの処理
        onTap: _onItemTapped,
        // ラベルを常に表示するための設定
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
