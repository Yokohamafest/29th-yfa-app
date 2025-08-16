import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class GeneralNotificationPermissionDialog extends StatelessWidget {
  const GeneralNotificationPermissionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('通知の許可'),
      content: const SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('運営からの重要なお知らせを受信するには、アプリの通知を許可してください。'),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text('あとで'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElevatedButton(
          child: const Text('設定を開く'),
          onPressed: () {
            openAppSettings();
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}