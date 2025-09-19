import 'package:flutter/material.dart';
import 'package:flutter_app_yfa/screens/event_list_screen.dart';
import 'package:flutter_app_yfa/screens/favorites_screen.dart';
import 'package:flutter_app_yfa/screens/home_screen.dart';
import 'package:flutter_app_yfa/screens/map_screen.dart';
import 'package:flutter_app_yfa/screens/timetable_screen.dart';
import 'services/data_service.dart';
import 'services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> with WidgetsBindingObserver {
  final NotificationService _notificationService = NotificationService();

  int _selectedIndex = 0;
  final Set<String> _favoriteEventIds = {};
  String? _highlightedEventId;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    WidgetsBinding.instance.addObserver(this);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('フォアグラウンドでメッセージを受信しました: ${message.notification?.title}');

      if (message.notification != null && message.notification!.title != null && message.notification!.body != null) {
        _notificationService.showPushNotification(
          title: message.notification!.title!,
          body: message.notification!.body!,
        );
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _refreshDynamicData();
    }
  }

  Future<void> _refreshDynamicData() async {
    try {
      await DataService.instance.refreshDynamicData();
      if (mounted) {
        setState(() {
        });
      }
    } catch (e) {
      print("Error refreshing dynamic data: $e");
    }
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
        onTap: _onItemTapped,
      ),
    );
  }
}
