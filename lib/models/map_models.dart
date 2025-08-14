import 'package:flutter/material.dart';

// マップの種類
enum MapType {
  campus,
  building2F1,
  building2F2,
  building3B2,
  building3B1,
  building3F1,
  building3F2,
  building3F3,
  building4F1F2,
}

// マップ画像の情報を持つクラス
class MapInfo {
  final MapType id;
  final String name;
  final String imagePath;
  const MapInfo({
    required this.id,
    required this.name,
    required this.imagePath,
  });
}

// ピンの種類
enum PinType {
  event,
  restroom,
  vendingMachine,
  bikeParking,
  smokingArea,
  recyclingStation,
  building, // 建物全体を示すピン
}

enum PinLinkActionType {
  url,
  map,
  eventDetail,
  announcementDetail,
  option,
  timetable,
}

class PinLink {
  final String text;
  final PinLinkActionType actionType;
  final String actionValue;

  const PinLink({
    required this.text,
    required this.actionType,
    required this.actionValue,
  });

  factory PinLink.fromJson(Map<String, dynamic> json) {
    return PinLink(
      text: json['text'],
      actionType: PinLinkActionType.values.byName(json['actionType']),
      actionValue: json['actionValue'],
    );
  }
}

class MapPin {
  final String id;
  final MapType mapId; // どのマップに所属するか
  final Offset position; // マップ画像上のXY座標 (左上が0,0)
  final PinType type;
  final String title;
  final String? parentBuildingId; // どの建物に属しているかを示すID (屋外ならnull)
  final double? fontSize;
  final double? iconSize;
  final EdgeInsets? padding;
  final String? detailText;
  final bool showDetailText;
  final PinLink? link;

  const MapPin({
    required this.id,
    required this.mapId,
    required this.position,
    required this.type,
    required this.title,
    this.parentBuildingId,
    this.fontSize,
    this.iconSize,
    this.padding,
    this.detailText,
    this.showDetailText = true,
    this.link,
  });

  factory MapPin.fromJson(Map<String, dynamic> json) {
    EdgeInsets? padding;
    if (json['padding'] != null) {
      // JSONのpaddingはMap形式で設定
      final paddingMap = json['padding'] as Map<String, dynamic>;
      padding = EdgeInsets.only(
        left: (paddingMap['left'] as num?)?.toDouble() ?? 0.0,
        top: (paddingMap['top'] as num?)?.toDouble() ?? 0.0,
        right: (paddingMap['right'] as num?)?.toDouble() ?? 0.0,
        bottom: (paddingMap['bottom'] as num?)?.toDouble() ?? 0.0,
      );
    }

    return MapPin(
      id: json['id'],
      mapId: MapType.values.byName(json['mapId']),
      position: Offset(
        (json['position']['dx'] as num).toDouble(),
        (json['position']['dy'] as num).toDouble(),
      ),
      type: PinType.values.byName(json['type']),
      title: json['title'],
      parentBuildingId: json['parentBuildingId'],
      fontSize: (json['fontSize'] as num?)?.toDouble(),
      iconSize: (json['iconSize'] as num?)?.toDouble(),
      padding: padding,
      detailText: json['detailText'],
      showDetailText: json['showDetailText'] ?? true,
      link: json['link'] != null ? PinLink.fromJson(json['link']) : null,
    );
  }
}
