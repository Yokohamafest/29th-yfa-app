import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/services.dart';
import '../main_scaffold.dart';
import '../services/data_service.dart';
import '../firebase_options.dart';
import '../widgets/compass_loading_indicator.dart';
import '../services/notification_service.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  final NotificationService _notificationService = NotificationService();
  final ValueNotifier<double> _progressNotifier = ValueNotifier(0.0);

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _progressNotifier.dispose();
    super.dispose();
  }

  Future<void> _requestATT() async {
    final status = await AppTrackingTransparency.trackingAuthorizationStatus;
    if (status == TrackingStatus.notDetermined) {
      await AppTrackingTransparency.requestTrackingAuthorization();
    }
  }

  Future<void> _initialize() async {
    try {
      _progressNotifier.value = 0.1;
      WidgetsFlutterBinding.ensureInitialized();

      await _requestATT();

      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      await Future.delayed(const Duration(milliseconds: 200));

      await _notificationService.init();

      _progressNotifier.value = 0.3;
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await Future.delayed(const Duration(milliseconds: 200));

      _progressNotifier.value = 0.5;
      await initializeDateFormatting('ja_JP');
      await Future.delayed(const Duration(milliseconds: 300));

      _progressNotifier.value = 0.7;
      await DataService.instance.initialize();

      DataService.instance.registerDeviceToken();

      _progressNotifier.value = 1.0;
      await Future.delayed(const Duration(milliseconds: 600));

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScaffold()),
        );
      }
    } catch (e) {
      print("!!!!! 初期化処理中にエラーが発生しました !!!!!");
      print(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ValueListenableBuilder<double>(
          valueListenable: _progressNotifier,
          builder: (context, progress, child) {
            return CompassLoadingIndicator(progress: progress);
          },
        ),
      ),
    );
  }
}
