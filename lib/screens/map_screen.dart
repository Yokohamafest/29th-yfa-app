import 'package:flutter/foundation.dart';
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

enum MapFilterType { event, service }

class _MapScreenState extends State<MapScreen> {
  // --- 状態を管理する変数 ---
  MapInfo _currentMap = allMaps.first;
  // InteractiveViewerをプログラムから操作するためのコントローラー
  final TransformationController _transformationController =
      TransformationController();

  Set<String> _highlightedPinIds = {};
  MapFilterType _currentFilterType = MapFilterType.event;
  // イベントフィルター
  final Set<FestivalDay> _selectedDays = {};
  final Set<EventCategory> _selectedCategories = {};
  bool _filterFavorites = false;
  // サービスフィルター
  final Set<PinType> _selectedServiceTypes = {};
  final Map<String, MapType> _buildingPinToFloorMap = {
    'pin_b2': MapType.building2F1, // 2号館のピンID -> 2号館1階マップ
    'pin_b3': MapType.building3F1, // 3号館のピンID -> 3号館1階マップ
    'pin_b4': MapType.building4F1F2, // 4号館のピンID -> 4号館1,2階マップ
    // 体育館（5号館）はフロアマップがないので、ここには含めない
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _jumpToEventLocation(widget.highlightedEventId);
    });
  }

  void _jumpToEventLocation(String? eventId) {
    if (eventId == null) return;

    // 渡されたeventIdを持つピンを探す
    // ignore: unnecessary_nullable_for_final_variable_declarations
    final MapPin? targetPin = allPins.firstWhere(
      (pin) => pin.eventIds.contains(eventId),
    );
    if (targetPin == null) return;

    // そのピンが所属するマップを探す
    final MapInfo targetMap = allMaps.firstWhere(
      (map) => map.id == targetPin.mapId,
    );

    // 画面の中心座標を取得
    final screenCenter = Offset(
      MediaQuery.of(context).size.width / 2,
      MediaQuery.of(context).size.height / 2,
    );
    final zoomLevel = 3.0; // 3倍にズーム

    // ピンが画面の中心に来るように、表示を移動・ズーム
    final matrix = Matrix4.identity()
      ..translate(screenCenter.dx, screenCenter.dy)
      ..scale(zoomLevel)
      ..translate(-targetPin.position.dx, -targetPin.position.dy);

    _transformationController.value = matrix;

    // 状態を更新して、正しいマップとハイライトを表示
    setState(() {
      _currentMap = targetMap;
      _highlightedPinIds = {targetPin.id};
    });
  }

  // フィルターが適用されたときに、ハイライトするピンを更新する関数
  void _applyFilters() {
    final newHighlightedPinIds = <String>{};
    bool isFilterActive = false; // いずれかのフィルターが有効かどうかのフラグ

    if (_currentFilterType == MapFilterType.event) {
      isFilterActive =
          _selectedDays.isNotEmpty ||
          _selectedCategories.isNotEmpty ||
          _filterFavorites;
      if (isFilterActive) {
        final filteredEvents = dummyEvents
            .where((event) {
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
                  !_selectedCategories.contains(event.category)) {
                return false;
              }
              if (_filterFavorites &&
                  !widget.favoriteEventIds.contains(event.id)) {
                return false;
              }
              return true;
            })
            .map((e) => e.id)
            .toSet();

        for (final pin in allPins) {
          if (pin.eventIds.any((eventId) => filteredEvents.contains(eventId))) {
            newHighlightedPinIds.add(pin.id);
          }
        }
      }
    } else {
      // --- サービスによる絞り込み ---
      isFilterActive = _selectedServiceTypes.isNotEmpty;
      if (isFilterActive) {
        for (final pin in allPins) {
          // 選択されたサービスピンを見つけたら
          if (_selectedServiceTypes.contains(pin.type)) {
            // そのサービスピン自身をハイライト対象に追加
            newHighlightedPinIds.add(pin.id);

            // もし親となる建物IDがあれば、その建物ピンもハイライト対象に追加
            if (pin.parentBuildingId != null) {
              newHighlightedPinIds.add(pin.parentBuildingId!);
            }
          }
        }
      }
    }

    setState(() {
      // フィルターがアクティブでなければ、ハイライトを空にする
      _highlightedPinIds = isFilterActive ? newHighlightedPinIds : {};
    });
  }

  // --- UIを生成するヘルパーメソッド群 ---

  // 企画のタグを生成
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

  // ピンウィジェットを生成
  Widget _buildMapPin(MapPin pin) {
    final bool isHighlighted = _highlightedPinIds.contains(pin.id);
    IconData iconData;
    Color iconColor;

    switch (pin.type) {
      case PinType.event:
      case PinType.building:
        iconData = Icons.place;
        iconColor = Colors.red;
        break;
      case PinType.restroom:
        iconData = Icons.wc;
        iconColor = Colors.blue;
        break;
      // ... 他のピンタイプ ...
      default:
        iconData = Icons.circle;
        iconColor = Colors.grey;
    }

    return Positioned(
      left: pin.position.dx - 18, // アイコンの中心が座標に来るように調整
      top: pin.position.dy - 36,
      child: InkWell(
        onTap: () {
          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (context) {
              // --- モーダルの中身をここから構築 ---

              // このピンに関連する企画のリストを取得
              final attachedEvents = dummyEvents
                  .where((event) => pin.eventIds.contains(event.id))
                  .toList();

              // この建物に含まれるサービスピンのリストを取得
              final servicesInBuilding = allPins
                  .where((servicePin) => servicePin.parentBuildingId == pin.id)
                  .toList();

              final bool isEventFilterActive =
                  _currentFilterType == MapFilterType.event &&
                  (_selectedDays.isNotEmpty ||
                      _selectedCategories.isNotEmpty ||
                      _filterFavorites);

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. ピンのタイトル
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // タイトル（長くなる可能性があるのでExpandedで囲む）
                        Expanded(
                          child: Text(
                            pin.title,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // フロアマップへの遷移ボタン
                        if (pin.type == PinType.building &&
                            _buildingPinToFloorMap.containsKey(pin.id))
                          ElevatedButton(
                            child: Text("${pin.title}フロアマップ"),
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

                    // --- 2. 館内設備の表示 (建物ピンの場合) ---
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
                      const SizedBox(height: 24.0), // 企画一覧との間にスペース
                    ],

                    // --- 3. 企画一覧の表示 (企画があるピンの場合) ---
                    if (attachedEvents.isNotEmpty) ...[
                      const Text(
                        '開催企画', // 見出しを追加
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Column(
                        children: attachedEvents.map((event) {
                          bool shouldHighlight = false;
                          if (isEventFilterActive) {
                            bool matches = true;
                            // 日付フィルター
                            if (_selectedDays.isNotEmpty) {
                              final isDayMatch =
                                  (_selectedDays.contains(FestivalDay.dayOne) &&
                                      (event.date == FestivalDay.dayOne ||
                                          event.date == FestivalDay.both)) ||
                                  (_selectedDays.contains(FestivalDay.dayTwo) &&
                                      (event.date == FestivalDay.dayTwo ||
                                          event.date == FestivalDay.both));
                              if (!isDayMatch) matches = false;
                            }
                            // カテゴリフィルター
                            if (matches &&
                                _selectedCategories.isNotEmpty &&
                                !_selectedCategories.contains(event.category)) {
                              matches = false;
                            }
                            // お気に入りフィルター
                            if (matches &&
                                _filterFavorites &&
                                !widget.favoriteEventIds.contains(event.id)) {
                              matches = false;
                            }
                            shouldHighlight = matches;
                          }

                          // 各企画をContainerで囲み、背景色とタップ機能を設定
                          return Container(
                            margin: const EdgeInsets.only(
                              bottom: 8.0,
                            ), // カード間の余白
                            decoration: BoxDecoration(
                              color: shouldHighlight
                                  ? Colors.orange.shade100
                                  : const Color.fromARGB(
                                      22,
                                      128,
                                      127,
                                      127,
                                    ), // 薄いグレーの背景
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).pop(); // モーダルを閉じる
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EventDetailScreen(
                                      event: event,
                                      favoriteEventIds: widget.favoriteEventIds,
                                      onToggleFavorite: widget.onToggleFavorite,
                                      onNavigateToMap: widget.onNavigateToMap,
                                    ),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12.0,
                                  horizontal: 16.0,
                                ),
                                // Rowを使って、コンテンツと「>」アイコンを横に並べる
                                child: Row(
                                  children: [
                                    // 左側のコンテンツ部分（Expandedで幅いっぱいまで広げる）
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
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          const SizedBox(height: 4.0),
                                          Wrap(
                                            spacing: 6.0,
                                            runSpacing: 4.0,
                                            children: [
                                              _buildTag(
                                                event.category.name,
                                                Colors.blue,
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
                                    // 右端の「>」アイコン
                                    Icon(
                                      Icons.chevron_right,
                                      color: Colors.grey[600],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],

                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          );
        },
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isHighlighted
                    ? Colors.yellow.withAlpha(204)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: iconColor, size: 36),
            ),
            Text(
              pin.title,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 左上のマップ切り替えUI
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
                  setState(
                    () =>
                        _currentMap = allMaps.firstWhere((m) => m.id == newMap),
                  );
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
                onPressed: () => setState(() => _currentMap = allMaps.first),
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
            // イベント / サービス の切り替えボタン
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
                  ? _buildEventFilterOptions() // イベント絞り込みUI
                  : _buildServiceFilterOptions(), // サービス絞り込みUI
            ),
          ],
        ),
      ),
    );
  }

  // イベント絞り込みのUI
  Widget _buildEventFilterOptions() {
    return ListView(
      padding: const EdgeInsets.all(8.0),
      children: [
        // --- 開催日のFilterChip ---
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
              // 【修正点】ここで日本語のnameゲッターを正しく呼び出す
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

        // --- カテゴリのFilterChip ---
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
              // 【修正点】ここでも日本語のnameゲッターを正しく呼び出す
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

        // --- お気に入りスイッチ ---
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

  // サービス絞り込みのUI
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
          title: Text(type.displayName), // 日本語名に変換
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
    // 現在のマップに所属するピンだけを取得
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
      endDrawer: _buildFilterDrawer(), // Drawerを追加
      body: Stack(
        children: [
          InteractiveViewer(
            transformationController: _transformationController,
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

          // マップ切り替えUI
          _buildMapSwitcher(),
        ],
      ),
    );
  }
}

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
