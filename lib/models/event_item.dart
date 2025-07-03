// event_item.dart

// 開催日を表現するためのenum
enum FestivalDay {
  dayOne, // 1日目
  dayTwo, // 2日目
  both,   // 両日
}

// 開催エリアを表現するためのenum
enum EventArea {
  building1,
  building2,
  building3,
  building4,
  building5, // 体育館
  outdoor, // 屋外模擬店
  other,        // その他
}

// 企画カテゴリを表現するためのenum
enum EventCategory {
  stage,      // ステージ
  exhibit,    // 展示
  food,       // 飲食
  handsOn,    // 体験型
  game,       //ゲーム
  other,      // その他
}


// 一つの企画が持つ情報を定義するクラス
class EventItem {
  final String id;
  final String title;
  final String groupName;
  final String description;
  final String imagePath;
  final EventArea area;
  final String location;
  final EventCategory category;
  final FestivalDay date;
  final DateTime? startTime;
  final DateTime? endTime;

  const EventItem({
    required this.id,
    required this.title,
    required this.groupName,
    required this.description,
    required this.imagePath,
    required this.area,
    required this.location,
    required this.category,
    required this.date,
    this.startTime,
    this.endTime,
  });
}
