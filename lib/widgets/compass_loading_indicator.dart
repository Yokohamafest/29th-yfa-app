import 'dart:math' as math;
import 'package:flutter/material.dart';

class CompassLoadingIndicator extends StatefulWidget {
  final double progress;

  const CompassLoadingIndicator({super.key, required this.progress});

  @override
  State<CompassLoadingIndicator> createState() => _CompassLoadingIndicatorState();
}

class _CompassLoadingIndicatorState extends State<CompassLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _angleAnimation;
  double _previousAngle = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _angleAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void didUpdateWidget(covariant CompassLoadingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      final newAngle = widget.progress * 2 * math.pi;

      _angleAnimation = Tween<double>(begin: _previousAngle, end: newAngle).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
      );

      _controller.forward(from: 0.0);

      _previousAngle = newAngle;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final percentage = (widget.progress * 100).toInt();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _angleAnimation,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                Image.asset('assets/images/compass_base.png', width: 50),

                Transform.rotate(
                  angle: _angleAnimation.value,
                  child: Image.asset('assets/images/compass_needle.png', height: 40),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        Text(
          'Now Loading…\n$percentage %',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}