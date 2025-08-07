import 'package:flutter/material.dart';
import '../models/event_item.dart';
import '../screens/event_detail_screen.dart';

class EventCard extends StatelessWidget {
  final EventItem event;
  final Set<String> favoriteEventIds;
  final Function(String) onToggleFavorite;
  final Function(String) onNavigateToMap;

  const EventCard({
    super.key,
    required this.event,
    required this.favoriteEventIds,
    required this.onToggleFavorite,
    required this.onNavigateToMap,
  });

  // タグの見た目を作るヘルパーウィジェット
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

  @override
  Widget build(BuildContext context) {
    final bool isFavorited = favoriteEventIds.contains(event.id);
    final allTags = [
      ...event.categories.map((c) => {'text': c.name, 'color': Colors.blue}),
      {'text': event.area.name, 'color': Colors.orange},
      {'text': event.date.name, 'color': Colors.green},
    ];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: event.disableDetailsLink
            ? null
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EventDetailScreen(
                      event: event,
                      favoriteEventIds: favoriteEventIds,
                      onToggleFavorite: onToggleFavorite,
                      onNavigateToMap: onNavigateToMap,
                    ),
                  ),
                );
              },
        child: SizedBox(
          height: 120,
          child: Row(
            children: [
              AspectRatio(
                aspectRatio: 1 / 1,
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
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              event.title,
                              style: const TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            padding: const EdgeInsets.only(left: 8.0),
                            constraints: const BoxConstraints(),
                            icon: Icon(
                              isFavorited
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isFavorited ? Colors.red : Colors.grey,
                            ),
                            onPressed: () {
                              onToggleFavorite(event.id);
                            },
                          ),
                        ],
                      ),
                      Text(
                        event.groupName,
                        style: TextStyle(
                          fontSize: 12.0,
                          color: Colors.grey[700],
                        ),
                      ),
                      const Spacer(),

                      // 【変更点】タグ表示エリアをLayoutBuilderで囲む
                      LayoutBuilder(
                        builder: (context, constraints) {
                          var tagWidgets = <Widget>[];
                          double currentWidth = 0;

                          // "+n"タグのおおよその幅を確保
                          final plusNTagsWidth = 40.0;

                          for (var tagData in allTags) {
                            final tag = _buildTag(
                              tagData['text'] as String,
                              tagData['color'] as Color,
                            );

                            // 各タグの幅を、TextPainterを使って事前に計測
                            final painter = TextPainter(
                              text: TextSpan(
                                text: tagData['text'] as String,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                              textDirection: TextDirection.ltr,
                            )..layout();

                            // padding(6*2=12)とmargin(6)を加味したおおよその幅
                            final tagWidth = painter.width + 12 + 6;

                            if (currentWidth + tagWidth <
                                constraints.maxWidth - plusNTagsWidth) {
                              tagWidgets.add(
                                Padding(
                                  padding: const EdgeInsets.only(right: 6.0),
                                  child: tag,
                                ),
                              );
                              currentWidth += tagWidth;
                            } else {
                              break;
                            }
                          }

                          final hiddenCount =
                              allTags.length - tagWidgets.length;

                          return Row(
                            children: [
                              ...tagWidgets,
                              if (hiddenCount > 0)
                                _buildTag('+$hiddenCount', Colors.grey),
                            ],
                          );
                        },
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
