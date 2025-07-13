import 'package:flutter/material.dart';
import 'package:flutter_app_yfa/screens/event_list_screen.dart';
import 'package:flutter_app_yfa/screens/favorites_screen.dart';
import 'package:flutter_app_yfa/screens/home_screen.dart';
import 'package:flutter_app_yfa/screens/map_screen.dart';
import 'package:flutter_app_yfa/screens/timetable_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;
  final Set<String> _favoriteEventIds = {};

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    // 'favorite_events' というキーで保存されたリストを読み込む
    final favoriteIds = prefs.getStringList('favorite_events');
    if (favoriteIds != null) {
      setState(() {
        _favoriteEventIds.addAll(favoriteIds);
      });
    }
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    // 'favorite_events' というキーで、現在のSetをListに変換して保存
    await prefs.setStringList('favorite_events', _favoriteEventIds.toList());
  }

  void _toggleFavorite(String eventId) {
    setState(() {
      if (_favoriteEventIds.contains(eventId)) {
        _favoriteEventIds.remove(eventId);
      } else {
        _favoriteEventIds.add(eventId);
      }
      // 状態を変更した直後に、保存処理を呼び出す
      _saveFavorites();
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 【変更点②】画面リストの定義と初期化を、buildメソッドの中に移動
    final List<Widget> screens = [
      const HomeScreen(),
      TimetableScreen(
        favoriteEventIds: _favoriteEventIds,
        onToggleFavorite: _toggleFavorite,
      ),
      const MapScreen(),
      EventListScreen(
        favoriteEventIds: _favoriteEventIds,
        onToggleFavorite: _toggleFavorite,
      ),
      FavoritesScreen(
        favoriteEventIds: _favoriteEventIds,
        onToggleFavorite: _toggleFavorite,
      ),
    ];

    return Scaffold(
      // 【変更点③】ローカル変数 screens を使うように変更
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'ホーム'),
          BottomNavigationBarItem(icon: Icon(Icons.schedule), label: 'タイムテーブル'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'マップ'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: '企画一覧'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'お気に入り'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
