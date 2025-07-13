import '../models/announcement_item.dart';

final List<AnnouncementItem> dummyAnnouncements = [
  AnnouncementItem(
    id: 'anno_001',
    title: '【重要】お笑いライブについて',
    content:
        'text text text text text text text text text text text text text text text text text text text text ',
    publishedAt: DateTime(2025, 9, 15, 10, 30),
  ),
  AnnouncementItem(
    id: 'anno_002',
    title: '落とし物のお知らせ',
    content:
        'text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text ',
    publishedAt: DateTime(2025, 9, 15, 9, 15),
  ),
  AnnouncementItem(
    id: 'anno_003',
    title: '横浜祭へようこそ！',
    content:
        'text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text ',
    publishedAt: DateTime(2025, 9, 14, 10, 0),
  ),
];
