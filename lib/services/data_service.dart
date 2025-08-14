import '../data/dummy_announcements.dart';
import '../data/dummy_events.dart';
import '../data/dummy_map_data.dart';
import '../data/dummy_spotlights.dart';
import '../data/dummy_info_links.dart';
import '../models/announcement_item.dart';
import '../models/event_item.dart';
import '../models/map_models.dart';
import '../models/spotlight_item.dart';
import '../models/info_link_item.dart';

// アプリの全てのデータ供給を担当するクラス
class DataService {
  // 企画情報を取得する（将来的にはおそらくここでFirebaseから取得）
  Future<List<EventItem>> getEvents() async {
    // 現在はダミーデータを返す
    // Future.delayedを追加して、実際のネットワーク通信を再現している
    await Future.delayed(const Duration(milliseconds: 500));
    return dummyEvents;
  }

  // シャッフル済みの企画情報を取得する
  // データ取得の処理は上のgetEventsを利用している
  Future<List<EventItem>> getShuffledEvents() async {
    final allEvents = await getEvents();
    return allEvents.where((event) => !event.hideFromList).toList()..shuffle();
  }

  // お知らせ情報を取得する
  Future<List<AnnouncementItem>> getAnnouncements() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return dummyAnnouncements;
  }

  // 注目企画の情報を取得する
  Future<List<SpotlightItem>> getSpotlights() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return dummySpotlights;
  }

  // マップの情報を取得する
  Future<List<MapInfo>> getMaps() async {
    return Future.value(allMaps);
  }

  // ピンの情報を取得する
  Future<List<MapPin>> getPins() async {
    return Future.value(allPins);
  }

  // オプション画面の情報・サポートのリンクを取得する
  Future<List<InfoLinkItem>> getInfoLinks() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return dummyInfoLinks;
  }
}