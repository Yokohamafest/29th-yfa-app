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

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

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
      _selectedIndex = 2;
      _highlightedEventId = eventId;
    });
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

  void changeTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(
        favoriteEventIds: _favoriteEventIds,
        onToggleFavorite: _toggleFavorite,
        onNavigateToMap: _navigateToMapAndHighlight,
        changeTab: changeTab,
      ),
      TimetableScreen(
        favoriteEventIds: _favoriteEventIds,
        onToggleFavorite: _toggleFavorite,
        onNavigateToMap: _navigateToMapAndHighlight,
        changeTab: changeTab,
      ),
      MapScreen(
        highlightedEventId: _highlightedEventId,
        favoriteEventIds: _favoriteEventIds,
        onToggleFavorite: _toggleFavorite,
        onNavigateToMap: _navigateToMapAndHighlight,
        changeTab: changeTab,
      ),
      EventListScreen(
        favoriteEventIds: _favoriteEventIds,
        onToggleFavorite: _toggleFavorite,
        onNavigateToMap: _navigateToMapAndHighlight,
        changeTab: changeTab,
      ),
      FavoritesScreen(
        favoriteEventIds: _favoriteEventIds,
        onToggleFavorite: _toggleFavorite,
        onNavigateToMap: _navigateToMapAndHighlight,
        changeTab: changeTab,
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
