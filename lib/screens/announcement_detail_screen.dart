import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/announcement_item.dart';

class AnnouncementDetailScreen extends StatelessWidget {
  final AnnouncementItem announcement;

  const AnnouncementDetailScreen({super.key, required this.announcement});

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('M/d(E) HH:mm', 'ja_JP');

    return Scaffold(
      appBar: AppBar(title: const Text('お知らせ詳細')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. タイトル
            Text(
              announcement.title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // 2. 公開日時
            Text(
              '公開日時: ${formatter.format(announcement.publishedAt)}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const Divider(height: 32.0),
            // 3. 本文
            Text(
              announcement.content,
              style: const TextStyle(fontSize: 16, height: 1.7),
            ),
          ],
        ),
      ),
    );
  }
}
