import 'dart:math';
import 'package:flutter/material.dart';

class SpeedGaugeView extends StatefulWidget {
  final double speed;
  final String unit;
  final double maxSpeed;

  const SpeedGaugeView({
    super.key,
    required this.speed,
    required this.unit,
    required this.maxSpeed,
  });

  @override
  State<SpeedGaugeView> createState() => _SpeedGaugeViewState();
}

class _SpeedGaugeViewState extends State<SpeedGaugeView> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _oldProgress = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
  }

  @override
  void didUpdateWidget(covariant SpeedGaugeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.speed != widget.speed || oldWidget.maxSpeed != widget.maxSpeed) {
      double newProgress = (widget.speed / widget.maxSpeed).clamp(0.0, 1.0);
      _animation = Tween<double>(begin: _oldProgress, end: newProgress).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller.forward(from: 0);
      _oldProgress = newProgress;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _gaugeColor {
    // Current value of animation
    double val = _animation.value;
    if (val >= 0.8) return Colors.green;
    if (val >= 0.5) return Colors.yellow;
    if (val >= 0.2) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Column(
          children: [
            SizedBox(
              width: 160,
              height: 160,
              child: CustomPaint(
                painter: _GaugePainter(
                  progress: _animation.value,
                  color: _gaugeColor,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.speed.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.unit,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final Color color;

  _GaugePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 10;
    const strokeWidth = 12.0;

    // Background Arc
    // Start from 135 degrees (3pi/4) to 45 degrees (pi/4) going clockwise?
    // Swift: trim 0.15 to 0.85. 0.0 is 3 o'clock.
    // 0.15 * 360 = 54 deg. 0.85 * 360 = 306 deg.
    // Rotated 90 deg -> +90.
    // Start: 54 + 90 = 144 deg. End: 306 + 90 = 396 (36 deg).
    // Total sweep: 306 - 54 = 252 degrees.
    // 144 degrees is roughly 4 o'clock? No 180 is 9 o'clock.
    // 0 is 3 o'clock. 90 is 6 o'clock. 180 is 9 o'clock. 270 is 12 o'clock.
    // Let's use standard gauge angles: 135 to 405 (270 degrees sweep), opening at bottom.
    
    const startAngle = 135.0 * pi / 180.0;
    const sweepAngle = 270.0 * pi / 180.0;

    final bgPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    // Foreground Arc
    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    // Add shadow
    final shadowPaint = Paint()
      ..color = color.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    
    final currentSweep = sweepAngle * progress;

    if (progress > 0) {
       canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        currentSweep,
        false,
        shadowPaint,
      );

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        currentSweep,
        false,
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
