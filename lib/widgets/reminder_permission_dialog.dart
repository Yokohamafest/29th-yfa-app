import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

class NotificationPermissionDialog extends StatefulWidget {
  final NotificationPermissionsStatus permissionsStatus;
  const NotificationPermissionDialog({
    super.key,
    required this.permissionsStatus,
  });

  @override
  State<NotificationPermissionDialog> createState() =>
      _NotificationPermissionDialogState();
}

class _NotificationPermissionDialogState
    extends State<NotificationPermissionDialog> {
  bool _dontShowAgain = false;

  void _disableReminders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reminders_enabled', false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('リマインダー通知の許可'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('お気に入り企画のリマインダー通知がオンになっています。\nこの通知を受信するには、以下の権限が必要です。'),
            const SizedBox(height: 16),

            if (!widget.permissionsStatus.isNotificationGranted)
              _buildPermissionRow(
                '通知の許可',
                () => openAppSettings(),
              ),

            if (!widget.permissionsStatus.isExactAlarmGranted)
              _buildPermissionRow(
                'アラームとリマインダー',
                () => Permission.scheduleExactAlarm.request(),
              ),

            const Divider(height: 24),

            CheckboxListTile(
              title: const Text(
                'リマインダーをオフにし、今後この案内を表示しない',
                style: TextStyle(fontSize: 14),
              ),
              value: _dontShowAgain,
              onChanged: (value) =>
                  setState(() => _dontShowAgain = value ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text('閉じる'),
          onPressed: () {
            if (_dontShowAgain) {
              _disableReminders();
            }
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  Widget _buildPermissionRow(String title, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          ElevatedButton(onPressed: onPressed, child: const Text('設定する')),
        ],
      ),
    );
  }
}
