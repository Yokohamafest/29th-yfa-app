import 'package:flutter/material.dart';
import '../models/event_item.dart';

// 一つの企画情報をカード形式で表示するための、再利用可能なウィジェット
class EventCard extends StatelessWidget {
  final EventItem event;

  const EventCard({
    super.key,
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
    // Cardウィジェットでカードの見た目を作る
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      clipBehavior: Clip.antiAlias, // 角丸に沿って画像もクリッピングする
      child: InkWell(
        onTap: () {
          // TODO: ここに企画詳細ページへの遷移処理を後で追加
          print('${event.title}がタップされました');
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // サムネイル画像
            // 画像の縦横比を16:9に固定
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.asset(
                event.imagePath,
                fit: BoxFit.cover,
                // 画像が存在しない場合にエラーの代わりに表示するウィジェット
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.image_not_supported, color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
            // 画像下の文字情報エリア
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // カテゴリと場所
                  Text(
                    '${event.category.name} | ${event.area} ${event.location}',
                    style: TextStyle(
                      fontSize: 12.0,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  // 企画タイトル
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4.0),
                  // 団体名
                  Text(
                    event.groupName,
                    style: TextStyle(
                      fontSize: 14.0,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}