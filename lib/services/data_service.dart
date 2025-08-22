import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';

// 各モデルのインポート文（あなたのプロジェクトに合わせてください）
import '../models/announcement_item.dart';
import '../models/event_item.dart';
import '../models/map_models.dart';
import '../models/spotlight_item.dart';
import '../models/info_link_item.dart';

class DataService {
  // ■■■ v1形式に統一された、共通のベースURL ■■■
  // (あなたのPCのIPアドレス、または本番用にhttps://...を記述)
  final String _baseUrl = "-eamyonqwna-an.a.run.app";

  // 汎用的なGETリクエスト処理
  Future<List<dynamic>> _get(String endpoint) async {
    final url = Uri.parse('https://$endpoint$_baseUrl');
    print('>>> Requesting API at: $url');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception(
          'Failed to load data from $endpoint. Status code: ${response.statusCode}',
        );
      }
    } on TimeoutException {
      throw Exception('Server connection timed out for $endpoint.');
    } catch (e) {
      print('Error fetching $endpoint: $e');
      rethrow;
    }
  }

  // --- GET系API (全てシンプルな形に統一) ---

  Future<List<EventItem>> getEvents() async {
    final jsonList = await _get('events');
    return jsonList.map((json) => EventItem.fromJson(json)).toList();
  }

  Future<List<EventItem>> getShuffledEvents() async {
    final allEvents = await getEvents();
    return allEvents.where((event) => !event.hideFromList).toList()..shuffle();
  }

  Future<List<AnnouncementItem>> getAnnouncements() async {
    final jsonList = await _get('announcements');
    return jsonList.map((json) => AnnouncementItem.fromJson(json)).toList();
  }

  Future<List<SpotlightItem>> getSpotlights() async {
    final jsonList = await _get('spotlights');
    return jsonList.map((json) => SpotlightItem.fromJson(json)).toList();
  }

  Future<List<MapInfo>> getMaps() async {
    final jsonList = await _get('maps');
    return jsonList.map((json) => MapInfo.fromJson(json)).toList();
  }

  Future<List<MapPin>> getPins() async {
    final jsonList = await _get('pins');
    return jsonList.map((json) => MapPin.fromJson(json)).toList();
  }

  Future<List<InfoLinkItem>> getInfoLinks() async {
    final jsonList = await _get('infolinks');
    return jsonList.map((json) => InfoLinkItem.fromJson(json)).toList();
  }

  // --- POST系API ---
  Future<void> registerDeviceToken() async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) return;

      final url = Uri.parse('$_baseUrl/devices');
      await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'token': fcmToken}),
          )
          .timeout(const Duration(seconds: 15));
      print("Device token registered to EMULATOR.");
    } catch (e) {
      print("Failed to register token: $e");
    }
  }

  Future<void> updateNotificationPreference(bool isEnabled) async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) return;

      final url = Uri.parse('$_baseUrl/updateNotificationPreference');
      await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'token': fcmToken, 'enabled': isEnabled}),
          )
          .timeout(const Duration(seconds: 15));
      print("Notification preference updated on EMULATOR.");
    } catch (e) {
      print("Failed to update preference: $e");
    }
  }
}
