// event_item.dart

// 一つの企画が持つ情報を定義するクラス
class EventItem {
  final String id; // 各企画を区別するID
  final String title; // 企画名
  final String groupName; // 団体名
  final String description; // 企画の詳しい説明文
  final String imagePath; // サムネイル画像のパス
  final String location; // 開催場所
  final String category; // カテゴリ
  final DateTime? startTime; // 開始時間 (時間指定のない企画はnull)
  final DateTime? endTime;   // 終了時間 (時間指定のない企画はnull)

  // このクラスからインスタンスを作るコンストラクタ
  const EventItem({
    required this.id,
    required this.title,
    required this.groupName,
    required this.description,
    required this.imagePath,
    required this.location,
    required this.category,
    this.startTime, // 決まった時刻がないものもあるのでrequiredではない
    this.endTime,
  });
}