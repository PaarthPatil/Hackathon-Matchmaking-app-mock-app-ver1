import 'dart:math' as math;
import 'package:flutter/material.dart';

class AchievementOverlay extends StatefulWidget {
  final String title;
  final String description;
  final VoidCallback onDismiss;

  const AchievementOverlay({
    super.key,
    required this.title,
    required this.description,
    required this.onDismiss,
  });

  @override
  State<AchievementOverlay> createState() => _AchievementOverlayState();
}

class _AchievementOverlayState extends State<AchievementOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late List<ConfettiParticle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    _scaleAnimation = CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.2, curve: Curves.elasticOut));
    _particles = List.generate(50, (_) => ConfettiParticle());
    _controller.forward();
    _controller.addListener(() {
      if (_controller.value > 0.8) {
        // fade out handled by opacity
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final opacity = _controller.value < 0.2 ? 1.0 : (1.0 - (_controller.value - 0.2) / 0.8).clamp(0.0, 1.0);
        
        return Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              ..._particles.map((p) => CustomPaint(
                painter: ConfettiPainter(p, _controller.value),
                child: Container(),
              )),
              Center(
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Opacity(
                    opacity: opacity,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.withValues(alpha: 0.8), Colors.purple.withValues(alpha: 0.8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: Colors.blue.withValues(alpha: 0.4), blurRadius: 20, spreadRadius: 5),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.emoji_events, color: Colors.amber, size: 64),
                          const SizedBox(height: 16),
                          Text(
                            widget.title,
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.description,
                            style: const TextStyle(color: Colors.white70, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ConfettiParticle {
  final Color color = Color((math.Random().nextDouble() * 0xFFFFFF).toInt()).withValues(alpha: 1.0);
  final double x = math.Random().nextDouble();
  final double y = math.Random().nextDouble();
  final double size = math.Random().nextDouble() * 8 + 4;
  final double speed = math.Random().nextDouble() * 2 + 1;
}

class ConfettiPainter extends CustomPainter {
  final ConfettiParticle p;
  final double progress;

  ConfettiPainter(this.p, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = p.color;
    final currentY = (p.y + progress * p.speed) % 1.0;
    canvas.drawRect(
      Rect.fromLTWH(p.x * size.width, currentY * size.height, p.size, p.size),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
