import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_app_yfa/models/announcement_item.dart';
import 'announcement_screen.dart';
import 'options_screen.dart';
import 'event_detail_screen.dart';
import '../models/event_item.dart';
import 'announcement_detail_screen.dart';
import '../models/spotlight_item.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/data_service.dart';

class HomeScreen extends StatefulWidget {
  final Set<String> favoriteEventIds;
  final Function(String) onToggleFavorite;
  final Function(String) onNavigateToMap;
  final Function(int) changeTab;

  const HomeScreen({
    super.key,
    required this.favoriteEventIds,
    required this.onToggleFavorite,
    required this.onNavigateToMap,
    required this.changeTab,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final DataService _dataService = DataService();
  late Future<List<dynamic>> _homeDataFuture; // 複数のデータをまとめて扱う

  AnimationController? _slideInController;
  late final AnimationController _rockingController;
  Animation<double>? _xAnimation;
  bool _isAnimationInitialized = false;

  static const int _initialPage = 5000;
  late final PageController _pageController;
  Timer? _autoPlayTimer;

  @override
  void initState() {
    super.initState();

    _homeDataFuture = Future.wait([
      _dataService.getAnnouncements(),
      _dataService.getSpotlights(),
      _dataService.getEvents(),
    ]);

    _rockingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _pageController = PageController(
      viewportFraction: 0.85,
      initialPage: _initialPage,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _initSlideAnimation());
    _startAutoPlay();
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

  void _startAutoPlay() {
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted || !_pageController.hasClients) return;
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _slideInController?.dispose();
    _rockingController.dispose();
    _pageController.dispose();
    _autoPlayTimer?.cancel();
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
        _xAnimation = Tween<double>(begin: -200.0, end: 20.0).animate(
          CurvedAnimation(parent: _slideInController!, curve: Curves.easeOut),
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
              decoration: BoxDecoration(color: Color(0xFF54A4DB)),
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

          FutureBuilder<List<dynamic>>(
            future: _homeDataFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Positioned.fill(
                  top: 420,
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                );
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return const Positioned.fill(
                  top: 420,
                  child: Center(
                    child: Text(
                      '情報を読み込めませんでした',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                );
              }

              final announcements = snapshot.data![0] as List<AnnouncementItem>;
              final spotlights = snapshot.data![1] as List<SpotlightItem>;
              final allEvents = snapshot.data![2] as List<EventItem>;

              return SingleChildScrollView(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        SizedBox(height: 420),

                        Container(
                          height: 250, //screenHeight * 0.4,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFF54A4DB), Colors.white],
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
                          left: screenWidth * 0.55,
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
                            _buildAnnouncementsSection(context, announcements),
                            const SizedBox(height: 32),
                            _buildSpotlightCarousel(context, spotlights, allEvents),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
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

  Widget _buildAnnouncementsSection(BuildContext context, List<AnnouncementItem> announcements) {
    final latestAnnouncements = (List.of(
      announcements,
    )..sort((a, b) => b.publishedAt.compareTo(a.publishedAt))).take(3);

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

  Widget _buildSpotlightCarousel(BuildContext context, List<SpotlightItem> spotlights, List<EventItem> allEvents) {
    final visibleSpotlights = spotlights.where((s) => s.isVisible).toList();

    if (visibleSpotlights.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        const Text(
          '注目企画',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: (MediaQuery.of(context).size.width * 0.9) * 9 / 16,
          child: PageView.builder(
            controller: _pageController,
            itemCount: 10000,
            onPageChanged: (page) {
              setState(() {});
            },
            itemBuilder: (context, index) {
              // 本当のインデックスを計算
              final realIndex = index % visibleSpotlights.length;
              final spotlight = visibleSpotlights[realIndex];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8.0),
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: InkWell(
                  onTap: () async {
                    if (spotlight.actionType == SpotlightActionType.event) {
                      final String eventId = spotlight.actionValue;
                      EventItem? targetEvent;
                      try {
                        targetEvent = allEvents.firstWhere(
                          (e) => e.id == eventId,
                        );
                      } catch (e) {
                        targetEvent = null;
                      }
                      if (targetEvent != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EventDetailScreen(
                              event: targetEvent!,
                              favoriteEventIds: widget.favoriteEventIds,
                              onToggleFavorite: widget.onToggleFavorite,
                              onNavigateToMap: widget.onNavigateToMap,
                            ),
                          ),
                        );
                      }
                    } else if (spotlight.actionType ==
                        SpotlightActionType.url) {
                      final url = Uri.parse(spotlight.actionValue);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url);
                      }
                    }
                  },
                  child: Image.asset(
                    spotlight.imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(child: Text('画像読込エラー'));
                    },
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
