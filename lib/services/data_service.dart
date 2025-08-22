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
  final String eventsUrl = "https://events-eamyonqwna-an.a.run.app";
  final String announcementsUrl =
      "https://announcements-eamyonqwna-an.a.run.app";
  final String spotlightsUrl = "https://spotlights-eamyonqwna-an.a.run.app";
  final String mapsUrl = "https://maps-eamyonqwna-an.a.run.app";
  final String pinsUrl = "https://pins-eamyonqwna-an.a.run.app";
  final String infolinksUrl = "https://infolinks-eamyonqwna-an.a.run.app";
  final String devicesUrl = "https://devices-eamyonqwna-an.a.run.app";
  final String updateNotificationPreferenceUrl =
      "https://updatenotificationpreference-eamyonqwna-an.a.run.app";

  Future<List<dynamic>> _get(String endpointUrl) async {
    final url = Uri.parse(endpointUrl);
    print('>>> Requesting API at: $url');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception(
          'Failed to load data from $endpointUrl. Status code: ${response.statusCode}',
        );
      }
    } on TimeoutException {
      throw Exception('Server connection timed out for $endpointUrl.');
    } catch (e) {
      print('Error fetching $endpointUrl: $e');
      rethrow;
    }
  }

  // --- GET系API (全てシンプルな形に統一) ---

  Future<List<EventItem>> getEvents() async {
    final jsonList = await _get(eventsUrl);
    return jsonList.map((json) => EventItem.fromJson(json)).toList();
  }

  Future<List<EventItem>> getShuffledEvents() async {
    final allEvents = await getEvents();
    return allEvents.where((event) => !event.hideFromList).toList()..shuffle();
  }

  Future<List<AnnouncementItem>> getAnnouncements() async {
    final jsonList = await _get(announcementsUrl);
    return jsonList.map((json) => AnnouncementItem.fromJson(json)).toList();
  }

  Future<List<SpotlightItem>> getSpotlights() async {
    final jsonList = await _get(spotlightsUrl);
    return jsonList.map((json) => SpotlightItem.fromJson(json)).toList();
  }

  Future<List<MapInfo>> getMaps() async {
    final jsonList = await _get(mapsUrl);
    return jsonList.map((json) => MapInfo.fromJson(json)).toList();
  }

  Future<List<MapPin>> getPins() async {
    final jsonList = await _get(pinsUrl);
    return jsonList.map((json) => MapPin.fromJson(json)).toList();
  }

  Future<List<InfoLinkItem>> getInfoLinks() async {
    final jsonList = await _get(infolinksUrl);
    return jsonList.map((json) => InfoLinkItem.fromJson(json)).toList();
  }

  // --- POST系API ---
  Future<void> registerDeviceToken() async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) return;

      final url = Uri.parse(devicesUrl);
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

      final url = Uri.parse(updateNotificationPreferenceUrl);
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
