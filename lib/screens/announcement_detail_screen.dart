import 'package:flutter/material.dart';
import 'package:flutter_app_yfa/utils/app_colors.dart';
import 'package:intl/intl.dart';
import '../models/announcement_item.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

class AnnouncementDetailScreen extends StatelessWidget {
  final AnnouncementItem announcement;

  const AnnouncementDetailScreen({super.key, required this.announcement});

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('M/d(E) HH:mm', 'ja_JP');

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'お知らせ詳細',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: (AppColors.secondary),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              announcement.title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '公開日時: ${formatter.format(announcement.publishedAt)}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const Divider(height: 32.0),
            MarkdownBody(
              data: announcement.content,
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(fontSize: 16, height: 1.7),
              ),
              onTapLink: (text, href, title) {
                if (href != null) {
                  launchUrl(Uri.parse(href));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
