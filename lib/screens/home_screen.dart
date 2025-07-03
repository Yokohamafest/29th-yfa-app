import 'dart:math' as math; // 数学的な計算（sin関数）を使うためにインポート
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // 2つのAnimationController
  late final AnimationController _slideInController; // スライドイン用
  late final AnimationController _rockingController; // 揺れ用

  late final Animation<double> _xAnimation;

  bool _isAnimationInitialized = false;

  @override
  void initState() {
    super.initState();

    // 画面サイズに依存しないアニメーションはここで初期化してOK
    _rockingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // アニメーションがまだ初期化されていなければ実行する
    // このフラグチェックにより、処理が一度しか実行されないことを保証する
    if (!_isAnimationInitialized) {
      // 画面サイズを取得
      final screenWidth = MediaQuery.of(context).size.width;

      // --- スライドイン用アニメーションの準備 ---
      _slideInController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 2),
      );

      // 取得した画面幅を使ってTweenの値を設定
      _xAnimation =
          Tween<double>(
            begin: screenWidth * 1.5,
            end: screenWidth * 0.475,
          ).animate(
            CurvedAnimation(parent: _slideInController, curve: Curves.easeOut),
          );

      _slideInController.forward();

      // 初期化が完了したことをマーク
      _isAnimationInitialized = true;
    }
  }
  /*
  @override
  void initState() {
    super.initState();
    final screenWidth = MediaQuery.of(context).size.width;

    // --- スライドイン用アニメーションの準備 ---
    _slideInController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _xAnimation = Tween<double>(begin: screenWidth * -0.5, end: screenWidth * 0.15/*-200.0, end: 20.0*/).animate(
      CurvedAnimation(parent: _slideInController, curve: Curves.easeOut),
    );
    _slideInController.forward(); // スライドインを開始

    // --- 揺れ用アニメーションの準備 ---
    _rockingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4), // 3秒かけて1往復する
    )..repeat(reverse: true); // 常にアニメーションを再生＆反転を繰り返す
  }
*/

  @override
  void dispose() {
    // 両方のコントローラーを破棄する
    _slideInController.dispose();
    _rockingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Container(
                  color: const Color.fromARGB(255, 15, 114, 175),
                ),
              ),
            ],
          ),

          SingleChildScrollView(
            child: Column(
              children: [
                // 画面上部のエリア
                Stack(
                  children: [
                    SizedBox(
                      height: screenHeight, // ヘッダーの高さ
                    ),

                    // 背景色（上半分）
                    Container(
                      height: 250, //screenHeight * 0.4,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          // グラデーションの開始位置
                          begin: Alignment.topCenter,
                          // グラデーションの終了位置
                          end: Alignment.bottomCenter,
                          // グラデーションで使用する色のリスト
                          colors: [
                            Color(0xFF54A4DB), // 上側の色
                            Colors.white, // 下側の色
                          ],
                        ),
                      ),
                    ),

                    //背景色（中間）
                    Positioned(
                      top: 250, //screenHeight * 0.4,
                      left: 0,
                      right: 0,
                      height: 50, //screenHeight * 0.1,
                      child: Container(color: Colors.white),
                    ),

                    /*
                    // 背景色（下半分）
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: screenHeight * 0.5,
                      child: Container(
                        color: const Color.fromARGB(255, 15, 114, 175),
                      ),
                    ),
*/

                    // ロゴやタイトル（ヘッダーエリア内の絶対位置に配置）
                    Positioned(
                      top: 100, //screenHeight * 0.15,
                      left: screenWidth * 0.55,
                      //right: screenWidth * 0.05,
                      child: Image.asset(
                        'assets/images/title.png',
                        //height: screenHeight * 0.22,
                        width: 150,
                      ),
                    ),
                    Positioned(
                      top: 0,
                      //left: 0,
                      right: screenWidth * 0.05,
                      child: Image.asset(
                        'assets/images/voyage_logo.png',
                        width: 150,
                        //height: screenHeight * 0.2,
                      ),
                    ),

                    // 船のアニメーション（ヘッダーエリア内の絶対位置に配置）
                    AnimatedBuilder(
                      animation: _slideInController,
                      builder: (context, slideInChild) {
                        return Positioned(
                          right: _xAnimation.value,
                          top: 140, //screenHeight * 0.19,
                          child: slideInChild!,
                        );
                      },
                      child: AnimatedBuilder(
                        animation: _rockingController,
                        builder: (context, rockingChild) {
                          final rockingValue = math.sin(
                            _rockingController.value * 2 * math.pi,
                          );
                          return Transform(
                            transform: Matrix4.translationValues(
                              0,
                              rockingValue * 5,
                              0,
                            )..rotateZ(rockingValue * 0.05),
                            alignment: Alignment.center,
                            child: rockingChild,
                          );
                        },
                        child: Image.asset(
                          'assets/images/ship.png',
                          //height: screenHeight * 0.27,
                          width: 180,
                        ),
                      ),
                    ),

                    // 波の画像
                    Positioned(
                      top: 275,
                      //bottom: screenHeight * 0.5,
                      left: 0,
                      right: 0,
                      child: Image.asset(
                        'assets/images/wave.gif',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ),
                //　ここまでが画面上部のエリア

                //　ここから下にコンテンツを追加予定
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 24.0,
                  ),
                  child: Column(
                    children: [
                      _buildContentCard(
                        title: '重要なお知らせ',
                        content: '・〇〇は雨天のため中止となりました。\n・落とし物のお知らせです。',
                      ),
                      const SizedBox(height: 20),
                      _buildContentCard(
                        title: '注目企画',
                        content:
                            '・13:00〜 お笑いライブ @メインステージ\n・15:00〜 バンド演奏 @第一体育館',
                      ),
                      const SizedBox(height: 20),
                      _buildContentCard(title: 'コンテンツ3', content: '内容'),
                      const SizedBox(height: 20),
                      _buildContentCard(title: 'コンテンツ4', content: '内容'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // コンテンツカードを生成するメソッド
  Widget _buildContentCard({required String title, required String content}) {
    return Card(
      elevation: 4.0, // 影の離れ具合
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(content),
          ],
        ),
      ),
    );
  }
}
