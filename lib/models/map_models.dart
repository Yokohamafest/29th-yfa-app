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

// 個々のピンの情報を持つクラス
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
  });
}
