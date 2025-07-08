import 'package:flutter/material.dart';
import '../models/event_item.dart';
import '../screens/event_detail_screen.dart';

// 一つの企画情報をカード形式で表示するための、再利用可能なウィジェット
class EventCard extends StatelessWidget {
  final EventItem event;

  // お気に入り状態を管理する変数
  final Set<String> favoriteEventIds;
  final Function(String) onToggleFavorite;

  const EventCard({
    super.key,
    required this.event,
    required this.favoriteEventIds,
    required this.onToggleFavorite,
  });

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
    final bool isFavorited = favoriteEventIds.contains(event.id);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // Navigator.pushを使って画面遷移を実行
          Navigator.push(
            context,
            MaterialPageRoute(
              // 遷移先の画面としてEventDetailScreenを指定
              // eventプロパティに、このカードが持つ企画情報を渡す
              builder: (context) => EventDetailScreen(event: event),
            ),
          );
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
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 0, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            // 企画タイトル
                            child: Text(
                              event.title,
                              style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // お気に入り登録ボタン
                          IconButton(
                            padding: const EdgeInsets.all(0),
                            constraints: const BoxConstraints(),
                            icon: Icon(
                              isFavorited ? Icons.favorite : Icons.favorite_border,
                              color: isFavorited ? Colors.red : Colors.grey,
                            ),
                            onPressed: () {
                              // ボタンが押されたら、親から渡された関数を呼び出す
                              onToggleFavorite(event.id);
                            },
                          ),
                        ],
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
