import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'announcement_detail_screen.dart';
import '../services/data_service.dart';

class AnnouncementScreen extends StatefulWidget {
  const AnnouncementScreen({super.key});

  @override
  State<AnnouncementScreen> createState() => _AnnouncementScreenState();
}

class _AnnouncementScreenState extends State<AnnouncementScreen> {
  final Set<String> _readAnnouncementIds = {};

  final DataService _dataService = DataService.instance;

  @override
  void initState() {
    super.initState();

    _loadReadStatus();
  }

  Future<void> _loadReadStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final readIds = prefs.getStringList('read_announcement_ids');
    if (readIds != null) {
      setState(() {
        _readAnnouncementIds.addAll(readIds);
      });
    }
  }

  Future<void> _saveReadStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'read_announcement_ids',
      _readAnnouncementIds.toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('M/d HH:mm');
    final sortedAnnouncements = [..._dataService.announcements]
      ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));

    return Scaffold(
      appBar: AppBar(title: const Text('お知らせ')),

      body: sortedAnnouncements.isEmpty
          ? const Center(child: Text('表示できるお知らせがありません'),)
          : ListView.builder(
        itemCount: sortedAnnouncements.length,
        itemBuilder: (context, index) {
          final announcement = sortedAnnouncements[index];
          final bool isRead = _readAnnouncementIds.contains(announcement.id);

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: ListTile(
              leading: isRead
                  ? const SizedBox(width: 24)
                  : const Icon(Icons.circle, color: Colors.blue, size: 12),
              title: Text(
                announcement.title,
                style: TextStyle(
                  fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                ),
              ),
              subtitle: Text(formatter.format(announcement.publishedAt)),
              onTap: () {
                if (!isRead) {
                  setState(() {
                    _readAnnouncementIds.add(announcement.id);
                  });
                  _saveReadStatus();
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AnnouncementDetailScreen(announcement: announcement),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
