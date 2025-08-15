import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/event_item.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));
  }

  Future<void> scheduleReminder(EventItem event, int reminderMinutes) async {
    for (final timeSlot in event.timeSlots) {
      final scheduleTime =
          timeSlot.startTime.subtract(Duration(minutes: reminderMinutes));

      if (scheduleTime.isBefore(DateTime.now())) {
        continue;
      }

      final notificationId =
          '${event.id}_${timeSlot.startTime.toIso8601String()}'.hashCode;

      await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        event.title,
        'まもなく「${event.location}」で始まります',
        tz.TZDateTime.from(scheduleTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'event_reminders',
            '企画リマインダー',
            channelDescription: 'お気に入りに登録した企画の開始を通知します。',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  Future<void> cancelReminder(EventItem event) async {
    for (final timeSlot in event.timeSlots) {
      final notificationId =
          '${event.id}_${timeSlot.startTime.toIso8601String()}'.hashCode;
      await flutterLocalNotificationsPlugin.cancel(notificationId);
    }
  }
}