// event_item.dart

// 開催日を表現するためのenum
enum FestivalDay {
  dayOne, // 1日目
  dayTwo, // 2日目
  both, // 両日
}

extension FestivalDayExt on FestivalDay {
  String get name {
    switch (this) {
      case FestivalDay.dayOne:
        return '1日目';

      case FestivalDay.dayTwo:
        return '2日目';

      case FestivalDay.both:
        return '両日';
    }
  }
}

// 開催エリアを表現するためのenum
enum EventArea {
  building1,
  building2,
  building3,
  building4,
  building5, // 体育館
  outdoor, // 屋外模擬店
  other, // その他
}

extension EventAreaExt on EventArea {
  String get name {
    switch (this) {
      case EventArea.building1:
        return '1号館';

      case EventArea.building2:
        return '2号館';

      case EventArea.building3:
        return '3号館';

      case EventArea.building4:
        return '4号館';

      case EventArea.building5:
        return '体育館';

      case EventArea.outdoor:
        return '屋外';

      case EventArea.other:
        return 'その他';
    }
  }
}

// 企画カテゴリを表現するためのenum
enum EventCategory {
  stage, // ステージ
  exhibit, // 展示
  food, // 飲食
  handsOn, // 体験
  game, //ゲーム
  other, // その他
}

extension EventCategoryExt on EventCategory {
  String get name {
    switch (this) {
      case EventCategory.stage:
        return 'ステージ';

      case EventCategory.exhibit:
        return '展示';

      case EventCategory.food:
        return '飲食';

      case EventCategory.handsOn:
        return '体験';

      case EventCategory.game:
        return 'ゲーム';

      case EventCategory.other:
        return 'その他';
    }
  }
}

class TimeSlot {
  final DateTime startTime;
  final DateTime endTime;

  const TimeSlot({required this.startTime, required this.endTime});
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
  final List<EventCategory> categories;
  final bool hideFromList; // trueなら企画一覧とお気に入り一覧に表示しない
  final bool disableDetailsLink; // trueなら詳細ページへの遷移を無効にする
  final FestivalDay date;
  final List<TimeSlot> timeSlots;

  const EventItem({
    required this.id,
    required this.title,
    required this.groupName,
    required this.description,
    required this.imagePath,
    required this.area,
    required this.location,
    required this.categories,
    this.hideFromList = false, // デフォルトはfalseに設定
    this.disableDetailsLink = false, // デフォルトはfalseに設定
    required this.date,
    // デフォルトは空のリスト。時間指定のない常時開催企画は、このリストが空になる
    this.timeSlots = const [],
  });
}
