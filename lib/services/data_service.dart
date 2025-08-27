import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/announcement_item.dart';
import '../models/event_item.dart';
import '../models/map_models.dart';
import '../models/spotlight_item.dart';
import '../models/info_link_item.dart';

class DataService {
  DataService._internal();
  static final DataService _instance = DataService._internal();
  static DataService get instance => _instance;

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

  late List<EventItem> events;
  late List<EventItem> shuffledEvents;
  late List<AnnouncementItem> announcements;
  late List<SpotlightItem> spotlights;
  late List<MapInfo> maps;
  late List<MapPin> pins;
  late List<InfoLinkItem> infoLinks;

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    final results = await Future.wait([
      _fetchAndDecode(announcementsUrl),
      _fetchAndDecode(spotlightsUrl),
      _fetchAndDecode(eventsUrl),
      _fetchAndDecode(mapsUrl),
      _fetchAndDecode(pinsUrl),
      _fetchAndDecode(infolinksUrl),
    ]);

    announcements = (results[0]).map((json) => AnnouncementItem.fromJson(json)).toList();
    spotlights = (results[1]).map((json) => SpotlightItem.fromJson(json)).toList();
    events = (results[2]).map((json) => EventItem.fromJson(json)).toList();
    maps = (results[3]).map((json) => MapInfo.fromJson(json)).toList();
    pins = (results[4]).map((json) => MapPin.fromJson(json)).toList();
    infoLinks = (results[5]).map((json) => InfoLinkItem.fromJson(json)).toList();

    shuffledEvents = events.where((event) => !event.hideFromList).toList()..shuffle();

    _isInitialized = true;
    print("✅ DataService Initialized");
  }

  Future<void> refreshAnnouncements() async {
    print("🔄 Refreshing announcements...");
    final result = await _fetchAndDecode(announcementsUrl);
    announcements = (result).map((json) => AnnouncementItem.fromJson(json)).toList();
    print("✅ Announcements refreshed");
  }

  Future<void> refreshDynamicData() async {
    print("🔄 Refreshing dynamic data...");
    final results = await Future.wait([
      _fetchAndDecode(announcementsUrl),
      _fetchAndDecode(spotlightsUrl),
    ]);
    announcements = (results[0]).map((json) => AnnouncementItem.fromJson(json)).toList();
    spotlights = (results[1]).map((json) => SpotlightItem.fromJson(json)).toList();
    print("✅ Dynamic data refreshed");
  }

  Future<List<dynamic>> _fetchAndDecode(String urlString) async {
    final url = Uri.parse(urlString);
    final response = await http.get(url).timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      final rawJson = utf8.decode(response.bodyBytes);
      return jsonDecode(rawJson);
    } else {
      throw Exception('Failed to load data from $urlString');
    }
  }

  Future<List<dynamic>> _get(String cacheKey, String urlString) async {
    final prefs = await SharedPreferences.getInstance();

    final cachedData = prefs.getString(cacheKey);
    final lastFetchTime = prefs.getInt('${cacheKey}_time');

    if (cachedData != null && lastFetchTime != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if ((now - lastFetchTime) < (5 * 60 * 1000)) {
        print("✅ Loading from CACHE: $cacheKey");
        return jsonDecode(cachedData);
      }
    }

    print("☁️ Loading from NETWORK: $cacheKey");
    final url = Uri.parse(urlString);
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final rawJson = utf8.decode(response.bodyBytes);
        await prefs.setString(cacheKey, rawJson);
        await prefs.setInt('${cacheKey}_time', DateTime.now().millisecondsSinceEpoch);
        return jsonDecode(rawJson);
      } else {
        throw Exception('Failed to load data from $urlString');
      }
    } catch (e) {
      if (cachedData != null) {
        print("⚠️ Network error, returning STALE CACHE for $cacheKey");
        return jsonDecode(cachedData);
      }
      print('Error fetching $cacheKey: $e');
      rethrow;
    }
  }

  Future<List<EventItem>> getEvents() async {
    final jsonList = await _get('events_cache', eventsUrl);
    return jsonList.map((json) => EventItem.fromJson(json)).toList();
  }

  Future<List<EventItem>> getShuffledEvents() async {
    final allEvents = await getEvents();
    return allEvents.where((event) => !event.hideFromList).toList()..shuffle();
  }

  Future<List<AnnouncementItem>> getAnnouncements() async {
    final jsonList = await _get('announcements_cache', announcementsUrl);
    return jsonList.map((json) => AnnouncementItem.fromJson(json)).toList();
  }

  Future<List<SpotlightItem>> getSpotlights() async {
    final jsonList = await _get('spotlights_cache', spotlightsUrl);
    return jsonList.map((json) => SpotlightItem.fromJson(json)).toList();
  }

  Future<List<MapInfo>> getMaps() async {
    final jsonList = await _get('maps_cache', mapsUrl);
    return jsonList.map((json) => MapInfo.fromJson(json)).toList();
  }

  Future<List<MapPin>> getPins() async {
    final jsonList = await _get('pins_cache', pinsUrl);
    return jsonList.map((json) => MapPin.fromJson(json)).toList();
  }

  Future<List<InfoLinkItem>> getInfoLinks() async {
    final jsonList = await _get('infolinks_cache', infolinksUrl);
    return jsonList.map((json) => InfoLinkItem.fromJson(json)).toList();
  }

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
