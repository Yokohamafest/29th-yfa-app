import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event_item.dart';
import 'event_detail_screen.dart';
import 'dart:math' as math;
import '../services/data_service.dart';

class TimetableScreen extends StatefulWidget {
  final Set<String> favoriteEventIds;
  final Function(String) onToggleFavorite;
  final Function(String) onNavigateToMap;
  final Function(int) changeTab;

  const TimetableScreen({
    super.key,
    required this.favoriteEventIds,
    required this.onToggleFavorite,
    required this.onNavigateToMap,
    required this.changeTab,
  });

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  late FestivalDay _selectedDay;
  final double _hourHeight = 120.0;
  final double _leftColumnWidth = 50.0;

  @override
  void initState() {
    super.initState();
    _selectedDay = _getInitialSelectedDay();
  }

  FestivalDay _getInitialSelectedDay() {
    final now = DateTime.now();
    if (now.year == 2025 && now.month == 9 && now.day == 15) {
      return FestivalDay.dayTwo;
    }
    return FestivalDay.dayOne;
  }

  @override
  Widget build(BuildContext context) {
    final allEvents = DataService.instance.events;

    return Scaffold(
      appBar: AppBar(title: const Text('タイムテーブル')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: ToggleButtons(
              isSelected: [
                _selectedDay == FestivalDay.dayOne,
                _selectedDay == FestivalDay.dayTwo,
              ],
              onPressed: (index) {
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
                  child: Text('1日目 (9/14)'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('2日目 (9/15)'),
                ),
              ],
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: _leftColumnWidth),
              _buildHeaderCell('体育館ステージ', Colors.orange.shade400),
              SizedBox(width: 3),
              _buildHeaderCell('31Aステージ', Colors.green.shade400),
              SizedBox(width: 3),
              _buildHeaderCell('32Aステージ', Colors.blue.shade400),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Stack(
                children: [
                  _buildGridAndTimeAxis(),
                  Row(
                    children: [
                      SizedBox(width: _leftColumnWidth),
                      _buildStageColumn(
                        '体育館',
                        Colors.orange.shade400,
                        allEvents,
                      ),
                      const SizedBox(width: 3),
                      _buildStageColumn(
                        '31A',
                        Colors.green.shade400,
                        allEvents,
                      ),
                      const SizedBox(width: 3),
                      _buildStageColumn(
                        '32A',
                        Colors.blue.shade400,
                        allEvents,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String title, Color backgroundColor) {
    return Expanded(
      child: Column(
        children: [
          Container(
            height: 60,
            color: backgroundColor,
            alignment: Alignment.center,
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridAndTimeAxis() {
    final List<Widget> children = [];
    for (int hour = 10; hour < 21; hour++) {
      final topPosition = (hour - 10) * _hourHeight;
      children.add(
        Positioned(
          top: topPosition,
          left: 0,
          child: SizedBox(
            width: _leftColumnWidth,
            height: _hourHeight,
            child: Center(child: Text('$hour:00')),
          ),
        ),
      );
      // 1時間ごとの実線
      children.add(
        Positioned(
          top: topPosition + (_hourHeight / 2),
          left: _leftColumnWidth,
          right: 0,
          child: Container(
            height: 1.5,
            color: const Color.fromARGB(255, 70, 70, 70),
          ),
        ),
      );
      // 30分ごとの破線
      if (hour < 20) {
        children.add(
          Positioned(
            top: topPosition + _hourHeight,
            left: _leftColumnWidth,
            right: 0,
            child: Row(
              children: List.generate(
                30,
                (index) => Expanded(
                  child: Container(
                    height: 0.8,
                    color: index % 2 == 0
                        ? const Color.fromARGB(255, 70, 70, 70)
                        : Colors.transparent,
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }
    return SizedBox(
      height: (21 - 10) * _hourHeight,
      child: Stack(children: children),
    );
  }

  Widget _buildStageColumn(
    String locationName,
    Color backgroundColor,
    List<EventItem> allEvents,
  ) {
    final eventsForStage = allEvents.where((event) {
      final isSameLocation = event.locations.contains(locationName);
      final isTimed = event.timeSlots != null && event.timeSlots!.isNotEmpty;
      return isSameLocation && isTimed;
    }).toList();

    final List<Widget> cards = [];
    for (final event in eventsForStage) {
      for (final timeSlot in event.timeSlots!) {
        if (timeSlot.startTime.toLocal().day !=
            (_selectedDay == FestivalDay.dayOne ? 14 : 15)) {
          continue;
        }

        final start = timeSlot.startTime.toLocal();
        final end = timeSlot.endTime?.toLocal() ?? DateTime(start.year, start.month, start.day, 20, 0);
        final topPosition =
            ((start.hour - 10) * 60 + start.minute) / 60.0 * _hourHeight;

        final durationHeight =
            end.difference(start).inMinutes / 60.0 * _hourHeight;
        const double minHeight = 45.0;
        final cardHeight = math.max(durationHeight, minHeight);

        cards.add(
          Positioned(
            top: topPosition + 60,
            left: 0,
            right: 0,
            height: cardHeight,
            child: _TimetableEventCard(
              event: event,
              timeSlot: timeSlot,
              cardHeight: cardHeight,
              cardColor: backgroundColor,
              favoriteEventIds: widget.favoriteEventIds,
              onToggleFavorite: widget.onToggleFavorite,
              onNavigateToMap: widget.onNavigateToMap,
            ),
          ),
        );
      }
    }

    return Expanded(
      child: Container(
        color: backgroundColor.withAlpha(25),
        child: SizedBox(
          height: (21 - 10) * _hourHeight,
          child: Stack(children: cards),
        ),
      ),
    );
  }
}

class _TimetableEventCard extends StatelessWidget {
  final EventItem event;
  final TimeSlot timeSlot;
  final double cardHeight;
  final Color cardColor;
  final Set<String> favoriteEventIds;
  final Function(String) onToggleFavorite;
  final Function(String) onNavigateToMap;

  const _TimetableEventCard({
    required this.event,
    required this.timeSlot,
    required this.cardHeight,
    required this.cardColor,
    required this.favoriteEventIds,
    required this.onToggleFavorite,
    required this.onNavigateToMap,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('HH:mm');

    int titleMaxLines;
    int groupNameMaxLines;

    final end = timeSlot.endTime?.toLocal() ?? DateTime(timeSlot.startTime.year, timeSlot.startTime.month, timeSlot.startTime.day, 20, 0);

    if (cardHeight < 65) {
      titleMaxLines = 1;
      groupNameMaxLines = 1;
    } else {
      final durationInMinutes = end
          .difference(timeSlot.startTime.toLocal())
          .inMinutes;
      final thirtyMinuteBlocks = (durationInMinutes / 30).ceil();
      titleMaxLines = math.max(2, thirtyMinuteBlocks * 2);
      groupNameMaxLines = math.max(1, thirtyMinuteBlocks);
    }

    return Card(
      color: cardColor,
      elevation: 2.0,
      margin: const EdgeInsets.all(1.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
      clipBehavior: Clip.none,
      child: InkWell(
        onTap: event.disableDetailsLink
            ? null
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EventDetailScreen(
                      event: event,
                      favoriteEventIds: favoriteEventIds,
                      onToggleFavorite: onToggleFavorite,
                      onNavigateToMap: onNavigateToMap,
                    ),
                  ),
                );
              },

        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: titleMaxLines,
                  ),
                  if (event.groupName.isNotEmpty)
                    Text(
                      event.groupName,
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                      maxLines: groupNameMaxLines,
                    ),
                ],
              ),
            ),
            Positioned(
              top: -12,
              left: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 2.0,
                  vertical: 1.0,
                ),
                color: Colors.black.withAlpha(204),
                child: Text(
                  '${formatter.format(timeSlot.startTime.toLocal())} - ${formatter.format(end.toLocal())}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
