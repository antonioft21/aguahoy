import 'dart:math';
import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../../core/theme.dart';

class ProgressCircle extends StatefulWidget {
  final double progress;
  final bool goalMet;

  const ProgressCircle({
    super.key,
    required this.progress,
    required this.goalMet,
  });

  @override
  State<ProgressCircle> createState() => _ProgressCircleState();
}

class _ProgressCircleState extends State<ProgressCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.goalMet ? AguaTheme.successGreen : Theme.of(context).colorScheme.primary;

    return CircularPercentIndicator(
      radius: 110,
      lineWidth: 14,
      percent: widget.progress,
      animation: true,
      animateFromLastPercent: true,
      animationDuration: 400,
      circularStrokeCap: CircularStrokeCap.round,
      progressColor: color,
      backgroundColor:
          Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.15),
      center: SizedBox(
        width: 180,
        height: 180,
        child: AnimatedBuilder(
          animation: _waveController,
          builder: (context, child) {
            return ClipOval(
              child: CustomPaint(
                painter: _WavePainter(
                  progress: widget.progress,
                  wavePhase: _waveController.value,
                  color: color,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                ),
                child: child,
              ),
            );
          },
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.goalMet ? Icons.check_circle : Icons.water_drop,
                  size: 44,
                  color: widget.progress > 0.55 ? Colors.white : color,
                ),
                const SizedBox(height: 6),
                Text(
                  '${(widget.progress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: widget.progress > 0.45 ? Colors.white : color,
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

class _WavePainter extends CustomPainter {
  final double progress;
  final double wavePhase;
  final Color color;
  final Color backgroundColor;

  _WavePainter({
    required this.progress,
    required this.wavePhase,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final w = size.width;
    final h = size.height;

    // Water level: 0% = bottom, 100% = top
    final waterLevel = h * (1.0 - progress);

    // Wave parameters
    final waveHeight = progress >= 1.0 ? 0.0 : 6.0;
    final phase = wavePhase * 2 * pi;

    // Draw first wave (darker)
    final wavePaint = Paint()..color = color.withValues(alpha: 0.3);
    final wavePath = Path();
    wavePath.moveTo(0, h);
    for (var x = 0.0; x <= w; x += 1) {
      final y = waterLevel +
          sin((x / w) * 2 * pi + phase) * waveHeight +
          cos((x / w) * 3 * pi + phase * 0.8) * waveHeight * 0.5;
      wavePath.lineTo(x, y);
    }
    wavePath.lineTo(w, h);
    wavePath.close();
    canvas.drawPath(wavePath, wavePaint);

    // Draw second wave (main color, slightly offset)
    final wavePaint2 = Paint()..color = color.withValues(alpha: 0.5);
    final wavePath2 = Path();
    wavePath2.moveTo(0, h);
    for (var x = 0.0; x <= w; x += 1) {
      final y = waterLevel +
          sin((x / w) * 2 * pi + phase + pi * 0.7) * waveHeight * 0.8 +
          cos((x / w) * 2.5 * pi + phase * 1.2) * waveHeight * 0.4;
      wavePath2.lineTo(x, y);
    }
    wavePath2.lineTo(w, h);
    wavePath2.close();
    canvas.drawPath(wavePath2, wavePaint2);
  }

  @override
  bool shouldRepaint(_WavePainter oldDelegate) =>
      oldDelegate.wavePhase != wavePhase ||
      oldDelegate.progress != progress ||
      oldDelegate.color != color;
}
