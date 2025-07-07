import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoriteNotificationSettings extends StatefulWidget {
  const FavoriteNotificationSettings({super.key});

  @override
  State<FavoriteNotificationSettings> createState() =>
      _FavoriteNotificationSettingsState();
}

class _FavoriteNotificationSettingsState
    extends State<FavoriteNotificationSettings> {
  bool _remindersEnabled = true;
  bool _isLoading = true;

  Map<int, bool> _reminderMinutesSettings = {
    15: true, // デフォルトで15分前をONにする
    30: false,
    60: false,
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // 保存された設定を読み込む
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _remindersEnabled = prefs.getBool('reminders_enabled') ?? true;
      // 各タイミングの設定を個別に読み込む
      _reminderMinutesSettings = {
        15: prefs.getBool('reminder_15_min_enabled') ?? true, // デフォルトは15分前のみON
        30: prefs.getBool('reminder_30_min_enabled') ?? false,
        60: prefs.getBool('reminder_60_min_enabled') ?? false,
      };
      _isLoading = false;
    });
  }

  // リマインダーのON/OFF設定を保存
  Future<void> _updateRemindersEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reminders_enabled', value);
    setState(() {
      _remindersEnabled = value;
    });
  }

  Future<void> _updateReminderMinutes(int minutes, bool isEnabled) async {
    final prefs = await SharedPreferences.getInstance();
    // 'reminder_15_min_enabled' のようなキーで個別に保存
    await prefs.setBool('reminder_${minutes}_min_enabled', isEnabled);
    setState(() {
      _reminderMinutesSettings[minutes] = isEnabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'お気に入り通知設定',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        SwitchListTile(
          title: const Text('リマインダー通知'),
          value: _remindersEnabled,
          onChanged: _updateRemindersEnabled,
        ),
        if (_remindersEnabled) ...[
          const Divider(height: 1),
          const Padding(
            padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
            child: Text(
              '通知のタイミング',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          CheckboxListTile(
            title: const Text('15分前'),
            value: _reminderMinutesSettings[15],
            onChanged: (bool? value) {
              if (value != null) _updateReminderMinutes(15, value);
            },
          ),
          CheckboxListTile(
            title: const Text('30分前'),
            value: _reminderMinutesSettings[30],
            onChanged: (bool? value) {
              if (value != null) _updateReminderMinutes(30, value);
            },
          ),
          CheckboxListTile(
            title: const Text('1時間前'),
            value: _reminderMinutesSettings[60],
            onChanged: (bool? value) {
              if (value != null) _updateReminderMinutes(60, value);
            },
          ),
        ],
        const SizedBox(height: 20),
      ],
    );
  }
}
