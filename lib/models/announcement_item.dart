class AnnouncementItem {
  final String id;
  final String title;
  final String content;
  final DateTime publishedAt;
  final bool isRead;

  const AnnouncementItem({
    required this.id,
    required this.title,
    required this.content,
    required this.publishedAt,
    this.isRead = false,
  });

  factory AnnouncementItem.fromJson(Map<String, dynamic> json) {
    return AnnouncementItem(
      id: json['id'] ?? " ",
      title: json['title'] ?? " ",
      content: json['content'] ?? " ",
      publishedAt: DateTime.parse(json['publishedAt']),
    );
  }
}
