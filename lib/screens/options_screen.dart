import 'package:flutter/material.dart';
import 'package:flutter_app_yfa/models/info_link_item.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/favorite_reminder_settings.dart';
import '../services/data_service.dart';
import '../services/notification_service.dart';
import '../widgets/announcement_permission_dialog.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/app_colors.dart';

class OptionsScreen extends StatefulWidget {
  final VoidCallback onSettingsChanged;
  final NotificationService notificationService;

  const OptionsScreen({
    super.key,
    required this.onSettingsChanged,
    required this.notificationService,
  });

  @override
  State<OptionsScreen> createState() => _OptionsScreenState();
}

class _OptionsScreenState extends State<OptionsScreen> {
  final DataService _dataService = DataService();
  String _appVersion = '';

  bool _generalNotificationsEnabled = true;

  late Future<List<InfoLinkItem>> _infoLinksFuture;

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
    _loadGeneralNotificationSetting();
    _infoLinksFuture = _dataService.getInfoLinks();
  }

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

    if (value == true) {
      final status = await Permission.notification.status;
      if (!status.isGranted && mounted) {
        showDialog(
          context: context,
          builder: (context) => const GeneralNotificationPermissionDialog(),
        );
      }
    }
  }

  IconData _getIconForName(String name) {
    switch (name) {
      case 'public':
        return Icons.public;
      case 'feedback_outlined':
        return Icons.feedback_outlined;
      case 'privacy_tip_outlined':
        return Icons.privacy_tip_outlined;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('オプション')),

      body: ListView(
        children: [
          const ListTile(
            title: Text(
              '通知設定',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          SwitchListTile(
            title: const Text('運営からのお知らせ通知'),
            subtitle: const Text('企画の中止や変更など、重要なお知らせを受け取ります'),
            value: _generalNotificationsEnabled,
            onChanged: _updateGeneralNotificationSetting,
          ),

          FavoriteNotificationSettings(
            onSettingsChanged: widget.onSettingsChanged,
          ),
          const Divider(),

          const ListTile(
            title: Text(
              'データ管理',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
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
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('このアプリについて'),
            subtitle: Text(_appVersion),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationIcon: Image.asset(
                  'assets/icon/app_icon.png',
                  width: 50,
                  height: 50,
                ),
                applicationName: '横浜祭2025 公式アプリ',
                applicationVersion: _appVersion,

                applicationLegalese: '© 2025 横浜祭実行委員会',
                children: [
                  const SizedBox(height: 24),
                  const Text(
                    'このアプリは、第29回横浜祭をより楽しむために開発されました。',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              );
            },
          ),
          FutureBuilder<List<InfoLinkItem>>(
            future: _infoLinksFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox.shrink();
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return const ListTile(title: Text('情報を読み込めませんでした'));
              }

              final links = snapshot.data!;
              return Column(
                children: links.map((link) {
                  return ListTile(
                    leading: Icon(_getIconForName(link.iconName)),
                    title: Text(link.title),
                    onTap: () => _launchURL(link.url),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
