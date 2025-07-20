import 'package:flutter/material.dart';
import '../models/map_models.dart';

// マップ画像のリスト
final List<MapInfo> allMaps = [
  MapInfo(
    id: MapType.campus,
    name: '全体マップ',
    imagePath: 'assets/maps/campus.png',
  ),
  MapInfo(
    id: MapType.building2F1,
    name: '2号館1階',
    imagePath: 'assets/maps/b2f1.png',
  ),
  MapInfo(
    id: MapType.building2F2,
    name: '2号館2階',
    imagePath: 'assets/maps/b2f2.png',
  ),
  MapInfo(
    id: MapType.building3F1,
    name: '3号館1階',
    imagePath: 'assets/maps/b3f1.png',
  ),
  MapInfo(
    id: MapType.building3F2,
    name: '3号館2階',
    imagePath: 'assets/maps/b3f2.png',
  ),
  MapInfo(
    id: MapType.building3F3,
    name: '3号館3階',
    imagePath: 'assets/maps/b3f3.png',
  ),
  MapInfo(
    id: MapType.building3B1,
    name: '3号館地下1階',
    imagePath: 'assets/maps/b3b1.png',
  ),
  MapInfo(
    id: MapType.building3B2,
    name: '3号館地下2階',
    imagePath: 'assets/maps/b3b2.png',
  ),
  MapInfo(
    id: MapType.building4F1F2,
    name: '4号館1階・2階',
    imagePath: 'assets/maps/b4f1f2.png',
  ),
];

final List<MapPin> allPins = [
  MapPin(
    id: 'pin_b3',
    mapId: MapType.campus,
    position: Offset(200, 80),
    type: PinType.building,
    title: '3号館',
  ),
  MapPin(
    id: 'pin_gym',
    mapId: MapType.campus,
    position: Offset(80, 100),
    type: PinType.building,
    title: '体育館',
  ),
  MapPin(
    id: 'pin_restroom_1',
    mapId: MapType.campus,
    position: Offset(150, 200),
    type: PinType.restroom,
    title: 'お手洗い',
    iconSize: 24,
  ),

  MapPin(
    id: 'pin_31A',
    mapId: MapType.building3F1,
    position: Offset(361, 124),
    type: PinType.event,
    title: '31A',
  ),
  MapPin(
    id: 'pin_restroom_2',
    mapId: MapType.building3F1,
    position: Offset(243, 133),
    type: PinType.restroom,
    title: 'お手洗い',
    parentBuildingId: 'pin_b3',
    iconSize: 14,
    padding: const EdgeInsets.symmetric(horizontal: 3.0, vertical: 3.0),
  ),
  MapPin(
    id: 'pin_restroom_1',
    mapId: MapType.building2F1,
    position: Offset(120, 100),
    type: PinType.restroom,
    title: 'お手洗い',
    parentBuildingId: 'pin_b2',
  ),
];
