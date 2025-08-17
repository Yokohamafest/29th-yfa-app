import 'event_item.dart';
import 'map_models.dart';

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

extension PinTypeExt on PinType {
  String get displayName {
    switch (this) {
      case PinType.location:
        return '企画';
      case PinType.restroom:
        return 'お手洗い';
      case PinType.vendingMachine:
        return '自動販売機';
      case PinType.bikeParking:
        return '駐輪場';
      case PinType.smokingArea:
        return '喫煙所';
      case PinType.recyclingStation:
        return '資源ステーション';
      case PinType.building:
        return '建物';
    }
  }
}