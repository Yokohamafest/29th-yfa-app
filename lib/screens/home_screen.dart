import 'dart:math' as math;
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
  AnimationController? _slideInController;
  late final AnimationController _rockingController;
  Animation<double>? _xAnimation;
  bool _isAnimationInitialized = false;
  List<EventItem> _recommendedEvents = [];

  @override
  void initState() {
    super.initState();

    _rockingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _selectRecommendedEvents();

    WidgetsBinding.instance.addPostFrameCallback((_) => _initSlideAnimation());
  }

  void _initSlideAnimation() {
    if (!mounted) return;

    _slideInController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _xAnimation = Tween<double>(begin: -200.0, end: 20.0).animate(
      CurvedAnimation(parent: _slideInController!, curve: Curves.easeOut),
    );
    _slideInController!.forward();

    if (mounted) {
      setState(() {});
    }
  }

  void _selectRecommendedEvents() {
    final allEvents = dummyEvents
        .where((event) => !event.hideFromList)
        .toList();
    allEvents.shuffle();
    setState(() {
      _recommendedEvents = allEvents.take(3).toList();
    });
  }

  @override
  void dispose() {
    _slideInController?.dispose();
    _rockingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (!_isAnimationInitialized) {
      _isAnimationInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _slideInController = AnimationController(
          vsync: this,
          duration: const Duration(seconds: 2),
        );
        _xAnimation =
            Tween<double>(
              begin: -200.0,
              end: 20.0,
            ).animate(
              CurvedAnimation(
                parent: _slideInController!,
                curve: Curves.easeOut,
              ),
            );
        _slideInController!.forward();
      });
    }

    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Color(0xFF54A4DB),
              ),
              child: Text(
                'メニュー',
                style: TextStyle(fontSize: 24, color: Colors.white),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.campaign),
              title: const Text('お知らせ'),
              onTap: () {
                Navigator.pop(context);
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
                Navigator.pop(context);
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
                Stack(
                  children: [
                    SizedBox(
                      height: 420,
                    ),

                    Container(
                      height: 250, //screenHeight * 0.4,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF54A4DB),
                            Colors.white,
                          ],
                        ),
                      ),
                    ),

                    Positioned(
                      top: 250, //screenHeight * 0.4,
                      left: 0,
                      right: 0,
                      height: 50, //screenHeight * 0.1,
                      child: Container(color: Colors.white),
                    ),

                    Positioned(
                      top: 100,
                      left: screenWidth * 0.55,
                      child: Image.asset(
                        'assets/images/title.png',
                        width: 150,
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: screenWidth * 0.05,
                      child: Image.asset(
                        'assets/images/voyage_logo.png',
                        width: 150,
                      ),
                    ),

                    if (_slideInController != null && _xAnimation != null)
                      AnimatedBuilder(
                        animation: _slideInController!,
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
                            width: 180,
                          ),
                        ),
                      ),

                    Positioned(
                      top: 275,
                      left: 0,
                      right: 0,
                      child: Image.asset(
                        'assets/images/wave.gif',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ),

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
                        _buildAnnouncementsSection(context),
                        const SizedBox(height: 32),
                        _buildRecommendationsSection(context),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            top: 45,
            left: 0,
            child: Builder(
              builder: (context) {
                return Material(
                  elevation: 4.0,
                  color: Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: IconButton(
                    icon: const Icon(Icons.menu),
                    iconSize: 30,
                    color: const Color.fromARGB(255, 15, 114, 175),
                    tooltip: 'メニューを開く',
                    onPressed: () {
                      // Drawerを開くための命令
                      Scaffold.of(context).openDrawer();
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // コンテンツカードを生成するメソッド 文字情報を追加する場合はこれを使えるかもしれない
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

  Widget _buildAnnouncementsSection(BuildContext context) {
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
