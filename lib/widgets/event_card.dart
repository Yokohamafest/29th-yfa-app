import 'package:flutter/material.dart';
import '../models/event_item.dart';

// 一つの企画情報をカード形式で表示するための、再利用可能なウィジェット
class EventCard extends StatelessWidget {
  final EventItem event;

  const EventCard({super.key, required this.event});

  // タグを生成するためのヘルパーメソッド
  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: color.withAlpha(51), // 少し薄い背景色
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
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // TODO: ここに企画詳細ページへの遷移処理を後で追加します
          print('${event.title}がタップされました');
        },
        child: SizedBox(
          height: 120, // カードの高さを指定
          child: Row(
            children: [
              // --- 左側：正方形の画像 ---
              AspectRatio(
                aspectRatio: 1 / 1, // 縦横比を1:1
                child: Image.asset(
                  event.imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  },
                ),
              ),

              // --- 右側：文字情報エリア ---
              // Expandedで残りのスペースをすべて文字エリアに使う
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 企画タイトル
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // 団体名
                      Text(
                        event.groupName,
                        style: TextStyle(
                          fontSize: 12.0,
                          color: Colors.grey[700],
                        ),
                      ),
                      const Spacer(), // 残りのスペースを埋めるスペーサー
                      // タグ表示エリア
                      Wrap(
                        spacing: 6.0, // タグ間の横スペース
                        runSpacing: 4.0, // タグ間の縦スペース
                        children: [
                          _buildTag(event.category.name, Colors.blue),
                          _buildTag(event.area.name, Colors.orange),
                          _buildTag(event.date.name, Colors.green),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
