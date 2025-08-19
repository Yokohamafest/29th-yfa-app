import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import '../main_scaffold.dart';
import '../services/data_service.dart';
import '../firebase_options.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      print("1. _initialize() 開始");

      WidgetsFlutterBinding.ensureInitialized();
      print("2. Binding 初期化完了");

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print("3. Firebase.initializeApp() 完了");

      await DataService().registerDeviceToken();
      print("4. registerDeviceToken() 完了");

      await Future.delayed(const Duration(milliseconds: 500));
      print("5. 遅延完了");

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScaffold()),
        );
        print("6. メイン画面へ遷移");
      }
    } catch (e) {
      print("!!!!! 初期化処理中にエラーが発生しました !!!!!");
      print(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
