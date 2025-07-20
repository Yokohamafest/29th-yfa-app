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
  // --- 状態変数 ---
  int _selectedIndex = 0;
  final Set<String> _favoriteEventIds = {};
  String? _highlightedEventId;

  // --- ライフサイクルメソッド ---
  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  // --- 状態操作メソッド ---
  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteIds = prefs.getStringList('favorite_events');
    if (favoriteIds != null) {
      setState(() {
        _favoriteEventIds.addAll(favoriteIds);
      });
    }
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorite_events', _favoriteEventIds.toList());
  }

  void _toggleFavorite(String eventId) {
    setState(() {
      if (_favoriteEventIds.contains(eventId)) {
        _favoriteEventIds.remove(eventId);
      } else {
        _favoriteEventIds.add(eventId);
      }
      _saveFavorites();
    });
  }

  void _navigateToMapAndHighlight(String eventId) {
    setState(() {
      _selectedIndex = 2; // マップ画面のインデックス
      _highlightedEventId = eventId;
    });
    // マップ表示後、少し経ったらハイライトを解除する
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _highlightedEventId = null;
        });
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // --- UI構築メソッド ---
  @override
  Widget build(BuildContext context) {
    // 画面リストの定義をbuildメソッド内で行う
    final List<Widget> screens = [
      HomeScreen(
        favoriteEventIds: _favoriteEventIds,
        onToggleFavorite: _toggleFavorite,
        onNavigateToMap: _navigateToMapAndHighlight,
      ),
      TimetableScreen(
        favoriteEventIds: _favoriteEventIds,
        onToggleFavorite: _toggleFavorite,
        onNavigateToMap: _navigateToMapAndHighlight,
      ),
      MapScreen(
        highlightedEventId: _highlightedEventId,
        favoriteEventIds: _favoriteEventIds,
        onToggleFavorite: _toggleFavorite,
        onNavigateToMap: _navigateToMapAndHighlight,
      ),
      EventListScreen(
        favoriteEventIds: _favoriteEventIds,
        onToggleFavorite: _toggleFavorite,
        onNavigateToMap: _navigateToMapAndHighlight,
      ),
      FavoritesScreen(
        favoriteEventIds: _favoriteEventIds,
        onToggleFavorite: _toggleFavorite,
        onNavigateToMap: _navigateToMapAndHighlight,
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'ホーム'),
          BottomNavigationBarItem(icon: Icon(Icons.schedule), label: 'タイムテーブル'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'マップ'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: '企画一覧'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'お気に入り'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color.fromARGB(255, 15, 114, 175),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
