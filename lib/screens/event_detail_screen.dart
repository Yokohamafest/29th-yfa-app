import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event_item.dart';
import '../widgets/tag_widget.dart';
import '../models/enum_extensions.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../utils/app_colors.dart';

class EventDetailScreen extends StatefulWidget {
  final EventItem event;
  final Set<String> favoriteEventIds;
  final Function(String) onToggleFavorite;
  final Function(String) onNavigateToMap;

  const EventDetailScreen({
    super.key,
    required this.event,
    required this.favoriteEventIds,
    required this.onToggleFavorite,
    required this.onNavigateToMap,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    Widget? child,
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
              if (child != null) child,
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final timeFormatter = DateFormat('HH:mm');
    final dayFormatter = DateFormat('M/d (E)', 'ja_JP');

    final bool isFavorited = widget.favoriteEventIds.contains(widget.event.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event.title),
        actions: [
          IconButton(
            icon: Icon(
              isFavorited ? Icons.favorite : Icons.favorite_border,
              color: isFavorited ? Colors.red : null,
            ),
            tooltip: 'お気に入り',
            onPressed: () {
              widget.onToggleFavorite(widget.event.id);
              setState(() {});
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1 / 1,
              child: CachedNetworkImage(
                imageUrl: widget.event.imagePath,
                fit: BoxFit.cover,
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: AppColors.tertiary.withAlpha(150),
                  child: Container(color: Colors.white),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.image_not_supported, color: Colors.grey),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.event.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.event.groupName,
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 16.0),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: [
                      TagWidget(
                        text: widget.event.date.name,
                        color: Colors.green,
                      ),
                      ...widget.event.areas.map(
                        (area) =>
                            TagWidget(text: area.name, color: Colors.orange),
                      ),
                      ...widget.event.categories.map(
                        (category) =>
                            TagWidget(text: category.name, color: Colors.blue),
                      ),
                    ],
                  ),
                  const Divider(height: 32.0),
                  _buildInfoRow(
                    icon: Icons.schedule,
                    title: '開催日時',
                    child: Builder(
                      builder: (context) {
                        if (widget.event.timeSlots == null) {
                          return const Text(
                            '時間未定',
                            style: TextStyle(fontSize: 16),
                          );
                        }
                        if (widget.event.timeSlots!.isEmpty) {
                          return const Text(
                            '終日開催',
                            style: TextStyle(fontSize: 16),
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: widget.event.timeSlots!.map((slot) {
                            return Text(
                              '${dayFormatter.format(slot.startTime.toLocal())} ${timeFormatter.format(slot.startTime.toLocal())} - ${timeFormatter.format(slot.endTime.toLocal())}',
                              style: const TextStyle(fontSize: 16),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  _buildInfoRow(
                    icon: Icons.location_on,
                    title: '開催場所',
                    child: Text(
                      '${widget.event.areas.map((a) => a.name).join('、')} / ${widget.event.locations.join(' 、')}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    trailing: OutlinedButton(
                      child: const Text('マップで見る'),
                      onPressed: () {
                        widget.onNavigateToMap(widget.event.id);
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  const Divider(height: 32.0),
                  MarkdownBody(
                    data: widget.event.description,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(fontSize: 16, height: 1.7),
                    ),
                    onTapLink: (text, href, title) {
                      if (href != null) {
                        launchUrl(Uri.parse(href));
                      }
                    },
                  ),
                  const SizedBox(height: 40.0),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
