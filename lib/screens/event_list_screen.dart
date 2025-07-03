import 'package:flutter/material.dart';
import '../data/dummy_events.dart';
import '../widgets/event_card.dart';

class EventListScreen extends StatelessWidget {
  const EventListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 画面上部のアプリバー
      appBar: AppBar(
        title: const Text('企画一覧'),
        backgroundColor: Colors.white,
        elevation: 1.0,
      ),
      // 画面の本体
      body: ListView.builder(
        // リスト全体の上下左右に余白を設定
        padding: const EdgeInsets.all(8.0),
        // 表示するアイテムの数（ダミーデータの数）
        itemCount: dummyEvents.length,
        // 各行の見た目を生成する部分
        itemBuilder: (BuildContext context, int index) {
          // ダミーデータのリストから、該当するインデックスの企画情報を取得
          final event = dummyEvents[index];
          // 先ほど作成した共通ウィジェット「EventCard」を返す
          return EventCard(event: event);
        },
      ),
    );
  }
}
