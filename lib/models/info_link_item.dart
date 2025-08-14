class InfoLinkItem {
  final String title;      // 表示するテキスト
  final String url;        // 遷移先のURL
  final String iconName;   // 表示するアイコンの名前

  const InfoLinkItem({
    required this.title,
    required this.url,
    required this.iconName,
  });

  factory InfoLinkItem.fromJson(Map<String, dynamic> json) {
    return InfoLinkItem(
      title: json['title'],
      url: json['url'],
      iconName: json['iconName'],
    );
  }
}