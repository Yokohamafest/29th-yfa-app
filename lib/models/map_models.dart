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
  building4F1,
  building4F2,
}

// マップ画像の情報を持つクラス
class MapInfo {
  final MapType id;
  final String name;
  final String imagePath;
  final int sortOrder;
  const MapInfo({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.sortOrder,
  });

  factory MapInfo.fromJson(Map<String, dynamic> json) {
    return MapInfo(
      id: MapType.values.byName(json['id'] ?? "campus"),
      name: json['name'] ?? " ",
      imagePath: json['imagePath'] ?? " ",
      sortOrder: json['sortOrder'] ?? 99,
    );
  }
}

// ピンの種類
enum PinType {
  location,
  restroom,
  vendingMachine,
  bikeParking,
  smokingArea,
  recyclingStation,
  building, // 建物全体を示すピン
}

enum PinVisualStyle {
  defaultBox,
  marker,
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
      text: json['text'] ?? " ",
      actionType: PinLinkActionType.values.byName(json['actionType'] ?? "timetable"),
      actionValue: json['actionValue'] ?? " ",
    );
  }
}

class MapPin {
  final String id;
  final MapType mapId; // どのマップに所属するか
  final Offset position; // マップ画像上のXY座標 (左上が0,0)
  final PinType type;
  final String title;
  final PinVisualStyle visualStyle;
  final String? parentBuildingId; // どの建物に属しているかを示すID (屋外ならnull)
  final double? fontSize;
  final double? iconSize;
  final double? markerSize;
  final EdgeInsets? padding;
  final String? detailText;
  final bool showDetailText;
  final PinLink? link;
  final bool hideUntilZoomed;

  const MapPin({
    required this.id,
    required this.mapId,
    required this.position,
    required this.type,
    required this.title,
    this.visualStyle = PinVisualStyle.defaultBox,
    this.parentBuildingId,
    this.fontSize, // デフォルトは10
    this.iconSize,
    this.padding,
    this.markerSize,
    this.detailText,
    this.showDetailText = true,
    this.link,
    this.hideUntilZoomed = false,
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
      // もしJSONに'id'がなければ、空文字列''をデフォルト値として使う
      id: json['id'] ?? '',
      // もしJSONに'mapId'がなければ、'other'をデフォルト値として使う
      mapId: MapType.values.byName(json['mapId'] ?? 'other'),
      position: Offset(
        (json['position']?['dx'] as num? ?? 0.0).toDouble(),
        (json['position']?['dy'] as num? ?? 0.0).toDouble(),
      ),
      // もしJSONに'type'がなければ、'location'をデフォルト値として使う
      type: PinType.values.byName(json['type'] ?? 'location'),
      // もしJSONに'title'がなければ、'名称未設定'をデフォルト値として使う
      title: json['title'] ?? '名称未設定',
      visualStyle: PinVisualStyle.values.byName(json['visualStyle'] ?? 'defaultBox'),
      parentBuildingId: json['parentBuildingId'],
      fontSize: (json['fontSize'] as num?)?.toDouble(),
      iconSize: (json['iconSize'] as num?)?.toDouble(),
      padding: padding,
      markerSize: (json['markerSize'] as num?)?.toDouble(),
      detailText: json['detailText'],
      link: json['link'] != null ? PinLink.fromJson(json['link']) : null,
      hideUntilZoomed: json['hideUntilZoomed'] ?? false,
    );
  }
}
