import 'package:flutter/material.dart';
import 'package:flutter_app_yfa/screens/event_list_screen.dart';
import 'package:flutter_app_yfa/screens/favorites_screen.dart';
import 'package:flutter_app_yfa/screens/home_screen.dart';
import 'package:flutter_app_yfa/screens/map_screen.dart';
import 'package:flutter_app_yfa/screens/timetable_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/data_service.dart';
import 'services/notification_service.dart';
import 'models/event_item.dart';
import 'widgets/notification_permission_dialog.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  final DataService _dataService = DataService();
  final NotificationService _notificationService = NotificationService();
  List<EventItem>? _allEvents;

  int _selectedIndex = 0;
  final Set<String> _favoriteEventIds = {};
  String? _highlightedEventId;

  @override
  void initState() {
    super.initState();
    _dataService.getEvents().then((events) {
      if (mounted) {
        setState(() {
          _allEvents = events;
        });
      }
    });
    _loadFavorites();
  }

  void _rescheduleAllReminders() async {
    if (_allEvents == null) return;

    final prefs = await SharedPreferences.getInstance();
    final remindersEnabled = prefs.getBool('reminders_enabled') ?? true;

    if (!remindersEnabled) {
      for (final eventId in _favoriteEventIds) {
        EventItem? event;
        try { event = _allEvents!.firstWhere((e) => e.id == eventId); } catch (e) { event = null; }
        if (event != null) {
          await _notificationService.cancelReminder(event);
        }
      }
      return;
    }

    final permissionsStatus = await _notificationService.checkPermissions();
    if (!permissionsStatus.allGranted) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => NotificationPermissionDialog(permissionsStatus: permissionsStatus),
        );
      }
      return;
    }

    final reminderMinutesSettings = {
      5: prefs.getBool('reminder_5_min_enabled') ?? false,
      15: prefs.getBool('reminder_15_min_enabled') ?? true,
      30: prefs.getBool('reminder_30_min_enabled') ?? false,
      60: prefs.getBool('reminder_60_min_enabled') ?? false,
    };

    for (final eventId in _favoriteEventIds) {
      EventItem? event;
      try { event = _allEvents!.firstWhere((e) => e.id == eventId); } catch (e) { event = null; }
      if (event == null) continue;

      await _notificationService.cancelReminder(event);
      reminderMinutesSettings.forEach((minutes, isEnabled) {
        if (isEnabled) {
          _notificationService.scheduleReminder(context, event!, minutes);
        }
      });
    }

    if(mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('お気に入りの通知設定を更新しました。'),
          duration: Duration(seconds: 2),
        ),
      );
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

  void _toggleFavorite(String eventId) async {
    if (_allEvents == null) return;
    final isFavorited = _favoriteEventIds.contains(eventId);

    if (isFavorited) {
      EventItem? event;
      try { event = _allEvents!.firstWhere((e) => e.id == eventId); } catch (e) { event = null; }
      if (event != null) {
        await _notificationService.cancelReminder(event);
      }
    } else {
      final prefs = await SharedPreferences.getInstance();
      final remindersEnabled = prefs.getBool('reminders_enabled') ?? true;

      if (remindersEnabled) {
        final permissionsStatus = await _notificationService.checkPermissions();

        if (permissionsStatus.allGranted) {
          EventItem? event;
          try { event = _allEvents!.firstWhere((e) => e.id == eventId); } catch (e) { event = null; }
          if (event != null) {
            final reminderMinutesSettings = {
              5: prefs.getBool('reminder_5_min_enabled') ?? false,
              15: prefs.getBool('reminder_15_min_enabled') ?? true,
              30: prefs.getBool('reminder_30_min_enabled') ?? false,
              60: prefs.getBool('reminder_60_min_enabled') ?? false,
            };
            reminderMinutesSettings.forEach((minutes, isEnabled) {
              if (isEnabled) {
                _notificationService.scheduleReminder(context, event!, minutes);
              }
            });
          }
        } else {
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => NotificationPermissionDialog(permissionsStatus: permissionsStatus),
            );
          }
        }
      }
    }

    setState(() {
      if (isFavorited) {
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
        onSettingsChanged: _rescheduleAllReminders,
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
        onSettingsChanged: _rescheduleAllReminders,
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
        onSettingsChanged: _rescheduleAllReminders,
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
