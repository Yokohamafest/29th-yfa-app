import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/dummy_events.dart';
import '../models/event_item.dart';
import 'event_detail_screen.dart';
import 'dart:math' as math;

class TimetableScreen extends StatefulWidget {
  // おkに入りの情報を受け取る変数
  final Set<String> favoriteEventIds;
  final Function(String) onToggleFavorite;

  const TimetableScreen({super.key, required this.favoriteEventIds,
    required this.onToggleFavorite,
});

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
          child: Container(
            height: 1.5,
            color: const Color.fromARGB(255, 70, 70, 70),
          ),
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
      height: (21 - 10) * _hourHeight, // 全体の高さを定義
      child: Stack(children: children),
    );
  }

  // 各ステージの列（企画カード）を生成
  Widget _buildStageColumn(String locationName, Color backgroundColor) {
    final eventsForStage = dummyEvents.where((event) {
      final isSameLocation = event.location == locationName;
      final isTimed = event.timeSlots.isNotEmpty;
      return isSameLocation && isTimed;
    }).toList();

    final List<Widget> cards = [];
    for (final event in eventsForStage) {
      for (final timeSlot in event.timeSlots) {
        // 表示中の日付と、タイムスロットの日付が一致するかチェック
        // （両日開催の企画が、両方の日に表示されるようにするため）
        if (timeSlot.startTime.day !=
            (_selectedDay == FestivalDay.dayOne ? 14 : 15)) {
          continue; // 日付が違えばスキップ
        }

        final start = timeSlot.startTime;
        final end = timeSlot.endTime;
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
            // 渡すeventオブジェクトは元のままでOK
            child: _TimetableEventCard(
              event: event,
              timeSlot: timeSlot,
              cardHeight: cardHeight,
              cardColor: backgroundColor,
              favoriteEventIds: widget.favoriteEventIds,
              onToggleFavorite: widget.onToggleFavorite,
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
          child: Stack(
            children: cards, // 生成したカードのリストを配置
          ),
        ),
      ),
    );
  }
}

// --- タイムテーブル専用の企画カードウィジェット ---
class _TimetableEventCard extends StatelessWidget {
  final EventItem event;
  final TimeSlot timeSlot;
  final double cardHeight;
  final Color cardColor;
  final Set<String> favoriteEventIds;
  final Function(String) onToggleFavorite;


  const _TimetableEventCard({
    required this.event,
    required this.timeSlot,
    required this.cardHeight,
    required this.cardColor,
    required this.favoriteEventIds,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('HH:mm');

    int titleMaxLines;
    int groupNameMaxLines;

    // まず、カードが極端に短い場合（オーバーフロー対策）
    if (cardHeight < 65) {
      titleMaxLines = 1;
      groupNameMaxLines = 1;
    }
    // カードに十分な高さがある場合は、企画の長さに応じて行数を増やす
    else {
      final durationInMinutes = timeSlot.endTime
          .difference(timeSlot.startTime)
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
                    builder: (context) => EventDetailScreen(event: event, favoriteEventIds: favoriteEventIds,
                      onToggleFavorite: onToggleFavorite,
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
                  //const SizedBox(height: 12),
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
                  '${formatter.format(timeSlot.startTime)} - ${formatter.format(timeSlot.endTime)}',
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
