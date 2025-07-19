import 'package:flutter/material.dart';
import '../data/dummy_map_data.dart';
import '../models/map_models.dart';
import '../data/dummy_events.dart';

// ... 他の必要なファイルをインポート ...

class MapScreen extends StatefulWidget {
  final String? highlightedEventId;
  const MapScreen({super.key, this.highlightedEventId});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // --- 状態を管理する変数 ---
  MapInfo _currentMap = allMaps.first;
  final Set<PinType> _serviceFilter = {}; // 選択されたサービスフィルター
  final Set<String> _highlightedPinIds = {}; // ハイライトすべきピンのIDリスト
  // InteractiveViewerをプログラムから操作するためのコントローラー
  final TransformationController _transformationController =
      TransformationController();

  @override
  void initState() {
    super.initState();
    // TODO: 詳細画面から渡されたhighlightedEventIdを使って、初期表示を制御する
  }

  // フィルターが適用されたときに、ハイライトするピンを更新する関数
  void _applyFilters() {
    _highlightedPinIds.clear();
    // TODO: 選択されたフィルターに応じて_highlightedPinIdsを更新するロジック
    setState(() {});
  }

  // --- UIを生成するヘルパーメソッド群 ---

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

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. ピンのタイトル
                    Text(
                      pin.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(height: 24),

                    // 2. 企画一覧の表示 (企画があるピンの場合)
                    if (attachedEvents.isNotEmpty)
                      ...attachedEvents.map(
                        (event) => ListTile(
                          title: Text(event.title),
                          subtitle: Text(event.groupName),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            /* TODO: 企画詳細へ遷移 */
                          },
                        ),
                      ),

                    // 3. 建物内のサービスピン一覧の表示 (建物ピンの場合)
                    if (pin.type == PinType.building &&
                        servicesInBuilding.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          '館内設備',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Wrap(
                        spacing: 16.0,
                        children: servicesInBuilding.map((servicePin) {
                          // TODO: ここで各サービスピンのアイコンと名前を表示
                          return Chip(
                            avatar: Icon(Icons.wc),
                            label: Text(servicePin.title),
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

  // 右上の絞り込みボタン
  Widget _buildFilterButton() {
    // TODO: 絞り込みDrawerを表示するロジックを実装
    return IconButton(onPressed: () {}, icon: const Icon(Icons.filter_list));
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
            if (_currentMap.id != MapType.campus)
              TextButton(
                onPressed: () => setState(() => _currentMap = allMaps.first),
                child: const Text('全体マップへ'),
              ),
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
          ],
        ),
      ),
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
        title: Text(_currentMap.name),
        actions: [_buildFilterButton()],
      ),
      body: Stack(
        children: [
          InteractiveViewer(
            transformationController: _transformationController,
            maxScale: 5.0,
            child: Stack(
              children: [
                // マップ画像
                Image.asset(_currentMap.imagePath),
                // ピン
                ...currentPins.map((pin) => _buildMapPin(pin)),
              ],
            ),
          ),
          // マップ切り替えUI
          _buildMapSwitcher(),
        ],
      ),
    );
  }
}
