import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event_item.dart';
import '../widgets/event_card.dart';
import '../widgets/favorite_reminder_settings.dart';
import '../services/data_service.dart';

class ScheduleEntry {
  final EventItem event;
  final TimeSlot timeSlot;
  ScheduleEntry(this.event, this.timeSlot);
}

class FavoritesScreen extends StatefulWidget {
  final Set<String> favoriteEventIds;
  final Function(String) onToggleFavorite;
  final Function(String) onNavigateToMap;
  final Function(int) changeTab;
  final VoidCallback onSettingsChanged;

  const FavoritesScreen({
    super.key,
    required this.favoriteEventIds,
    required this.onToggleFavorite,
    required this.onNavigateToMap,
    required this.changeTab,
    required this.onSettingsChanged,
  });

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late FestivalDay _selectedDay;

  static final timeFormatter = DateFormat('HH:mm');

  final DataService _dataService = DataService();
  late Future<List<EventItem>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _eventsFuture = _dataService.getEvents();
    _selectedDay = _getInitialSelectedDay();
  }

  FestivalDay _getInitialSelectedDay() {
    final now = DateTime.now();
    if (now.year == 2025 && now.month == 9 && now.day == 15) {
      return FestivalDay.dayTwo;
    }
    return FestivalDay.dayOne;
  }

  List<Widget> _buildScheduleWidgets(List<ScheduleEntry> scheduleEntries) {
    if (scheduleEntries.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('この日にお気に入りの企画はありません'),
        ),
      ];
    }

    final List<Widget> scheduleWidgets = [];
    for (int i = 0; i < scheduleEntries.length; i++) {
      final currentEntry = scheduleEntries[i];

      scheduleWidgets.add(
        _buildTimeSlotHeader(
          currentEntry.timeSlot.startTime.toLocal(),
          currentEntry.timeSlot.endTime.toLocal(),
        ),
      );
      scheduleWidgets.add(
        EventCard(
          event: currentEntry.event,
          favoriteEventIds: widget.favoriteEventIds,
          onToggleFavorite: widget.onToggleFavorite,
          onNavigateToMap: widget.onNavigateToMap,
        ),
      );
    }
    return scheduleWidgets;
  }

  Widget _buildTimeSlotHeader(DateTime startTime, DateTime endTime) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        '${timeFormatter.format(startTime)} - ${timeFormatter.format(endTime)}',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'お気に入り企画',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Builder(
            builder: (context) {
              return TextButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    builder: (context) {
                      return FavoriteNotificationSettings(
                        onSettingsChanged: widget.onSettingsChanged,
                      );
                    },
                  );
                },
                icon: const Icon(Icons.notifications_active_outlined),
                label: const Text(
                  '通知設定',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: TextButton.styleFrom(
                  side: const BorderSide(color: Colors.white, width: 0.8),
                  foregroundColor:
                      Theme.of(context).appBarTheme.iconTheme?.color ??
                      Colors.white,
                  shadowColor: Colors.black,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<EventItem>>(
        future: _eventsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('データの読み込みに失敗しました'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('表示できる企画がありません'));
          }

          final allEvents = snapshot.data!;

          final favoritedEvents = allEvents
              .where(
                (event) =>
                    widget.favoriteEventIds.contains(event.id) &&
                    !event.hideFromList,
              )
              .toList();

          final undecidedEvents = favoritedEvents
              .where((event) => event.timeSlots == null)
              .toList();

          final allDayEvents = favoritedEvents
              .where(
                (event) => event.timeSlots != null && event.timeSlots!.isEmpty,
              )
              .toList();

          final timedEvents = favoritedEvents
              .where(
                (event) =>
                    event.timeSlots != null && event.timeSlots!.isNotEmpty,
              )
              .toList();

          final List<ScheduleEntry> scheduleItems = [];
          final dayToFilter = _selectedDay == FestivalDay.dayOne ? 14 : 15;

          for (final event in timedEvents) {
            if (event.timeSlots != null) {
              for (final slot in event.timeSlots!) {
                if (slot.startTime.toLocal().day == dayToFilter) {
                  scheduleItems.add(ScheduleEntry(event, slot));
                }
              }
            }
          }
          scheduleItems.sort(
            (a, b) => a.timeSlot.startTime.toLocal().compareTo(
              b.timeSlot.startTime.toLocal(),
            ),
          );

          return favoritedEvents.isEmpty
              ? const Center(child: Text('お気に入りに登録した企画はありません'))
              : ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    if (allDayEvents.isNotEmpty) ...[
                      const Text(
                        '終日開催企画',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ...allDayEvents.map(
                        (event) => EventCard(
                          event: event,
                          favoriteEventIds: widget.favoriteEventIds,
                          onToggleFavorite: widget.onToggleFavorite,
                          onNavigateToMap: widget.onNavigateToMap,
                        ),
                      ),
                      const Divider(height: 32, thickness: 1),
                    ],
                    const Text(
                      '時間指定企画',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: ToggleButtons(
                        isSelected: [
                          _selectedDay == FestivalDay.dayOne,
                          _selectedDay == FestivalDay.dayTwo,
                        ],
                        onPressed: (int index) {
                          setState(() {
                            _selectedDay = (index == 0)
                                ? FestivalDay.dayOne
                                : FestivalDay.dayTwo;
                          });
                        },
                        borderRadius: BorderRadius.circular(8.0),
                        children: const [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text('1日目'),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text('2日目'),
                          ),
                        ],
                      ),
                    ),
                    ..._buildScheduleWidgets(scheduleItems),
                    const Divider(height: 32, thickness: 1),

                    if (undecidedEvents.isNotEmpty) ...[
                      const Text(
                        '時間未定企画',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ...undecidedEvents.map(
                        (event) => EventCard(
                          event: event,
                          favoriteEventIds: widget.favoriteEventIds,
                          onToggleFavorite: widget.onToggleFavorite,
                          onNavigateToMap: widget.onNavigateToMap,
                        ),
                      ),
                    ],
                  ],
                );
        },
      ),
    );
  }
}
