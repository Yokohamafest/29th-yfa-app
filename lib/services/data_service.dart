import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';

import '../models/announcement_item.dart';
import '../models/event_item.dart';
import '../models/map_models.dart';
import '../models/spotlight_item.dart';
import '../models/info_link_item.dart';

class DataService {
  // ローカルテスト用のベースURL (Android Emulator用)
  final String _baseUrl =
      "http://192.168.8.90:5001/yokohama-fest-29-dev/asia-northeast1";

  Future<List<dynamic>> _get(String urlString) async {
    final url = Uri.parse(urlString);
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception(
          'Failed to load data from $urlString. Status code: ${response.statusCode}',
        );
      }
    } on TimeoutException {
      throw Exception('Server connection timed out for $urlString.');
    } catch (e) {
      print('Error fetching $urlString: $e');
      rethrow;
    }
  }

  // --- GET系API ---
  Future<List<EventItem>> getEvents() async {
    final url =
        "http://192.168.8.90:5001/yokohama-festival-29-dev/asia-northeast1/events";
    final jsonList = await _get(url);
    return jsonList.map((json) => EventItem.fromJson(json)).toList();
  }

  // ▼▼▼ このメソッドを復活させました ▼▼▼
  Future<List<EventItem>> getShuffledEvents() async {
    // まずはgetEvents()ですべての企画を取得
    final allEvents = await getEvents();
    // hideFromListがfalseのものだけをフィルタリングして、シャッフルして返す
    return allEvents.where((event) => !event.hideFromList).toList()..shuffle();
  }
  // ▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲

  Future<List<AnnouncementItem>> getAnnouncements() async {
    final jsonList = await _get("$_baseUrl/announcements");
    return jsonList.map((json) => AnnouncementItem.fromJson(json)).toList();
  }

  Future<List<SpotlightItem>> getSpotlights() async {
    final jsonList = await _get("$_baseUrl/spotlights");
    return jsonList.map((json) => SpotlightItem.fromJson(json)).toList();
  }

  Future<List<MapInfo>> getMaps() async {
    final jsonList = await _get("$_baseUrl/maps");
    return jsonList.map((json) => MapInfo.fromJson(json)).toList();
  }

  Future<List<MapPin>> getPins() async {
    final jsonList = await _get("$_baseUrl/pins");
    return jsonList.map((json) => MapPin.fromJson(json)).toList();
  }

  Future<List<InfoLinkItem>> getInfoLinks() async {
    final jsonList = await _get("$_baseUrl/infolinks");
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
