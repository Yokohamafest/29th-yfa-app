import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/event_item.dart';
import '../widgets/reminder_permission_dialog.dart';

class NotificationPermissionsStatus {
  final bool isNotificationGranted;
  final bool isExactAlarmGranted;

  const NotificationPermissionsStatus({
    required this.isNotificationGranted,
    required this.isExactAlarmGranted,
  });

  bool get allGranted => isNotificationGranted && isExactAlarmGranted;
}

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));
  }

  Future<NotificationPermissionsStatus> checkPermissions() async {
    final notificationStatus = await Permission.notification.status;
    final exactAlarmStatus = await Permission.scheduleExactAlarm.status;
    return NotificationPermissionsStatus(
      isNotificationGranted: notificationStatus.isGranted,
      isExactAlarmGranted: exactAlarmStatus.isGranted,
    );
  }

  Future<bool> _requestExactAlarmPermission(BuildContext context) async {
    if (await Permission.scheduleExactAlarm.isGranted) {
      return true;
    }

    final status = await Permission.scheduleExactAlarm.request();
    if (status.isGranted) {
      return true;
    }

    if (status.isPermanentlyDenied || status.isDenied) {
      if (!context.mounted) return false;
      await showDialog(
        context: context,
        builder: (context) => NotificationPermissionDialog(
          permissionsStatus: NotificationPermissionsStatus(
            isNotificationGranted: true,
            isExactAlarmGranted: false,
          ),
        ),
      );
      return await Permission.scheduleExactAlarm.isGranted;
    }
    return false;
  }

  Future<void> scheduleReminder(
    BuildContext context,
    EventItem event,
    int reminderMinutes,
  ) async {
    final hasPermission = await _requestExactAlarmPermission(context);
    if (!hasPermission) {
      debugPrint('Exact alarm permission not granted.');
      return;
    }
    for (final timeSlot in event.timeSlots) {
      final scheduleTime = timeSlot.startTime.subtract(
        Duration(minutes: reminderMinutes),
      );

      if (scheduleTime.isBefore(DateTime.now())) {
        continue;
      }

      final notificationId =
          '${event.id}_${timeSlot.startTime.toIso8601String()}_$reminderMinutes'
              .hashCode;

      await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        event.title,
        '${event.title}が$reminderMinutes分後に「${event.location}」で始まります!',
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
    final possibleMinutes = [5, 15, 30, 60];
    for (final timeSlot in event.timeSlots) {
      for (final minutes in possibleMinutes) {
        final notificationId =
            '${event.id}_${timeSlot.startTime.toIso8601String()}_$minutes'
                .hashCode;
        await flutterLocalNotificationsPlugin.cancel(notificationId);
      }
    }
  }

  Future<void> showPushNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'general_notifications',
      '運営からのお知らせ',
      channelDescription: '運営からの重要なお知らせを通知します。',
      importance: Importance.max,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecond,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }
}
