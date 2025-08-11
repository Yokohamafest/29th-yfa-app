import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/favorite_notification_settings.dart';

class OptionsScreen extends StatefulWidget {
  const OptionsScreen({super.key});

  @override
  State<OptionsScreen> createState() => _OptionsScreenState();
}

class _OptionsScreenState extends State<OptionsScreen> {
  String _appVersion = '';

  bool _generalNotificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
    _loadGeneralNotificationSetting();
  }

  // アプリのバージョン情報を読み込む
  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = 'バージョン ${packageInfo.version} (${packageInfo.buildNumber})';
    });
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$urlString を開けませんでした')));
    }
  }

  void _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('データの初期化'),
        content: const Text('お気に入りや既読の情報など、保存されたデータがすべてリセットされます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('リセット'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('データをリセットしました。アプリを再起動してください。')),
      );
    }
  }

  Future<void> _loadGeneralNotificationSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _generalNotificationsEnabled =
          prefs.getBool('general_notifications_enabled') ?? true;
    });
  }

  Future<void> _updateGeneralNotificationSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('general_notifications_enabled', value);
    setState(() {
      _generalNotificationsEnabled = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'オプション',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color.fromARGB(255, 84, 164, 219),
        foregroundColor: Colors.white,
      ),

      body: ListView(
        children: [
          const ListTile(
            title: Text(
              '通知設定',
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
            ),
          ),

          SwitchListTile(
            title: const Text('運営からのお知らせ通知'),
            subtitle: const Text('企画の中止や変更など、重要なお知らせを受け取ります'),
            value: _generalNotificationsEnabled,
            onChanged: _updateGeneralNotificationSetting,
          ),

          const FavoriteNotificationSettings(),
          const Divider(),

          // --- データ管理 ---
          const ListTile(
            title: Text(
              'データ管理',
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('キャッシュをクリアする'),
            subtitle: const Text('お気に入りや既読の情報をリセットする。\n（デバッグ用のため、削除予定）'),
            onTap: _clearCache,
          ),
          const Divider(),

          const ListTile(
            title: Text(
              '情報・サポート',
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('このアプリについて'),
            subtitle: Text(_appVersion),
            onTap: () {
              // TODO: アプリのクレジットなどを表示するダイアログ
            },
          ),
          ListTile(
            leading: const Icon(Icons.public),
            title: const Text('横浜祭公式サイト'),
            onTap: () => _launchURL('https://yokohama-fest.net/29th'),
          ),
          ListTile(
            leading: const Icon(Icons.feedback_outlined),
            title: const Text('お問い合わせ'),
            onTap: () => _launchURL('https://yokohama-fest.net/29th/form'),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('プライバシーポリシー'),
            onTap: () => _launchURL(
              'https://yokohama-fest.net/29th',
            ), // TODO: プライバシーポリシーのURLに要変更
          ),
        ],
      ),
    );
  }
}
