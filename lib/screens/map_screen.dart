import 'dart:async';
import 'package:flutter/material.dart';
import '../data/dummy_map_data.dart';
import '../models/map_models.dart';
import '../data/dummy_events.dart';
import '../models/event_item.dart';
import 'event_detail_screen.dart';

class MapScreen extends StatefulWidget {
  final String? highlightedEventId;
  final Set<String> favoriteEventIds;
  final Function(String) onToggleFavorite;
  final Function(String) onNavigateToMap;

  const MapScreen({
    super.key,
    this.highlightedEventId,
    required this.favoriteEventIds,
    required this.onToggleFavorite,
    required this.onNavigateToMap,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MapInfo _currentMap = allMaps.first;

  Set<String> _highlightedPinIds = {};
  String? _blinkingPinId;

  MapFilterType _currentFilterType = MapFilterType.event;
  // イベントフィルター
  final Set<FestivalDay> _selectedDays = {};
  final Set<EventCategory> _selectedCategories = {};
  bool _filterFavorites = false;
  // サービスフィルター
  final Set<PinType> _selectedServiceTypes = {};
  final Map<String, MapType> _buildingPinToFloorMap = {
    'pin_b2': MapType.building2F1,
    'pin_b3': MapType.building3F1,
    'pin_b4': MapType.building4F1F2,
    // 体育館（5号館）はフロアマップがないので、ここには含めない
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.highlightedEventId != null) {
        _navigateToEvent(widget.highlightedEventId!);
      }
    });
  }

  @override
  void didUpdateWidget(covariant MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.highlightedEventId != null &&
        widget.highlightedEventId != oldWidget.highlightedEventId) {
      _navigateToEvent(widget.highlightedEventId!);
    }
  }

  void _navigateToEvent(String eventId) {
    EventItem? targetEvent;
    try {
      targetEvent = dummyEvents.firstWhere((e) => e.id == eventId);
    } catch (e) {
      targetEvent = null;
    }

    if (targetEvent == null) return;

    MapPin? targetPin;
    try {
      targetPin = allPins.firstWhere(
        (pin) =>
            pin.type == PinType.event && pin.title == targetEvent!.location,
      );
    } catch (e) {
      targetPin = null;
    }

    if (targetPin == null) {
      const buildingAreaMap = {
        '体育館': EventArea.building5,
        '2号館': EventArea.building2,
        '3号館': EventArea.building3,
        '4号館': EventArea.building4,
      };

      MapEntry<String, EventArea>? buildingEntry;
      try {
        buildingEntry = buildingAreaMap.entries.firstWhere(
          (entry) => entry.value == targetEvent!.area,
        );
      } catch (e) {
        buildingEntry = null;
      }

      if (buildingEntry != null) {
        final buildingTitle = buildingEntry.key;
        try {
          targetPin = allPins.firstWhere(
            (pin) => pin.type == PinType.building && pin.title == buildingTitle,
          );
        } catch (e) {
          targetPin = null;
        }
      }
    }

    if (targetPin == null) return;

    final MapInfo targetMap = allMaps.firstWhere(
      (map) => map.id == targetPin!.mapId,
    );

    setState(() {
      _currentMap = targetMap;
      _blinkingPinId = targetPin!.id;
      _highlightedPinIds = {};
    });

    Future.delayed(const Duration(seconds: 15), () {
      if (mounted) {
        setState(() {
          _blinkingPinId = null;
        });
      }
    });
  }

  void _applyFilters() {
    final newHighlightedPinIds = <String>{};
    bool isFilterActive = false;

    if (_currentFilterType == MapFilterType.event) {
      isFilterActive =
          _selectedDays.isNotEmpty ||
          _selectedCategories.isNotEmpty ||
          _filterFavorites;
      if (isFilterActive) {
        final filteredEvents = dummyEvents.where((event) {
          if (_selectedDays.isNotEmpty) {
            final isDayMatch =
                (_selectedDays.contains(FestivalDay.dayOne) &&
                    (event.date == FestivalDay.dayOne ||
                        event.date == FestivalDay.both)) ||
                (_selectedDays.contains(FestivalDay.dayTwo) &&
                    (event.date == FestivalDay.dayTwo ||
                        event.date == FestivalDay.both));
            if (!isDayMatch) return false;
          }
          if (_selectedCategories.isNotEmpty &&
              !event.categories.any(
                (category) => _selectedCategories.contains(category),
              )) {
            return false;
          }
          if (_filterFavorites && !widget.favoriteEventIds.contains(event.id)) {
            return false;
          }
          return true;
        }).toList();

        for (final pin in allPins) {
          bool shouldHighlight = false;
          if (pin.type == PinType.event) {
            shouldHighlight = filteredEvents.any(
              (event) => event.location == pin.title,
            );
          } else if (pin.type == PinType.building) {
            const buildingAreaMap = {
              '1号館': EventArea.building1 /* ... */,
              '2号館': EventArea.building2 /* ... */,
              '3号館': EventArea.building3 /* ... */,
              '4号館': EventArea.building4 /* ... */,
              '体育館': EventArea.building5,
            };
            final targetArea = buildingAreaMap[pin.title];
            if (targetArea != null) {
              shouldHighlight = filteredEvents.any(
                (event) => event.area == targetArea,
              );
            }
          }
          if (shouldHighlight) {
            newHighlightedPinIds.add(pin.id);
          }
        }
      }
    } else {
      isFilterActive = _selectedServiceTypes.isNotEmpty;
      if (isFilterActive) {
        for (final pin in allPins) {
          if (_selectedServiceTypes.contains(pin.type)) {
            newHighlightedPinIds.add(pin.id);

            if (pin.parentBuildingId != null) {
              newHighlightedPinIds.add(pin.parentBuildingId!);
            }
          }
        }
      }
    }

    setState(() {
      _blinkingPinId = null;
      _highlightedPinIds = isFilterActive ? newHighlightedPinIds : {};
    });
  }

  // --- UIを生成するヘルパーメソッド群 ---

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 3.0),
      decoration: BoxDecoration(
        color: color.withAlpha(51),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildMapPin(MapPin pin) {
    final bool isHighlighted = _highlightedPinIds.contains(pin.id);
    final bool isBlinking = _blinkingPinId == pin.id;

    return Positioned(
      left: pin.position.dx,
      top: pin.position.dy,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: InkWell(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              builder: (context) {
                // --- データ準備 ---
                List<EventItem> attachedEvents = [];

                final visibleEvents = dummyEvents
                    .where((event) => !event.hideFromList)
                    .toList();

                if (pin.type == PinType.building) {
                  const buildingAreaMap = {
                    '体育館': EventArea.building5,
                    '2号館': EventArea.building2,
                    '3号館': EventArea.building3,
                    '4号館': EventArea.building4,
                  };
                  final targetArea = buildingAreaMap[pin.title];
                  if (targetArea != null) {
                    attachedEvents = visibleEvents
                        .where((event) => event.area == targetArea)
                        .toList();
                  }
                }
                else if (pin.type == PinType.event) {
                  attachedEvents = visibleEvents
                      .where((event) => event.location == pin.title)
                      .toList();
                }
                // --- 検索ロジックここまで ---

                final servicesInBuilding = allPins
                    .where(
                      (servicePin) => servicePin.parentBuildingId == pin.id,
                    )
                    .toList();

                final bool isEventFilterActive =
                    _currentFilterType == MapFilterType.event &&
                    (_selectedDays.isNotEmpty ||
                        _selectedCategories.isNotEmpty ||
                        _filterFavorites);

                // --- UI構築 ---
                return Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.7,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    pin.title,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (pin.type == PinType.building &&
                                    _buildingPinToFloorMap.containsKey(pin.id))
                                  ElevatedButton(
                                    child: const Text('フロアマップ'),
                                    onPressed: () {
                                      final targetMapId =
                                          _buildingPinToFloorMap[pin.id];
                                      if (targetMapId != null) {
                                        setState(() {
                                          _currentMap = allMaps.firstWhere(
                                            (map) => map.id == targetMapId,
                                          );
                                        });
                                      }
                                      Navigator.of(context).pop();
                                    },
                                  ),
                              ],
                            ),
                            const Divider(height: 24),
                            if (pin.type == PinType.building &&
                                servicesInBuilding.isNotEmpty) ...[
                              const Text(
                                '館内設備',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              Wrap(
                                spacing: 16.0,
                                runSpacing: 8.0,
                                children: servicesInBuilding.map((servicePin) {
                                  IconData serviceIcon;
                                  switch (servicePin.type) {
                                    case PinType.restroom:
                                      serviceIcon = Icons.wc;
                                      break;
                                    case PinType.vendingMachine:
                                      serviceIcon = Icons.local_drink;
                                      break;
                                    case PinType.smokingArea:
                                      serviceIcon = Icons.smoking_rooms;
                                      break;
                                    case PinType.bikeParking:
                                      serviceIcon = Icons.pedal_bike;
                                      break;
                                    case PinType.recyclingStation:
                                      serviceIcon = Icons.recycling;
                                      break;
                                    default:
                                      serviceIcon = Icons.info;
                                  }
                                  return Chip(
                                    avatar: Icon(serviceIcon, size: 16),
                                    label: Text(servicePin.title),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 16.0),
                            ],
                            if (attachedEvents.isNotEmpty)
                              const Text(
                                '開催企画',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                          ],
                        ),
                      ),

                      if (attachedEvents.isNotEmpty)
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            itemCount: attachedEvents.length,
                            itemBuilder: (context, index) {
                              final event = attachedEvents[index];
                              bool shouldHighlight = false;
                              if (isEventFilterActive) {
                                bool matches = true;
                                if (_selectedDays.isNotEmpty) {
                                  final isDayMatch =
                                      (_selectedDays.contains(
                                            FestivalDay.dayOne,
                                          ) &&
                                          (event.date == FestivalDay.dayOne ||
                                              event.date ==
                                                  FestivalDay.both)) ||
                                      (_selectedDays.contains(
                                            FestivalDay.dayTwo,
                                          ) &&
                                          (event.date == FestivalDay.dayTwo ||
                                              event.date == FestivalDay.both));
                                  if (!isDayMatch) matches = false;
                                }
                                if (matches &&
                                    _selectedCategories.isNotEmpty &&
                                    !event.categories.any(
                                      (category) => _selectedCategories
                                          .contains(category),
                                    )) {
                                  matches = false;
                                }
                                if (matches &&
                                    _filterFavorites &&
                                    !widget.favoriteEventIds.contains(
                                      event.id,
                                    )) {
                                  matches = false;
                                }
                                shouldHighlight = matches;
                              }

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8.0),
                                decoration: BoxDecoration(
                                  color: shouldHighlight
                                      ? Colors.orange.shade100
                                      : const Color.fromARGB(22, 128, 127, 127),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: InkWell(
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EventDetailScreen(
                                          event: event,
                                          favoriteEventIds:
                                              widget.favoriteEventIds,
                                          onToggleFavorite:
                                              widget.onToggleFavorite,
                                          onNavigateToMap:
                                              widget.onNavigateToMap,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12.0,
                                      horizontal: 16.0,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                event.title,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if (event.groupName.isNotEmpty &&
                                                  event.groupName != ' ')
                                                Text(
                                                  event.groupName,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[700],
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              const SizedBox(height: 4.0),
                                              Wrap(
                                                spacing: 6.0,
                                                runSpacing: 4.0,
                                                children: [
                                                  ...event.categories.map(
                                                    (category) => _buildTag(
                                                      category.name,
                                                      Colors.blue,
                                                    ),
                                                  ),
                                                  _buildTag(
                                                    event.date.name,
                                                    Colors.green,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          Icons.chevron_right,
                                          color: Colors.grey[600],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
          child: MapPinWidget(
            pin: pin,
            isHighlighted: isHighlighted,
            isBlinking: isBlinking,
          ),
        ),
      ),
    );
  }

  Widget _buildMapSwitcher() {
    return Positioned(
      top: 10,
      left: 10,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
        ),
        child: Row(
          children: [
            DropdownButton<MapType>(
              value: _currentMap.id,
              onChanged: (MapType? newMap) {
                if (newMap != null) {
                  setState(() {
                    _currentMap = allMaps.firstWhere((m) => m.id == newMap);
                    _blinkingPinId = null; // マップ切り替えで点滅解除
                  });
                }
              },
              items: allMaps
                  .map(
                    (map) =>
                        DropdownMenuItem(value: map.id, child: Text(map.name)),
                  )
                  .toList(),
            ),
            if (_currentMap.id != MapType.campus)
              TextButton(
                onPressed: () => setState(() {
                  _currentMap = allMaps.first;
                  _blinkingPinId = null;
                }),
                child: const Text('全体マップに戻る'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDrawer() {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'マップピン絞り込み',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            SegmentedButton<MapFilterType>(
              segments: const [
                ButtonSegment(
                  value: MapFilterType.event,
                  label: Text('企画'),
                  icon: Icon(Icons.celebration),
                ),
                ButtonSegment(
                  value: MapFilterType.service,
                  label: Text('サービス'),
                  icon: Icon(Icons.info_outline),
                ),
              ],
              selected: {_currentFilterType},
              onSelectionChanged: (newSelection) {
                setState(() {
                  _currentFilterType = newSelection.first;
                  _applyFilters();
                });
              },
            ),
            const Divider(),
            Expanded(
              child: _currentFilterType == MapFilterType.event
                  ? _buildEventFilterOptions()
                  : _buildServiceFilterOptions(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventFilterOptions() {
    return ListView(
      padding: const EdgeInsets.all(8.0),
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 16.0),
          child: Text(
            "開催日",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Wrap(
            spacing: 8.0,
            children: FestivalDay.values.map((value) {
              final isSelected = _selectedDays.contains(value);
              return FilterChip(
                label: Text(value.name),
                selected: isSelected,
                onSelected: (bool selected) {
                  setState(() {
                    if (selected) {
                      _selectedDays.add(value);
                    } else {
                      _selectedDays.remove(value);
                    }
                    _applyFilters();
                  });
                },
              );
            }).toList(),
          ),
        ),

        Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 16.0),
          child: Text(
            "カテゴリ",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Wrap(
            spacing: 8.0,
            children: EventCategory.values.map((value) {
              final isSelected = _selectedCategories.contains(value);
              return FilterChip(
                label: Text(value.name),
                selected: isSelected,
                onSelected: (bool selected) {
                  setState(() {
                    if (selected) {
                      _selectedCategories.add(value);
                    } else {
                      _selectedCategories.remove(value);
                    }
                    _applyFilters();
                  });
                },
              );
            }).toList(),
          ),
        ),

        SwitchListTile(
          title: const Text('お気に入り登録済'),
          value: _filterFavorites,
          onChanged: (value) {
            setState(() {
              _filterFavorites = value;
              _applyFilters();
            });
          },
        ),
      ],
    );
  }

  Widget _buildServiceFilterOptions() {
    final serviceTypes = [
      PinType.restroom,
      PinType.vendingMachine,
      PinType.smokingArea,
      PinType.bikeParking,
      PinType.recyclingStation,
    ];
    return ListView(
      padding: const EdgeInsets.all(8.0),
      children: serviceTypes.map((type) {
        return CheckboxListTile(
          title: Text(type.displayName),
          value: _selectedServiceTypes.contains(type),
          onChanged: (selected) {
            setState(() {
              if (selected == true) {
                _selectedServiceTypes.add(type);
              } else {
                _selectedServiceTypes.remove(type);
              }
              _applyFilters();
            });
          },
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentPins = allPins
        .where((p) => p.mapId == _currentMap.id)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text("マップ"),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      endDrawer: _buildFilterDrawer(),
      body: Stack(
        children: [
          InteractiveViewer(
            minScale: 0.5,
            maxScale: 5.0,
            child: Center(
              child: Stack(
                children: [
                  Image.asset(_currentMap.imagePath),
                  ...currentPins.map((pin) => _buildMapPin(pin)),
                ],
              ),
            ),
          ),

          _buildMapSwitcher(),
        ],
      ),
    );
  }
}

enum MapFilterType { event, service }

extension PinTypeExt on PinType {
  String get displayName {
    switch (this) {
      case PinType.event:
        return '企画';
      case PinType.restroom:
        return 'お手洗い';
      case PinType.vendingMachine:
        return '自動販売機';
      case PinType.bikeParking:
        return '駐輪場';
      case PinType.smokingArea:
        return '喫煙所';
      case PinType.recyclingStation:
        return '資源ステーション';
      case PinType.building:
        return '建物';
    }
  }
}

class MapPinWidget extends StatefulWidget {
  final MapPin pin;
  final bool isHighlighted;
  final bool isBlinking;
  final double? width;
  final double? height;

  const MapPinWidget({
    super.key,
    required this.pin,
    this.isHighlighted = false,
    this.isBlinking = false,
    this.width,
    this.height,
  });

  @override
  State<MapPinWidget> createState() => _MapPinWidgetState();
}

class _MapPinWidgetState extends State<MapPinWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    if (widget.isBlinking) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant MapPinWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isBlinking != oldWidget.isBlinking) {
      if (widget.isBlinking) {
        _animationController.repeat(reverse: true);
      } else {
        _animationController.stop();
        _animationController.value = 1.0;
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    IconData? serviceIcon;
    if (widget.pin.type != PinType.building &&
        widget.pin.type != PinType.event) {
      switch (widget.pin.type) {
        case PinType.restroom:
          serviceIcon = Icons.wc;
          break;
        case PinType.vendingMachine:
          serviceIcon = Icons.local_drink;
          break;
        // TODO:他のサービスピンも同様に追加 ...
        default:
          serviceIcon = Icons.info;
      }
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final borderColor = widget.isBlinking
            ? Color.lerp(
                Colors.red.shade700,
                Colors.yellow.shade700,
                _animationController.value,
              )!
            : (widget.isHighlighted
                  ? Colors.yellow.shade700
                  : Colors.grey.shade400);

        final borderWidth = widget.isBlinking || widget.isHighlighted
            ? 3.0
            : 1.0;

        return Container(
          width: widget.width,
          height: widget.height,
          padding:
              widget.pin.padding ??
              const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: borderColor, width: borderWidth),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: serviceIcon != null
              ? Icon(
                  serviceIcon,
                  color: Colors.blue.shade800,
                  size: widget.pin.iconSize ?? 20,
                )
              : Text(
                  widget.pin.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: widget.pin.fontSize ?? 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
        );
      },
    );
  }
}
