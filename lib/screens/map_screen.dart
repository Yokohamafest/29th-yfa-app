import 'dart:async';
import 'package:flutter/material.dart';
import '../models/map_models.dart';
import '../models/event_item.dart';
import 'event_detail_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/announcement_item.dart';
import 'announcement_detail_screen.dart';
import 'options_screen.dart';
import '../services/data_service.dart';
import '../widgets/tag_widget.dart';
import '../models/enum_extensions.dart';
import '../services/notification_service.dart';
import '../utils/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/map_tutorial_overlay.dart';
import 'package:shimmer/shimmer.dart';

enum BuildingSelection { campus, building2, building3, building4 }

class MapScreen extends StatefulWidget {
  final String? highlightedEventId;
  final Set<String> favoriteEventIds;
  final Function(String) onToggleFavorite;
  final Function(String) onNavigateToMap;
  final Function(int) changeTab;
  final Future<void> Function() onSettingsChanged;

  const MapScreen({
    super.key,
    this.highlightedEventId,
    required this.favoriteEventIds,
    required this.onToggleFavorite,
    required this.onNavigateToMap,
    required this.changeTab,
    required this.onSettingsChanged,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final DataService _dataService = DataService();
  late Future<List<dynamic>> _mapDataFuture;

  List<MapInfo>? _allMaps;
  List<MapPin>? _allPins;
  List<EventItem>? _allEvents;
  List<AnnouncementItem>? _allAnnouncements;

  BuildingSelection _selectedBuilding = BuildingSelection.campus;
  MapInfo? _currentMap;

  Set<String> _highlightedPinIds = {};
  String? _blinkingPinId;

  MapFilterType _currentFilterType = MapFilterType.event;
  final Set<FestivalDay> _selectedDays = {};
  final Set<EventCategory> _selectedCategories = {};
  bool _filterFavorites = false;
  final Set<PinType> _selectedServiceTypes = {};
  final Map<String, MapType> _buildingPinToFloorMap = {
    'building_2': MapType.building2F1,
    'building_3': MapType.building3F1,
    'building_4': MapType.building4F1,
    //フロアマップを持つ建物のピンのid（pin_b2など）とそのピンから遷移したいフロアマップをMapTypeのenumから選択して対応付ける（建物のマップピンのモーダルからフロアマップへ遷移するため）
    // 1号館および体育館（5号館）はフロアマップがないので、ここには含めない（もしフロアマップを持つ建物が増えたらここにも追加する）
  };

  late final Map<BuildingSelection, List<MapInfo>> _floorMapsByBuilding;

  final TransformationController _transformationController =
      TransformationController();
  double _currentScale = 1.0;
  static const double _zoomThreshold = 2.5;

  String? _highlightedPinIdForNavigation;

  bool _showTutorialOverlay = false;

  @override
  void initState() {
    super.initState();
    _mapDataFuture = Future.wait([
      _dataService.getMaps(),
      _dataService.getPins(),
      _dataService.getEvents(),
      _dataService.getAnnouncements(),
    ]);

    _mapDataFuture.then((data) {
      if (mounted) {
        _allMaps = data[0] as List<MapInfo>;
        _allPins = data[1] as List<MapPin>;
        _allEvents = data[2] as List<EventItem>;
        _allAnnouncements = data[3] as List<AnnouncementItem>;

        _floorMapsByBuilding = {
          BuildingSelection.building2:
              _allMaps!.where((m) => m.id.name.startsWith('building2')).toList()
                ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
          BuildingSelection.building3:
              _allMaps!.where((m) => m.id.name.startsWith('building3')).toList()
                ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
          BuildingSelection.building4:
              _allMaps!.where((m) => m.id.name.startsWith('building4')).toList()
                ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
        };

        setState(() {
          _currentMap = _allMaps!.firstWhere((m) => m.id == MapType.campus);
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (widget.highlightedEventId != null) {
            _navigateToEvent(widget.highlightedEventId!);
          }
        });
      }
    });
    _transformationController.addListener(() {
      if (mounted) {
        setState(() {
          _currentScale = _transformationController.value.getMaxScaleOnAxis();
        });
      }
    });
    _checkIfShowTutorial();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _checkIfShowTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final bool hasShown = prefs.getBool('has_shown_map_tutorial') ?? false;

    if (!hasShown && mounted) {
      setState(() {
        _showTutorialOverlay = true;
      });
    }
  }

  Future<void> _launchURL(Uri url) async {
    if (!await launchUrl(url)) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${url.toString()} を開けませんでした')));
    }
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
      targetEvent = _allEvents!.firstWhere((e) => e.id == eventId);
    } catch (e) {
      targetEvent = null;
    }

    if (targetEvent == null) return;

    MapPin? targetPin;
    try {
      targetPin = _allPins!.firstWhere(
        (pin) =>
            pin.type == PinType.location &&
            targetEvent!.locations.contains(pin.title),
      );
    } catch (e) {
      targetPin = null;
    }

    if (targetPin == null) {
      const buildingAreaMap = {
        '1号館': EventArea.building1,
        '2号館': EventArea.building2,
        '3号館': EventArea.building3,
        '4号館': EventArea.building4,
        '5号館': EventArea.building5,
      };

      MapEntry<String, EventArea>? buildingEntry;
      try {
        buildingEntry = buildingAreaMap.entries.firstWhere(
          (entry) => entry.value == targetEvent!.areas.first,
        );
      } catch (e) {
        buildingEntry = null;
      }

      if (buildingEntry != null) {
        final buildingTitle = buildingEntry.key;
        try {
          targetPin = _allPins!.firstWhere(
            (pin) => pin.type == PinType.building && pin.title == buildingTitle,
          );
        } catch (e) {
          targetPin = null;
        }
      }
    }

    if (targetPin == null) return;

    final MapInfo targetMap = _allMaps!.firstWhere(
      (map) => map.id == targetPin!.mapId,
    );

    BuildingSelection targetBuilding = BuildingSelection.campus;
    if (targetMap.id.name.startsWith('building2')) {
      targetBuilding = BuildingSelection.building2;
    }
    if (targetMap.id.name.startsWith('building3')) {
      targetBuilding = BuildingSelection.building3;
    }
    if (targetMap.id.name.startsWith('building4')) {
      targetBuilding = BuildingSelection.building4;
    }

    setState(() {
      _selectedBuilding = targetBuilding;
      _currentMap = targetMap;
      _blinkingPinId = targetPin!.id;
      _highlightedPinIdForNavigation = targetPin.id;
      _highlightedPinIds = {};
    });

    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          _blinkingPinId = null;
          _highlightedPinIdForNavigation = null;
        });
      }
    });
  }

  void _applyFilters() {
    if (_highlightedPinIdForNavigation != null) {
      setState(() {
        _highlightedPinIdForNavigation = null;
      });
    }

    final newHighlightedPinIds = <String>{};
    bool isFilterActive = false;

    if (_currentFilterType == MapFilterType.event) {
      isFilterActive =
          _selectedDays.isNotEmpty ||
          _selectedCategories.isNotEmpty ||
          _filterFavorites;
      if (isFilterActive) {
        final filteredEvents = _allEvents!.where((event) {
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

        for (final pin in _allPins!) {
          bool shouldHighlight = false;
          if (pin.type == PinType.location) {
            shouldHighlight = filteredEvents.any(
              (event) => event.locations.contains(pin.title),
            );
          } else if (pin.type == PinType.building) {
            const buildingAreaMap = {
              '1号館': EventArea.building1,
              '2号館': EventArea.building2,
              '3号館': EventArea.building3,
              '4号館': EventArea.building4,
              '5号館': EventArea.building5,
            };
            final targetArea = buildingAreaMap[pin.title];
            if (targetArea != null) {
              shouldHighlight = filteredEvents.any(
                (event) => event.areas.contains(targetArea),
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
        for (final pin in _allPins!) {
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

  Widget _buildMapPin(
    MapPin pin,
    BoxConstraints constraints,
    List<EventItem> allEvents,
    List<MapPin> allPins,
  ) {
    final bool isHighlighted = _highlightedPinIds.contains(pin.id);
    final bool isBlinking = _blinkingPinId == pin.id;

    final absoluteX = pin.position.dx * constraints.maxWidth;
    final absoluteY = pin.position.dy * constraints.maxHeight;

    final Offset translationOffset;
    if (pin.visualStyle == PinVisualStyle.marker) {
      translationOffset = const Offset(-0.5, -1.0);
    } else {
      translationOffset = const Offset(-0.5, -0.5);
    }

    return Positioned(
      left: absoluteX,
      top: absoluteY,
      child: FractionalTranslation(
        translation: translationOffset,
        child: InkWell(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              builder: (context) {
                List<EventItem> attachedEvents = [];

                final visibleEvents = _allEvents!
                    .where((event) => !event.hideFromList)
                    .toList();

                if (pin.type == PinType.building) {
                  const buildingAreaMap = {
                    '1号館': EventArea.building1,
                    '2号館': EventArea.building2,
                    '3号館': EventArea.building3,
                    '4号館': EventArea.building4,
                    '5号館': EventArea.building5,
                  };
                  final targetArea = buildingAreaMap[pin.title];
                  if (targetArea != null) {
                    attachedEvents = visibleEvents
                        .where((event) => event.areas.contains(targetArea))
                        .toList();
                  }
                } else if (pin.type == PinType.location) {
                  attachedEvents = visibleEvents
                      .where((event) => event.locations.contains(pin.title))
                      .toList();
                }

                final servicesInBuilding = _allPins!
                    .where(
                      (servicePin) => servicePin.parentBuildingId == pin.id,
                    )
                    .toList();

                final bool isEventFilterActive =
                    _currentFilterType == MapFilterType.event &&
                    (_selectedDays.isNotEmpty ||
                        _selectedCategories.isNotEmpty ||
                        _filterFavorites);

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
                                        BuildingSelection newBuildingSelection =
                                            BuildingSelection.campus;
                                        if (targetMapId.name.startsWith(
                                          'building2',
                                        )) {
                                          newBuildingSelection =
                                              BuildingSelection.building2;
                                        }
                                        if (targetMapId.name.startsWith(
                                          'building3',
                                        )) {
                                          newBuildingSelection =
                                              BuildingSelection.building3;
                                        }
                                        if (targetMapId.name.startsWith(
                                          'building4',
                                        )) {
                                          newBuildingSelection =
                                              BuildingSelection.building4;
                                        }

                                        setState(() {
                                          _selectedBuilding =
                                              newBuildingSelection;
                                          _currentMap = _allMaps!.firstWhere(
                                            (map) => map.id == targetMapId,
                                          );
                                        });
                                      }
                                      Navigator.of(context).pop();
                                    },
                                  ),
                              ],
                            ),

                            if ((pin.detailText != null || pin.link != null) &&
                                pin.showDetailText) ...[
                              const Divider(height: 24),
                              if (pin.detailText != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Text(
                                    pin.detailText!,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              if (pin.link != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: TextButton(
                                    child: Text(pin.link!.text),
                                    onPressed: () {
                                      final link = pin.link!;
                                      switch (link.actionType) {
                                        case PinLinkActionType.url:
                                          final url = Uri.parse(
                                            link.actionValue,
                                          );
                                          _launchURL(url);
                                          break;
                                        case PinLinkActionType.eventDetail:
                                          final eventId = link.actionValue;
                                          EventItem? targetEvent;
                                          try {
                                            targetEvent = _allEvents!
                                                .firstWhere(
                                                  (e) => e.id == eventId,
                                                );
                                          } catch (e) {
                                            targetEvent = null;
                                          }

                                          if (targetEvent != null) {
                                            Navigator.of(context).pop();
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    EventDetailScreen(
                                                      event: targetEvent!,
                                                      favoriteEventIds: widget
                                                          .favoriteEventIds,
                                                      onToggleFavorite: widget
                                                          .onToggleFavorite,
                                                      onNavigateToMap: widget
                                                          .onNavigateToMap,
                                                    ),
                                              ),
                                            );
                                          }
                                          break;
                                        case PinLinkActionType
                                            .announcementDetail:
                                          final announcementId =
                                              link.actionValue;
                                          AnnouncementItem? targetAnnouncement;
                                          try {
                                            if (_allAnnouncements != null) {
                                              targetAnnouncement =
                                                  _allAnnouncements!.firstWhere(
                                                    (announcement) =>
                                                        announcement.id ==
                                                        announcementId,
                                                  );
                                            }
                                          } catch (e) {
                                            targetAnnouncement = null;
                                          }
                                          if (targetAnnouncement != null) {
                                            Navigator.of(context).pop();
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    AnnouncementDetailScreen(
                                                      announcement:
                                                          targetAnnouncement!,
                                                    ),
                                              ),
                                            );
                                          }
                                          break;
                                        case PinLinkActionType.option:
                                          Navigator.of(context).pop();
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  OptionsScreen(
                                                    onSettingsChanged: widget
                                                        .onSettingsChanged,
                                                    notificationService:
                                                        NotificationService(),
                                                  ),
                                            ),
                                          );
                                          break;
                                        case PinLinkActionType.map:
                                          final mapIdString = link.actionValue;
                                          MapInfo? targetMap;
                                          try {
                                            final targetMapType = MapType.values
                                                .byName(mapIdString);
                                            targetMap = _allMaps!.firstWhere(
                                              (map) => map.id == targetMapType,
                                            );
                                          } catch (e) {
                                            targetMap = null;
                                          }

                                          if (targetMap != null) {
                                            BuildingSelection
                                            newBuildingSelection =
                                                BuildingSelection.campus;
                                            if (targetMap.id.name.startsWith(
                                              'building2',
                                            )) {
                                              newBuildingSelection =
                                                  BuildingSelection.building2;
                                            }
                                            if (targetMap.id.name.startsWith(
                                              'building3',
                                            )) {
                                              newBuildingSelection =
                                                  BuildingSelection.building3;
                                            }
                                            if (targetMap.id.name.startsWith(
                                              'building4',
                                            )) {
                                              newBuildingSelection =
                                                  BuildingSelection.building4;
                                            }

                                            setState(() {
                                              _selectedBuilding =
                                                  newBuildingSelection;
                                              _currentMap = targetMap;
                                            });
                                          }
                                          Navigator.of(context).pop();
                                          break;
                                        case PinLinkActionType.timetable:
                                          Navigator.of(context).pop();
                                          widget.changeTab(1);
                                      }
                                    },
                                  ),
                                ),
                            ],

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
                                                  TagWidget(
                                                    text: event.date.name,
                                                    color: Colors.green,
                                                  ),
                                                  ...event.categories.map(
                                                    (category) => TagWidget(
                                                      text: category.name,
                                                      color: Colors.blue,
                                                    ),
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

  Widget _buildFilterDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF54A4DB)),
            child: Text(
              'マップピン検索',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: SegmentedButton<MapFilterType>(
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
          ),
          const Divider(),
          _currentFilterType == MapFilterType.event
              ? _buildEventFilterOptions()
              : _buildServiceFilterOptions(),
        ],
      ),
    );
  }

  Widget _buildEventFilterOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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

        Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 16.0),
          child: Text(
            "その他",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Wrap(
            spacing: 8.0,
            children: [
              FilterChip(
                label: const Text('お気に入り登録済'),
                selected: _filterFavorites,
                onSelected: (bool selected) {
                  setState(() {
                    _filterFavorites = selected;
                    _applyFilters();
                  });
                },
              ),
            ],
          ),
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
    return Column(
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

  Widget _buildBuildingSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SegmentedButton<BuildingSelection>(
            segments: const [
              ButtonSegment(value: BuildingSelection.campus, label: Text('全体')),
              ButtonSegment(
                value: BuildingSelection.building2,
                label: Text('2号館'),
              ),
              ButtonSegment(
                value: BuildingSelection.building3,
                label: Text('3号館'),
              ),
              ButtonSegment(
                value: BuildingSelection.building4,
                label: Text('4号館'),
              ),
            ],
            selected: {_selectedBuilding},
            onSelectionChanged: (newSelection) {
              setState(() {
                _selectedBuilding = newSelection.first;
                _highlightedPinIdForNavigation = null;
                if (_selectedBuilding == BuildingSelection.campus) {
                  _currentMap = _allMaps!.firstWhere(
                    (m) => m.id == MapType.campus,
                  );
                } else {
                  _currentMap = _floorMapsByBuilding[_selectedBuilding]!.first;
                }
                _blinkingPinId = null;
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFloorSelector() {
    final floors = _floorMapsByBuilding[_selectedBuilding]!;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: ToggleButtons(
          isSelected: floors.map((map) => map.id == _currentMap!.id).toList(),
          onPressed: (index) {
            setState(() {
              _currentMap = floors[index];
              _highlightedPinIdForNavigation = null;
            });
          },
          borderRadius: BorderRadius.circular(8.0),
          children: floors
              .map(
                (map) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(map.name.split(' ').last),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FutureBuilder<List<dynamic>>(
          future: _mapDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting ||
                _currentMap == null) {
              return Scaffold(
                appBar: AppBar(title: const Text('マップ')),
                body: const Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return Scaffold(
                appBar: AppBar(title: const Text('マップ')),
                body: const Center(child: Text('データの読み込みに失敗しました')),
              );
            }

            final currentPins = _allPins!
                .where((p) => p.mapId == _currentMap!.id)
                .toList();

            return Scaffold(
              appBar: AppBar(
                title: Text(
                  "マップ",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                actions: [
                  Builder(
                    builder: (context) {
                      return TextButton.icon(
                        onPressed: () {
                          Scaffold.of(context).openEndDrawer();
                        },
                        icon: const Icon(Icons.search),
                        label: const Text(
                          'マップピン検索',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: TextButton.styleFrom(
                          side: const BorderSide(
                            color: Colors.white,
                            width: 0.8,
                          ),
                          foregroundColor:
                              Theme.of(context).appBarTheme.iconTheme?.color ??
                              Colors.white,
                          shadowColor: Colors.black,
                        ),
                      );
                    },
                  ),
                ],
              ),
              endDrawer: _buildFilterDrawer(),
              body: Column(
                children: [
                  _buildBuildingSelector(),
                  if (_selectedBuilding != BuildingSelection.campus)
                    _buildFloorSelector(),

                  Expanded(
                    child: InteractiveViewer(
                      transformationController: _transformationController,
                      minScale: 0.5,
                      maxScale: 5.0,
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: _currentMap!.aspectRatio,
                          child: Stack(
                            children: [
                              CachedNetworkImage(
                                key: ValueKey(_currentMap!.id),
                                imageUrl: _currentMap!.imagePath,
                                fit: BoxFit.contain,
                                placeholder: (context, url) => Shimmer.fromColors(
                                  baseColor: Colors.grey.shade300,
                                  highlightColor: AppColors.tertiary.withAlpha(150),
                                  child: Container(color: Colors.white),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey[300],
                                  child: const Center(
                                    child: Icon(
                                      Icons.image_not_supported,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned.fill(
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    return Stack(
                                      children: currentPins.where((pin) {
                                        if (pin.id == _highlightedPinIdForNavigation) return true;
                                        if (pin.hideUntilZoomed) return _currentScale >= _zoomThreshold;
                                        return true;
                                      }).map((pin) {
                                        return _buildMapPin(
                                          pin,
                                          constraints,
                                          _allEvents!,
                                          _allPins!,
                                        );
                                      }).toList(),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        if (_showTutorialOverlay)
          MapTutorialOverlay(
            onDismiss: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('has_shown_map_tutorial', true);
              if (mounted) {
                setState(() {
                  _showTutorialOverlay = false;
                });
              }
            },
          ),
      ],
    );
  }
}

enum MapFilterType { event, service }

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

  static const double referenceScreenWidth =
      412.0; // 開発時に使っていたスマホの横幅をピンのサイズを正規化するための基準値にしている

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
    final double currentScreenWidth = MediaQuery.of(context).size.width;
    final double scaleFactor = currentScreenWidth / referenceScreenWidth;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final highlightColor = widget.isBlinking
            ? Color.lerp(
                Colors.orangeAccent,
                Colors.pinkAccent,
                _animationController.value,
              )!
            : (widget.isHighlighted
                  ? Colors.orangeAccent
                  : Colors.grey.shade400);

        BoxShadow? glowShadow;
        if (widget.isBlinking) {
          final spread = 2.0 + (_animationController.value * 5.0);
          glowShadow = BoxShadow(
            color: highlightColor.withAlpha(179),
            blurRadius: 8.0,
            spreadRadius: spread,
          );
        } else if (widget.isHighlighted) {
          glowShadow = const BoxShadow(
            color: Colors.orangeAccent,
            blurRadius: 8.0,
            spreadRadius: 2.0,
          );
        }

        if (widget.pin.visualStyle == PinVisualStyle.marker) {
          final markerColor = widget.isHighlighted || widget.isBlinking
              ? highlightColor
              : Colors.red;

          final double size = (widget.pin.markerSize ?? 40.0) * scaleFactor;

          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [if (glowShadow != null) glowShadow],
            ),
            child: Icon(
              Icons.location_pin,
              color: markerColor,
              size: size,
              shadows: const [
                Shadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          );
        } else {
          IconData? serviceIcon;
          if (widget.pin.type != PinType.building &&
              widget.pin.type != PinType.location) {
            switch (widget.pin.type) {
              case PinType.restroom:
                serviceIcon = Icons.wc;
                break;
              case PinType.vendingMachine:
                serviceIcon = Icons.local_drink;
                break;
              case PinType.bikeParking:
                serviceIcon = Icons.pedal_bike;
                break;
              case PinType.smokingArea:
                serviceIcon = Icons.smoking_rooms_rounded;
                break;
              case PinType.recyclingStation:
                serviceIcon = Icons.delete;
                break;
              default:
                serviceIcon = Icons.info;
            }
          }

          final scaledFontSize = (widget.pin.fontSize ?? 10) * scaleFactor;
          final scaledIconSize = (widget.pin.iconSize ?? 20) * scaleFactor;
          final scaledPadding =
              (widget.pin.padding ??
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0)) *
              scaleFactor;

          return Container(
            width: widget.width,
            height: widget.height,
            padding: scaledPadding,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.0 * scaleFactor),
              border: Border.all(color: highlightColor, width: 1.5),
              boxShadow: [
                const BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
                if (glowShadow != null) glowShadow,
              ],
            ),
            child: serviceIcon != null
                ? Icon(
                    serviceIcon,
                    color: AppColors.primary,
                    size: scaledIconSize,
                  )
                : Text(
                    widget.pin.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: scaledFontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
          );
        }
      },
    );
  }
}
