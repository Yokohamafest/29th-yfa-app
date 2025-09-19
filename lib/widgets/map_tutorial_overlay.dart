import 'package:flutter/material.dart';

class MapTutorialOverlay extends StatefulWidget {
  final VoidCallback onDismiss;

  const MapTutorialOverlay({super.key, required this.onDismiss});

  @override
  State<MapTutorialOverlay> createState() => _MapTutorialOverlayState();
}

class _MapTutorialOverlayState extends State<MapTutorialOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: GestureDetector(
        onTap: widget.onDismiss,
        child: Container(
          color: Colors.black.withAlpha(179),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final imageWidth = constraints.maxWidth * 0.45;
                    return Image.asset(
                      'assets/images/pinch_gesture.png',
                      width: imageWidth,
                      fit: BoxFit.contain,
                    );
                  },
                ),
                const SizedBox(height: 20),
                const Text(
                  '2本指でマップを\n拡大・縮小できます',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 40),
                Text(
                  '(画面をタップして閉じる)',
                  style: TextStyle(
                    color: Colors.white.withAlpha(204),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}