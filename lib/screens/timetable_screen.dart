import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/dummy_events.dart';
import '../models/event_item.dart';
import 'event_detail_screen.dart';
import 'dart:math' as math;

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
          // --- ここからが画面上部に「固定」される部分 ---
          // 1. 日付切り替えボタン
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
          // 2. ステージタイトルヘッダー
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

          // --- 3. タイムテーブル本体（ここから下がスクロールする） ---
          Expanded(
            child: SingleChildScrollView(
              child: Stack(
                children: [
                  _buildGridAndTimeAxis(),
                  Row(
                    children: [
                      SizedBox(width: _leftColumnWidth),
                      // 【変更点④】各列に色を渡し、間に隙間を追加
                      _buildStageColumn('体育館ステージ', Colors.orange.shade400),
                      const SizedBox(width: 3), // 企画列の間の隙間
                      _buildStageColumn('31Aステージ', Colors.green.shade400),
                      const SizedBox(width: 3), // 企画列の間の隙間
                      _buildStageColumn('32Aステージ', Colors.blue.shade400),
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
      child: Column(
        children: [
          // 四角形のヘッダー本体
          Container(
            height: 60, // ヘッダーの高さ
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
  Widget _buildStageColumn(String locationName, Color backgroundColor) {
    final eventsForStage = dummyEvents.where((event) {
      final isSameDay =
          event.date == _selectedDay || event.date == FestivalDay.both;
      final isSameLocation = event.location == locationName;
      final isTimed = event.startTime != null;
      return isSameDay && isSameLocation && isTimed;
    }).toList();

    return Expanded(
      // 【変更点②】SizedBoxをContainerで囲み、背景色を設定
      child: Container(
        // ヘッダーの背景色を少し薄くして使用
        color: backgroundColor.withOpacity(0.1),
        child: SizedBox(
          height: (21 - 10) * _hourHeight,
          child: Stack(
            children: eventsForStage.map((event) {
              final start = event.startTime!;
              final end = event.endTime!;
              final topPosition =
                  ((start.hour - 10) * 60 + start.minute) / 60.0 * _hourHeight;
              // カードの高さ計算（最低の高さを保証）
              final durationHeight =
                  end.difference(start).inMinutes / 60.0 * _hourHeight;
              const double minHeight = 45.0;
              final cardHeight = math.max(durationHeight, minHeight);

              return Positioned(
                top: topPosition + 60,
                // 【変更点③】左右の余白を調整
                left: 0,
                right: 0,
                height: cardHeight,
                child: _TimetableEventCard(event: event),
              );
            }).toList(),
          ),
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
