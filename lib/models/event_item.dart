// event_item.dart

// 開催日を表現するためのenum
enum FestivalDay {
  dayOne, // 1日目
  dayTwo, // 2日目
  both, // 両日
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


// 企画カテゴリを表現するためのenum
enum EventCategory {
  stage, // ステージ
  exhibit, // 展示
  food, // 飲食
  handsOn, // 体験
  game, //ゲーム
  goods, //物販
  other, // その他
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
  final List<EventArea> areas;
  final List<String> locations;
  final List<EventCategory> categories;
  final bool hideFromList; // trueなら企画一覧とお気に入り一覧に表示しない デフォルトはfalse
  final bool disableDetailsLink; // trueなら詳細ページへの遷移を無効にする デフォルトはfalse
  final FestivalDay date;
  final List<TimeSlot>? timeSlots; // デフォルトは空のリスト 時間指定のない終日開催企画は、このリストが空になる

  const EventItem({
    required this.id,
    required this.title,
    required this.groupName,
    required this.description,
    required this.imagePath,
    required this.areas,
    required this.locations,
    required this.categories,
    this.hideFromList = false,
    this.disableDetailsLink = false,
    required this.date,
    this.timeSlots,
  });

  factory EventItem.fromJson(Map<String, dynamic> json) {
    List<TimeSlot>? timeSlots;
    if (json['timeSlots'] != null) {
      timeSlots = (json['timeSlots'] as List)
          .map((slot) => TimeSlot.fromJson(slot))
          .toList();
    }

    return EventItem(
      id: json['id'] ?? " ",
      title: json['title'] ?? " ",
      groupName: json['groupName'] ?? " ",
      description: json['description'] ?? " ",
      imagePath: json['imagePath'] ?? " ",
      areas: (json['areas'] as List?)
              ?.map((area) => EventArea.values.byName(area as String))
              .toList() ??
          [],
      locations: List<String>.from(json['locations'] ?? []),
      categories: (json['categories'] as List)
          .map((category) => EventCategory.values.byName(category))
          .toList(),
      hideFromList: json['hideFromList'] ?? false,
      disableDetailsLink: json['disableDetailsLink'] ?? false,
      date: FestivalDay.values.byName(json['date'] ?? "dayOne"),
      timeSlots: timeSlots,
    );
  }
}
