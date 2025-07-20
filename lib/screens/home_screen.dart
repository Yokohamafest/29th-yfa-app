import 'dart:math' as math; // 数学的な計算（sin関数）を使うためにインポート
import 'package:flutter/material.dart';
import 'announcement_screen.dart';
import 'options_screen.dart';
import '../data/dummy_events.dart';
import '../models/event_item.dart';
import '../widgets/event_card.dart';
import '../data/dummy_announcements.dart';
import 'announcement_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final Set<String> favoriteEventIds;
  final Function(String) onToggleFavorite;
  final Function(String) onNavigateToMap;

  const HomeScreen({
    super.key,
    required this.favoriteEventIds,
    required this.onToggleFavorite,
    required this.onNavigateToMap,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
   AnimationController? _slideInController; // スライドイン用
  late final AnimationController _rockingController; // 揺れ用
  Animation<double>? _xAnimation;
  bool _isAnimationInitialized = false;
  bool _isMenuOpen = false;
  List<EventItem> _recommendedEvents = [];

  // メニューの開閉を切り替える関数
  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
    });
  }

  @override
  void initState() {
    super.initState();

    // 画面サイズに依存しないアニメーションはここで初期化
    _rockingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _selectRecommendedEvents();

    WidgetsBinding.instance.addPostFrameCallback((_) => _initSlideAnimation());
  }

  void _initSlideAnimation() {
    // この関数が呼ばれる時点ではcontextは有効
    if (!mounted) return;
    //final screenWidth = MediaQuery.of(context).size.width;

    _slideInController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _xAnimation = Tween<double>(
      begin: -200.0,
      end: 20.0,
    ).animate(
      //【修正点①】_slideInControllerがnullでないことを'!'で保証
      CurvedAnimation(parent: _slideInController!, curve: Curves.easeOut),
    );
    //【修正点②】_slideInControllerがnullでないことを'!'で保証
    _slideInController!.forward();

    // 初期化が完了したことを画面に通知するためにsetStateを呼ぶ
    if (mounted) {
      setState(() {});
    }
  }


  void _selectRecommendedEvents() {
    // 企画一覧に表示される企画のみを抽出
    final allEvents = dummyEvents
        .where((event) => !event.hideFromList)
        .toList();
    // リストをシャッフル
    allEvents.shuffle();
    // 先頭から3つを取得
    setState(() {
      _recommendedEvents = allEvents.take(3).toList();
    });
  }

  @override
  void dispose() {
    // 両方のコントローラーを破棄する
    _slideInController?.dispose();
    _rockingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    const double menuWidth = 250; // サイドメニューの幅を定義

    if (!_isAnimationInitialized) {
      _isAnimationInitialized = true;
      // このコールバックは、最初のフレームが描画された直後に一度だけ実行される
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // このタイミングなら、screenWidthは常に正しい値
        _slideInController = AnimationController(
          vsync: this,
          duration: const Duration(seconds: 2),
        );
        _xAnimation = Tween<double>(
          begin: -200.0, // 画面の左外側からスタート
          end: 20.0,     // 最終的に停止する左からの位置
        ).animate(
        CurvedAnimation(parent: _slideInController!, curve: Curves.easeOut),
        );
        // buildメソッドが完了した後にアニメーションを開始
        _slideInController!.forward();
      });
    }



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
                      height: 420, // ヘッダーの高さ
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
                    if (_slideInController != null && _xAnimation != null)
                      AnimatedBuilder(
                        animation: _slideInController!, // non-nullであることを保証
                        builder: (context, slideInChild) {
                          return Positioned(
                            left: _xAnimation!.value,
                            top: 140,
                            child: slideInChild!,
                          );
                        },
                        child: AnimatedBuilder(
                        animation: _rockingController,
                        builder: (context, rockingChild) {
                          final rockingValue = math.sin(_rockingController.value * 2 * math.pi);
                          return Transform(
                            transform: Matrix4.translationValues(0, rockingValue * 5, 0)
                              ..rotateZ(rockingValue * 0.05),
                            alignment: Alignment.center,
                            child: rockingChild,
                          );
                        },
                        child: Image.asset('assets/images/ship.png', width: 180),
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
                // ここまでが画面上部のエリア

                // ここから下にコンテンツを追加予定
                Container(
                  color: const Color.fromARGB(255, 15, 114, 175),
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 24.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ① 最新のお知らせセクション
                        _buildAnnouncementsSection(context),
                        const SizedBox(height: 32),
                        // ② おすすめ企画セクション
                        _buildRecommendationsSection(context),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          AnimatedPositioned(
            duration: const Duration(milliseconds: 300), // アニメーションの時間
            curve: Curves.easeInOut, // アニメーションの緩急
            // _isMenuOpenの値に応じて、leftの位置を変更する
            left: _isMenuOpen ? 0 : -menuWidth, // 開いている時は0、閉じている時は画面外
            top: 0,
            height: 300,
            width: menuWidth,
            child: Material(
              // 影や背景色をつけるためにMaterialで囲む
              elevation: 8.0,
              borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(12.0),
              ),
              clipBehavior: Clip.antiAlias,
              child: Container(
                color: Colors.white,
                child: SafeArea(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      const Text(
                        'メニュー',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(height: 40),
                      ListTile(
                        leading: const Icon(Icons.campaign),
                        title: const Text('お知らせ'),
                        onTap: () {
                          // お知らせ一覧画面へ遷移
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AnnouncementScreen(),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.settings),
                        title: const Text('オプション'),
                        onTap: () {
                          // オプション画面へ遷移
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const OptionsScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // --- レイヤー3: メニューを開くためのボタン ---
          Positioned(
            top: 40, // 位置を微調整
            left: 0, // 画面の左端にピッタリつける
            child: Material(
              // ボタンに影をつける
              elevation: _isMenuOpen ? 0.0 : 4.0,
              // ボタンの背景色
              color: Colors.white,
              // 【重要】ボタンの形を定義
              shape: const RoundedRectangleBorder(
                // 右上と右下だけを角丸にする
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              // ボタンを押したときのエフェクトが、上記の形からはみ出ないようにする
              clipBehavior: Clip.antiAlias,
              child: IconButton(
                icon: Icon(_isMenuOpen ? Icons.close : Icons.menu),
                iconSize: 30,
                color: const Color.fromARGB(255, 15, 114, 175),
                tooltip: 'メニューを開く',
                onPressed: _toggleMenu,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // コンテンツカードを生成するメソッド 文字情報を追加する場合はこれを使える
  /*
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
  */

  // 最新のお知らせセクションを生成するメソッド
  Widget _buildAnnouncementsSection(BuildContext context) {
    // お知らせを公開日時が新しい順にソートし、先頭3件を取得
    final latestAnnouncements = (List.of(
      dummyAnnouncements,
    )..sort((a, b) => b.publishedAt.compareTo(a.publishedAt))).take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '最新のお知らせ',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              // 取得した3件のお知らせをリスト表示
              ...latestAnnouncements.map((announcement) {
                return ListTile(
                  title: Text(
                    announcement.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AnnouncementDetailScreen(
                          announcement: announcement,
                        ),
                      ),
                    );
                  },
                );
              }),
              const Divider(height: 1),
              // お知らせ一覧画面へのリンク
              ListTile(
                title: const Text(
                  'お知らせ一覧',
                  style: TextStyle(color: Colors.blue),
                ),
                trailing: const Icon(Icons.arrow_forward, color: Colors.blue),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AnnouncementScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // おすすめ企画セクションを生成するメソッド
  Widget _buildRecommendationsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'おすすめ企画',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        // initStateで選ばれた3つの企画のカードを表示
        ..._recommendedEvents.map(
          (event) => EventCard(
            event: event,
            favoriteEventIds: widget.favoriteEventIds,
            onToggleFavorite: widget.onToggleFavorite,
            onNavigateToMap: widget.onNavigateToMap,
          ),
        ),
      ],
    );
  }
}
