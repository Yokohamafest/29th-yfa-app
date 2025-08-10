import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/dummy_events.dart';
import '../models/event_item.dart';
import '../widgets/event_card.dart';
import '../widgets/favorite_notification_settings.dart';

class ScheduleEntry {
  final EventItem event;
  final TimeSlot timeSlot;
  ScheduleEntry(this.event, this.timeSlot);
}

class FavoritesScreen extends StatefulWidget {
  final Set<String> favoriteEventIds;
  final Function(String) onToggleFavorite;
  final Function(String) onNavigateToMap;

  const FavoritesScreen({
    super.key,
    required this.favoriteEventIds,
    required this.onToggleFavorite,
    required this.onNavigateToMap,
  });

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  FestivalDay _selectedDay = FestivalDay.dayOne;

  static final timeFormatter = DateFormat('HH:mm');

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
          currentEntry.timeSlot.startTime,
          currentEntry.timeSlot.endTime,
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
    final favoritedEvents = dummyEvents
        .where(
          (event) =>
              widget.favoriteEventIds.contains(event.id) && !event.hideFromList,
        )
        .toList();

    final allDayEvents = favoritedEvents
        .where((event) => event.timeSlots.isEmpty)
        .toList();

    final List<ScheduleEntry> scheduleItems = [];
    final dayToFilter = _selectedDay == FestivalDay.dayOne ? 14 : 15;

    for (final event in favoritedEvents) {
      for (final slot in event.timeSlots) {
        if (slot.startTime.day == dayToFilter) {
          scheduleItems.add(ScheduleEntry(event, slot));
        }
      }
    }
    // 開始時間でソート
    scheduleItems.sort(
      (a, b) => a.timeSlot.startTime.compareTo(b.timeSlot.startTime),
    );

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
                      return const FavoriteNotificationSettings();
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
                  backgroundColor: Color.fromARGB(255, 72, 151, 209),
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
        backgroundColor: Color.fromARGB(255, 84, 164, 219),
        foregroundColor: Colors.white,
      ),
      body: favoritedEvents.isEmpty
          ? const Center(child: Text('お気に入りに登録した企画はありません'))
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                if (allDayEvents.isNotEmpty) ...[
                  const Text(
                    '常時開催企画',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
              ],
            ),
    );
  }
}
