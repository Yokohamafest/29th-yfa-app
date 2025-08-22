import 'package:flutter/material.dart';
import '../models/event_item.dart';
import '../screens/event_detail_screen.dart';
import 'tag_widget.dart';
import '../models/enum_extensions.dart';
import 'package:cached_network_image/cached_network_image.dart';

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

  @override
  Widget build(BuildContext context) {
    final bool isFavorited = favoriteEventIds.contains(event.id);
    final allTags = [
      {'text': event.date.name, 'color': Colors.green},
      {'text': event.area.name, 'color': Colors.orange},
      ...event.categories.map((c) => {'text': c.name, 'color': Colors.blue}),
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
                child: CachedNetworkImage(
                  imageUrl: event.imagePath,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[300],
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                      ),
                    ),
                  ),
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

                      LayoutBuilder(
                        builder: (context, constraints) {
                          var tagWidgets = <Widget>[];
                          double currentWidth = 0;

                          final plusNTagsWidth = 40.0;

                          for (var tagData in allTags) {
                            final tag = TagWidget(
                              text:tagData['text'] as String,
                              color:tagData['color'] as Color,
                            );

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
                                TagWidget(text:'+$hiddenCount', color:Colors.grey),
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
