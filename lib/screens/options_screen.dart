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

  bool _generalNotificationsEnabled = true; // お知らせ通知の受け取りの状態を管理する変数

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

  // URLをブラウザで開くための関数
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      //【修正点】awaitの後に、mountedプロパティで生存確認を追加
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$urlString を開けませんでした')));
    }
  }

  // キャッシュをクリアする関数
  void _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('データの初期化'),
        content: const Text('お気に入りや既読の情報など、保存されたデータがすべてリセットされます。よろしいですか？'),
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

    //【修正点】awaitの後に、mountedプロパティで生存確認を追加
    if (confirmed == true && mounted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (!mounted) return; // ここでも再度チェック
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('データをリセットしました。アプリを再起動してください。')),
      );
    }
  }

  // 運営からのお知らせ通知設定を読み込む関数
  Future<void> _loadGeneralNotificationSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // 'general_notifications_enabled'キーで保存された値があればそれを、なければtrueをデフォルト値とする
      _generalNotificationsEnabled =
          prefs.getBool('general_notifications_enabled') ?? true;
    });
  }

  // 運営からのお知らせ通知設定を保存する関数
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
      appBar: AppBar(title: const Text('オプション')),
      body: ListView(
        children: [
          // --- 通知設定 ---
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

          // 共通ウィジェットとして作成した通知設定をここに配置
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
            subtitle: const Text('お気に入りや既読の情報をリセットします'),
            onTap: _clearCache,
          ),
          const Divider(),

          // --- 情報・サポート ---
          const ListTile(
            title: Text(
              '情報・サポート',
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('このアプリについて'),
            subtitle: Text(_appVersion), // 読み込んだバージョン情報を表示
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
