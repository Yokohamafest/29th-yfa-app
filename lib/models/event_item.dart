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
        return '5号館';

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

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
    );
  }
}

class EventItem {
  final String id;
  final String title;
  final String groupName;
  final String description;
  final String imagePath;
  final EventArea area;
  final String
  location; // この文字列によってどこで行われる企画なのかを判定している（タイムテーブル画面とマップ画面）ので、文字は統一するように（「体育館」や「31A」、「32A」など）
  final List<EventCategory> categories;
  final bool hideFromList; // trueなら企画一覧とお気に入り一覧に表示しない デフォルトはfalse
  final bool disableDetailsLink; // trueなら詳細ページへの遷移を無効にする デフォルトはfalse
  final FestivalDay date;
  final List<TimeSlot> timeSlots; // デフォルトは空のリスト 時間指定のない常時開催企画は、このリストが空になる

  const EventItem({
    required this.id,
    required this.title,
    required this.groupName,
    required this.description,
    required this.imagePath,
    required this.area,
    required this.location,
    required this.categories,
    this.hideFromList = false,
    this.disableDetailsLink = false,
    required this.date,
    this.timeSlots = const [],
  });

  factory EventItem.fromJson(Map<String, dynamic> json) {
    return EventItem(
      id: json['id'],
      title: json['title'],
      groupName: json['groupName'],
      description: json['description'],
      imagePath: json['imagePath'],
      area: EventArea.values.byName(json['area']),
      location: json['location'],
      categories: (json['categories'] as List)
          .map((category) => EventCategory.values.byName(category))
          .toList(),
      hideFromList: json['hideFromList'] ?? false,
      disableDetailsLink: json['disableDetailsLink'] ?? false,
      date: FestivalDay.values.byName(json['date']),
      timeSlots: (json['timeSlots'] as List)
          .map((slot) => TimeSlot.fromJson(slot))
          .toList(),
    );
  }
}
