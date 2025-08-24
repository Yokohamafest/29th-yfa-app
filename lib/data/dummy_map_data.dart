import 'package:flutter/material.dart';
import '../models/map_models.dart';

final List<MapPin> allPins = [
  MapPin(
    id: 'pin_b3',
    mapId: MapType.campus,
    position: Offset(0.45, 0.25),
    type: PinType.building,
    title: '3号館',
  ),
  MapPin(
    id: 'pin_b5',
    mapId: MapType.campus,
    position: Offset(0.15, 0.3),
    type: PinType.building,
    title: '5号館',
    detailText: '5号館（体育館）です。多くのステージ企画が開催されます。',
    link: PinLink(
      text: 'ステージ企画のタイムテーブルを見る',
      actionType: PinLinkActionType.timetable,
      actionValue: '', // 画面遷移だけなので値は不要
    ),
  ),
  MapPin(
    id: 'pin_restroom_1',
    mapId: MapType.campus,
    position: Offset(0.8, 0.5),
    type: PinType.restroom,
    title: 'お手洗い',
    iconSize: 24,
    detailText: 'トイレです'
  ),

  MapPin(
    id: 'pin_31A',
    mapId: MapType.building3F1,
    position: Offset(0.9, 0.5),
    type: PinType.location,
    title: '31A',
    link: PinLink(
      text: 'VALORANT ドラフト杯の企画詳細ページへ移動（テスト用）',
      actionType: PinLinkActionType.eventDetail,
      actionValue: 'event_011', // 遷移先の企画ID
    ),
  ),
  MapPin(
    id: 'pin_restroom_2',
    mapId: MapType.building3F1,
    position: Offset(0.65, 0.7),
    type: PinType.restroom,
    title: 'お手洗い',
    parentBuildingId: 'pin_b3',
    iconSize: 14,
    padding: const EdgeInsets.symmetric(horizontal: 3.0, vertical: 3.0),
  ),
  MapPin(
    id: 'pin_restroom_1',
    mapId: MapType.building2F1,
    position: Offset(0.3, 0.3),
    type: PinType.restroom,
    title: 'お手洗い',
    parentBuildingId: 'pin_b2',
  ),
  MapPin(
    id: 'pin_link_test1',
    mapId: MapType.campus,
    position: Offset(0.1, 0.5),
    type: PinType.location,
    title: 'テスト用ピン',
    detailText: 'このピンのリンクをタップすると、2号館1階に移動',
    link: PinLink(
      text: '2号館1階のフロアマップへ',
      actionType: PinLinkActionType.map,
      // 遷移先のMapTypeのenumの要素名を文字列で指定
      actionValue: 'building2F1',
    ),
  ),
  MapPin(
    id: 'pin_link_test2',
    mapId: MapType.campus,
    position: Offset(0.4, 0.5),
    type: PinType.vendingMachine,
    title: 'テスト用ピン',
    detailText: 'このピンのリンクをタップすると、オプション画面に移動',
    link: PinLink(
      text: 'オプション画面へ',
      actionType: PinLinkActionType.option,
      actionValue: '',
    ),
  ),
  MapPin(
    id: 'pin_link_test3',
    mapId: MapType.campus,
    position: Offset(0.6, 0.5),
    type: PinType.recyclingStation,
    title: 'テスト用ピン',
    detailText: 'このピンのリンクをタップすると、横浜祭ホームページに移動',
    link: PinLink(
      text: 'ホームページへ',
      actionType: PinLinkActionType.url,
      actionValue: 'https://yokohama-fest.net/29th',
    ),
  ),
];
