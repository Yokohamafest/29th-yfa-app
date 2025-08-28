import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/data_service.dart';
import '../models/event_item.dart';
import '../widgets/event_card.dart';
import '../models/enum_extensions.dart';

class EventListScreen extends StatefulWidget {
  final Set<String> favoriteEventIds;
  final Function(String) onToggleFavorite;
  final Function(String) onNavigateToMap;
  final Function(int) changeTab;

  const EventListScreen({
    super.key,
    required this.favoriteEventIds,
    required this.onToggleFavorite,
    required this.onNavigateToMap,
    required this.changeTab,
  });

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  List<EventItem>? _initialEvents;
  List<EventItem> _filteredEvents = [];

  final TextEditingController _searchController = TextEditingController();

  final Set<EventCategory> _selectedCategories = {};
  final Set<EventArea> _selectedAreas = {};
  final Set<FestivalDay> _selectedDays = {};
  TimeOfDay? _startTimeFilter;
  TimeOfDay? _endTimeFilter;
  bool _hideAllDayEvents = false;

  int _selectedDayForTimeFilter = 1;

  @override
  void initState() {
    super.initState();

    _initialEvents = DataService.instance.shuffledEvents;
    _filteredEvents = List.of(_initialEvents!);

    _searchController.addListener(_runFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _runFilter() {
    if (_initialEvents == null) return;
    List<EventItem> results = List.of(_initialEvents!);

    final searchQuery = _searchController.text.toLowerCase();

    if (searchQuery.isNotEmpty) {
      results = results.where((event) {
        final titleMatch = event.title.toLowerCase().contains(searchQuery);
        final groupMatch = event.groupName.toLowerCase().contains(searchQuery);
        return titleMatch || groupMatch;
      }).toList();
    }

    if (_selectedCategories.isNotEmpty) {
      results = results
          .where(
            (event) => event.categories.any(
              (category) => _selectedCategories.contains(category),
            ),
          )
          .toList();
    }

    if (_selectedAreas.isNotEmpty) {
      results = results
          .where(
            (event) => event.areas.any(
              (area) => _selectedAreas.contains(area),
            ),
          )
          .toList();
    }

    if (_selectedDays.isNotEmpty) {
      results = results.where((event) {
        if (_selectedDays.contains(FestivalDay.dayOne) &&
            (event.date == FestivalDay.dayOne ||
                event.date == FestivalDay.both)) {
          return true;
        }
        if (_selectedDays.contains(FestivalDay.dayTwo) &&
            (event.date == FestivalDay.dayTwo ||
                event.date == FestivalDay.both)) {
          return true;
        }
        if (_selectedDays.contains(FestivalDay.both) &&
            (event.date == FestivalDay.both)) {
          return true;
        }
        return false;
      }).toList();
    }

    if (_startTimeFilter != null || _endTimeFilter != null) {
      final int filterDay = _selectedDayForTimeFilter == 1 ? 14 : 15;

      final filterStart = _startTimeFilter != null
          ? DateTime(
              2025,
              9,
              filterDay,
              _startTimeFilter!.hour,
              _startTimeFilter!.minute,
            )
          : DateTime(2025, 9, 14, 4, 0);

      final filterEnd = _endTimeFilter != null
          ? DateTime(2025, 9, filterDay, _endTimeFilter!.hour, _endTimeFilter!.minute)
          : DateTime(2025, 9, 15, 4, 0);

      results = results.where((event) {
        if (event.timeSlots == null) {
          return false;
        }
        if (event.timeSlots!.isEmpty) {
          return !_hideAllDayEvents;
        }
        return event.timeSlots!.any((slot) {
          final end = slot.endTime?.toLocal() ?? DateTime(slot.startTime.year, slot.startTime.month, slot.startTime.day, 20, 0);
          return slot.startTime.toLocal().isBefore(filterEnd) &&
              end.isAfter(filterStart);
        });
      }).toList();
    }

    if (_startTimeFilter == null && _endTimeFilter == null && _hideAllDayEvents) {
      results = results.where((event) {
        return !(event.timeSlots == null || event.timeSlots!.isEmpty);
      }).toList();
    }

    setState(() {
      _filteredEvents = results;
    });
  }

  Widget _buildFilterChips<T extends Enum>(
    String title,
    Set<T> selectedValues,
    List<T> allValues,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 16.0),
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Wrap(
            spacing: 8.0,
            children: allValues.map((value) {
              final isSelected = selectedValues.contains(value);

              String displayName;
              if (value is FestivalDay) {
                displayName = value.name;
              } else if (value is EventArea) {
                displayName = value.name;
              } else if (value is EventCategory) {
                displayName = value.name;
              } else {
                displayName = value.name;
              }
              return FilterChip(
                label: Text(displayName),
                selected: isSelected,
                onSelected: (bool selected) {
                  setState(() {
                    if (selected) {
                      selectedValues.add(value);
                    } else {
                      selectedValues.remove(value);
                    }
                    _runFilter();
                  });
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '企画一覧',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Builder(
            builder: (context) {
              return TextButton.icon(
                onPressed: () {
                  Scaffold.of(context).openEndDrawer();
                },
                icon: const Icon(Icons.filter_list),
                label: const Text(
                  '絞り込み',
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
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF54A4DB)),
              child: Text(
                '検索・絞り込み',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'キーワード検索',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),

            _buildTimeFilter(),

            _buildFilterChips<FestivalDay>(
              '開催日',
              _selectedDays,
              FestivalDay.values,
            ),
            _buildFilterChips<EventCategory>(
              'カテゴリ',
              _selectedCategories,
              EventCategory.values,
            ),
            _buildFilterChips<EventArea>(
              'エリア',
              _selectedAreas,
              EventArea.values,
            ),
          ],
        ),
      ),

      body: _filteredEvents.isEmpty
          ? const Center(child: Text('表示できる企画がありません'))
          : ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: _filteredEvents.length,
              itemBuilder: (context, index) {
                final event = _filteredEvents[index];
                return EventCard(
                  event: event,
                  favoriteEventIds: widget.favoriteEventIds,
                  onToggleFavorite: widget.onToggleFavorite,
                  onNavigateToMap: widget.onNavigateToMap,
                );
              },
            ),
    );
  }

  Widget _buildTimeFilter() {
    final timeFormatter = DateFormat('HH:mm');
    Future<void> selectTime(bool isStartTime) async {
      final initialTime =
          (isStartTime ? _startTimeFilter : _endTimeFilter) ?? TimeOfDay.now();
      final TimeOfDay? picked = await showTimePicker(
        context: context,
        initialTime: initialTime,
      );
      if (picked != null) {
        setState(() {
          if (isStartTime) {
            _startTimeFilter = picked;
          } else {
            _endTimeFilter = picked;
          }
          _runFilter();
        });
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 8.0, right: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '時間帯',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              if (_startTimeFilter != null || _endTimeFilter != null)
                ToggleButtons(
                  isSelected: [
                    _selectedDayForTimeFilter == 1,
                    _selectedDayForTimeFilter == 2,
                  ],
                  onPressed: (index) {
                    setState(() {
                      _selectedDayForTimeFilter = index + 1;
                      _runFilter();
                    });
                  },
                  borderRadius: BorderRadius.circular(8.0),
                  constraints: const BoxConstraints(minHeight: 32.0, minWidth: 60.0),
                  children: const [
                    Text('1日目'),
                    Text('2日目'),
                  ],
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => selectTime(true),
                  child: Text(
                    _startTimeFilter != null
                        ? timeFormatter.format(
                            DateTime(
                              2025,
                              1,
                              1,
                              _startTimeFilter!.hour,
                              _startTimeFilter!.minute,
                            ),
                          )
                        : '開始時刻',
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Text('〜'),
              ),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => selectTime(false),
                  child: Text(
                    _endTimeFilter != null
                        ? timeFormatter.format(
                            DateTime(
                              2025,
                              1,
                              1,
                              _endTimeFilter!.hour,
                              _endTimeFilter!.minute,
                            ),
                          )
                        : '終了時刻',
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_startTimeFilter != null || _endTimeFilter != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextButton(
              child: const Text('時間指定をクリア'),
              onPressed: () {
                setState(() {
                  _startTimeFilter = null;
                  _endTimeFilter = null;
                  _hideAllDayEvents = false;
                  _runFilter();
                });
              },
            ),
          ),
          SwitchListTile(
            title: const Text('終日開催企画を非表示'),
            value: _hideAllDayEvents,
            onChanged: (bool value) {
              setState(() {
                _hideAllDayEvents = value;
                _runFilter();
              });
            },
          ),
        ],
      ],
    );
  }
}
