import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/dummy_events.dart';
import '../models/event_item.dart';
import 'event_detail_screen.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  FestivalDay _selectedDay = FestivalDay.dayOne;
  final double _hourHeight = 120.0; // 1時間あたりの高さを定義
  final double _leftColumnWidth = 50.0; // 左の時間軸の幅を定義

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('タイムテーブル'), elevation: 1.0),
      body: Column(
        children: [
          // --- 1. 日付切り替えボタン ---
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

          // --- 2. ステージ名のヘッダー ---
          SizedBox(
            height: 40,
            // 【変更点】Rowを直接配置し、各セルに色を指定
            child: Row(
              children: [
                SizedBox(width: _leftColumnWidth), // 時間軸の幅
                _buildHeaderCell('体育館ステージ', Colors.orange.shade400),
                _buildHeaderCell('31Aステージ', Colors.green.shade400),
                _buildHeaderCell('32Aステージ', Colors.blue.shade400),
              ],
            ),
          ),

          // --- 3. タイムテーブル本体 ---
          Expanded(
            child: SingleChildScrollView(
              child: Stack(
                children: [
                  // 背景のグリッド線と時間軸
                  _buildGridAndTimeAxis(),
                  // 企画カード
                  Row(
                    children: [
                      SizedBox(width: _leftColumnWidth), // 時間軸の幅だけスペース
                      _buildStageColumn('体育館ステージ'),
                      _buildStageColumn('31Aステージ'),
                      _buildStageColumn('32Aステージ'),
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

  // --- 以下、UIを生成するためのヘルパーメソッド ---

  // ステージ名ヘッダーのセル
  Widget _buildHeaderCell(String title, Color backgroundColor) {
    return Expanded(
      child: Container(
        // 受け取った色を背景色として設定
        color: backgroundColor,
        child: Center(
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white, // 文字色を白にすると見やすい
            ),
          ),
        ),
      ),
    );
  }

  // 背景グリッドと時間軸を生成
  Widget _buildGridAndTimeAxis() {
    final List<Widget> children = [];
    // 10時から20時までループ
    for (int hour = 10; hour < 21; hour++) {
      final topPosition = (hour - 10) * _hourHeight;
      // 時間軸 (10:00, 11:00...)
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
          child: Container(height: 1, color: Colors.grey[400]),
        ),
      );
      // 30分ごとの破線 (20時は除く)
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
                    height: 1,
                    color: index % 2 == 0
                        ? Colors.grey[300]
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
      height: (21 - 10) * _hourHeight, // 全体の高さを定義
      child: Stack(children: children),
    );
  }

  // 各ステージの列（企画カード）を生成
  Widget _buildStageColumn(String locationName) {
    // 選択された日付と場所に合致する企画だけをフィルタリング
    final eventsForStage = dummyEvents.where((event) {
      final isSameDay =
          event.date == _selectedDay || event.date == FestivalDay.both;
      // 【変更点②】event.areaではなく、event.locationをチェックする
      final isSameLocation = event.location == locationName;
      final isTimed = event.startTime != null;
      return isSameDay && isSameLocation && isTimed;
    }).toList();

    return Expanded(
      child: SizedBox(
        height: (21 - 10) * _hourHeight,
        child: Stack(
          children: eventsForStage.map((event) {
            final start = event.startTime!;
            final end = event.endTime!;
            final topPosition =
                ((start.hour - 10) * 60 + start.minute) / 60.0 * _hourHeight;
            final cardHeight =
                end.difference(start).inMinutes / 60.0 * _hourHeight;

            return Positioned(
              top: topPosition + (_hourHeight / 2),
              left: 2,
              right: 2,
              height: cardHeight,
              child: _TimetableEventCard(event: event),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// --- タイムテーブル専用の企画カードウィジェット ---
class _TimetableEventCard extends StatelessWidget {
  final EventItem event;
  // TODO: お気に入り機能の連携
  const _TimetableEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('HH:mm');
    return Card(
      color: Colors.yellow[200], // 参考画像に合わせた色
      elevation: 2.0,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventDetailScreen(event: event),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ⑦ 開始・終了時刻
              Text(
                '${formatter.format(event.startTime!)} - ${formatter.format(event.endTime!)}',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // ⑤ 企画タイトル
              Text(
                event.title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // ⑤ 団体名（省略可能）
              if (event.groupName.isNotEmpty)
                Text(event.groupName, style: const TextStyle(fontSize: 10)),
              const Spacer(),
              // ⑤ お気に入りボタン（省略可能）
              // Align(alignment: Alignment.bottomRight, child: Icon(Icons.favorite_border, size: 14)),
            ],
          ),
        ),
      ),
    );
  }
}
