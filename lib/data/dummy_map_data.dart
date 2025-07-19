import 'package:flutter/material.dart';
import '../models/map_models.dart';

// マップ画像のリスト
final List<MapInfo> allMaps = [
  MapInfo(id: MapType.campus, name: '全体マップ', imagePath: 'assets/maps/campus.png'),
  MapInfo(id: MapType.building2F1, name: '2号館1階', imagePath: 'assets/maps/b2f1.png'),
  MapInfo(id: MapType.building2F2, name: '2号館2階', imagePath: 'assets/maps/b2f2.png'),
  MapInfo(id: MapType.building3F1, name: '3号館1階', imagePath: 'assets/maps/b3f1.png'),
  MapInfo(id: MapType.building3F2, name: '3号館2階', imagePath: 'assets/maps/b3f2.png'),
  MapInfo(id: MapType.building3F3, name: '3号館3階', imagePath: 'assets/maps/b3f3.png'),
  MapInfo(id: MapType.building3B1, name: '3号館地下1階', imagePath: 'assets/maps/b3b1.png'),
  MapInfo(id: MapType.building3B2, name: '3号館地下2階', imagePath: 'assets/maps/b3f2.png'),
  MapInfo(id: MapType.building4F1F2, name: '4号館1階・2階', imagePath: 'assets/maps/b4f1f2.png'),
];

// 全てのピンのリスト
final List<MapPin> allPins = [
  // --- 全体マップ上のピン ---
  MapPin(id: 'pin_b3', mapId: MapType.campus, position: Offset(200, 300), type: PinType.building, title: '3号館', eventIds: ['event_011', 'event_016']),
  MapPin(id: 'pin_gym', mapId: MapType.campus, position: Offset(100, 400), type: PinType.building, title: '体育館', eventIds: ['event_001', 'event_003']),
  MapPin(id: 'pin_restroom_1', mapId: MapType.campus, position: Offset(150, 350), type: PinType.restroom, title: 'お手洗い'),

  // --- 3号館1階のピン ---
  MapPin(id: 'pin_3_f1_event', mapId: MapType.building3F1, position: Offset(50, 80), type: PinType.event, title: '〇〇展示', eventIds: ['event_099']),
  MapPin(id: 'pin_restroom_2', mapId: MapType.building3F1, position: Offset(120, 100), type: PinType.restroom, title: 'お手洗い'),
  // ... 他の全てのピン情報を追加 ...
];