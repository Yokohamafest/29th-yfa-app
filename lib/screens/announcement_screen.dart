import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart'; // SharedPreferencesをインポート
import '../data/dummy_announcements.dart';
import '../models/announcement_item.dart';
import 'announcement_detail_screen.dart';

class AnnouncementScreen extends StatefulWidget {
  const AnnouncementScreen({super.key});

  @override
  State<AnnouncementScreen> createState() => _AnnouncementScreenState();
}

class _AnnouncementScreenState extends State<AnnouncementScreen> {
  // お知らせのリストは変更なし
  late final List<AnnouncementItem> _announcements;
  
  // 【変更点①】既読にしたお知らせのIDを記憶するためのSetを追加
  final Set<String> _readAnnouncementIds = {};

  @override
  void initState() {
    super.initState();
    _announcements = List.of(dummyAnnouncements)
      ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    
    // 【変更点②】アプリ起動時に、保存された既読状態を読み込む
    _loadReadStatus();
  }

  // スマホのストレージから既読IDリストを読み込む関数
  Future<void> _loadReadStatus() async {
    final prefs = await SharedPreferences.getInstance();
    // 'read_announcement_ids' というキーで保存されたリストを読み込む
    final readIds = prefs.getStringList('read_announcement_ids');
    if (readIds != null) {
      setState(() {
        _readAnnouncementIds.addAll(readIds);
      });
    }
  }
  
  // スマホのストレージに既読IDリストを保存する関数
  Future<void> _saveReadStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('read_announcement_ids', _readAnnouncementIds.toList());
  }

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('M/d HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('お知らせ'),
      ),
      body: ListView.builder(
        itemCount: _announcements.length,
        itemBuilder: (context, index) {
          final announcement = _announcements[index];
          // 【変更点③】既読かどうかを、ダミーデータではなくSetの中身で判断
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
                // 【変更点④】タップされたら、既読リストに追加して保存する
                if (!isRead) {
                  setState(() {
                    _readAnnouncementIds.add(announcement.id);
                  });
                  _saveReadStatus();
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AnnouncementDetailScreen(announcement: announcement),
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