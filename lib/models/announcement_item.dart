class AnnouncementItem {
  final String id;
  final String title;
  final String content;
  final DateTime publishedAt;
  final bool isRead; // 既読・未読を管理するフラグ

  const AnnouncementItem({
    required this.id,
    required this.title,
    required this.content,
    required this.publishedAt,
    this.isRead = false,
  });
}