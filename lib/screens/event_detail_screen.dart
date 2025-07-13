import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // 日付フォーマットのためにインポート
import '../models/event_item.dart';

class EventDetailScreen extends StatelessWidget {
  // 表示するべき企画情報を、前の画面から受け取るための変数
  final EventItem event;

  const EventDetailScreen({super.key, required this.event});

  // タグを生成するためのヘルパーメソッド（event_card.dartからコピー）
  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
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

  @override
  Widget build(BuildContext context) {
    // 時刻を「13:00」のような形式に変換するフォーマッター
    final timeFormatter = DateFormat('HH:mm');
    final dayFormatter = DateFormat('M/d (E)', 'ja_JP');

    return Scaffold(
      appBar: AppBar(
        title: Text(event.title), // AppBarのタイトルに企画名を表示
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. メイン画像
            Image.asset(
              event.imagePath,
              width: double.infinity, // 横幅いっぱいに表示
              height: 250,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 250,
                  color: Colors.grey[300],
                  child: const Center(child: Icon(Icons.image_not_supported)),
                );
              },
            ),

            // 2. 文字情報エリア
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 企画タイトル
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  // 団体名
                  Text(
                    event.groupName,
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 16.0),

                  // タグ表示
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: [
                      _buildTag(event.category.name, Colors.blue),
                      _buildTag(event.area.name, Colors.orange),
                      _buildTag(event.date.name, Colors.green),
                    ],
                  ),
                  const Divider(height: 32.0),

                  // 開催日時
                  _buildInfoRow(
                    icon: Icons.schedule,
                    title: '開催日時',
                    // timeSlotsが空なら「常時開催」、そうでなければリストを表示
                    child: event.timeSlots.isEmpty
                        ? const Text('常時開催', style: TextStyle(fontSize: 16))
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: event.timeSlots.map((slot) {
                              return Text(
                                '${dayFormatter.format(slot.startTime)} ${timeFormatter.format(slot.startTime)} - ${timeFormatter.format(slot.endTime)}',
                                style: const TextStyle(fontSize: 16),
                              );
                            }).toList(),
                          ),
                  ),
                  const SizedBox(height: 16.0),

                  // 開催場所
                  _buildInfoRow(
                    icon: Icons.location_on,
                    title: '開催場所',
                    child: Text('${event.area.name} / ${event.location}'),
                    // TODO: マップへの遷移機能を後で追加
                    // trailing: OutlinedButton(onPressed: () {}, child: const Text('マップで見る')),
                  ),
                  const Divider(height: 32.0),

                  // 企画説明
                  Text(
                    '企画説明',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    event.description,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // アイコンとタイトル、内容を横に並べるためのヘルパーメソッド
  // アイコンとタイトル、内容を横に並べるためのヘルパーメソッド
  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    Widget? child, // 【変更点①】content: String から child: Widget? に変更
    Widget? trailing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(width: 12.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4.0),
              // 【変更点②】受け取ったchildウィジェットがnullでなければ表示
              if (child != null) child,
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }
}
