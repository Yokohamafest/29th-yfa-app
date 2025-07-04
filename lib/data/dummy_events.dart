import '../models/event_item.dart';

// アプリ内で使用するダミーの企画データリスト
// バックエンドが完成したら、この部分はサーバーから取得したデータに置き換わる
final List<EventItem> dummyEvents = [
  // --- ダミーデータ1: 時間指定のあるステージ企画 ---
  EventItem(
    id: 'event_001',
    title: 'お笑いライブ',
    groupName: '学生団体A',
    description: '大人気お笑い芸人〇〇と△△が登場！笑いと感動のステージをお見逃しなく。',
    imagePath: 'assets/images/sample_event_1.png', // 仮の画像パス
    area: EventArea.building5,
    location: 'メインステージ',
    category: EventCategory.stage,
    date: FestivalDay.dayTwo,
    startTime: DateTime(2025, 10, 25, 13, 0), // 2025年10月25日 13:00
    endTime: DateTime(2025, 10, 25, 14, 0),   // 2025年10月25日 14:00
  ),

  // --- ダミーデータ2: 時間指定のない展示企画 ---
  EventItem(
    id: 'event_002',
    title: '鉄道研究部 模型展示',
    groupName: '鉄道研究部',
    description: '部員が丹精込めて作り上げた、リアルな鉄道模型の世界へようこそ。Nゲージの巨大ジオラマは圧巻です。',
    imagePath: 'assets/images/sample_event_2.png',
    area: EventArea.building3,
    location: '31A教室',
    category: EventCategory.exhibit,
    date: FestivalDay.dayOne,
  ),

  // --- ダミーデータ3: 時間指定のない飲食企画 ---
  EventItem(
    id: 'event_003',
    title: '絶品！こだわり焼きそば',
    groupName: '料理サークルB',
    description: 'ソースから手作りした、こだわりの絶品焼きそばです。毎年行列ができる人気メニュー！',
    imagePath: 'assets/images/sample_event_3.png',
    area: EventArea.outdoor,
    location: '模擬店エリア',
    category: EventCategory.food,
    date: FestivalDay.both,
  ),
];