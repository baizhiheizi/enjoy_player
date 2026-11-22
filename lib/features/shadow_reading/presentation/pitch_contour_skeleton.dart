/// Loading placeholder for the pitch contour chart area.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'pitch_contour_chart.dart';

/// Placeholder footprint matching [PitchContourChart] height band.
class PitchContourChartSkeleton extends StatelessWidget {
  const PitchContourChartSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(
      context,
    ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6);
    return SizedBox(
      height: 160,
      width: double.infinity,
      child: CustomPaint(painter: PitchContourSkeletonPainter(baseColor: base)),
    );
  }
}

/// Deterministic bars and sine stroke drawn by [PitchContourChartSkeleton].
class PitchContourSkeletonPainter extends CustomPainter {
  PitchContourSkeletonPainter({required this.baseColor});

  final Color baseColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = baseColor;
    const n = 44;
    final barW = size.width / n;
    final rnd = math.Random(42);
    for (var i = 0; i < n; i++) {
      final h = barW * (0.45 + rnd.nextDouble() * 1.1);
      final x = i * barW + barW * 0.12;
      final top = size.height * 0.52 + (size.height * 0.42 - h);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, top, barW * 0.76, h),
          const Radius.circular(2),
        ),
        paint,
      );
    }
    final linePaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final path = Path();
    const steps = 48;
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final x = t * size.width;
      final y =
          size.height * 0.26 + math.sin(t * math.pi * 5) * size.height * 0.09;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant PitchContourSkeletonPainter oldDelegate) =>
      oldDelegate.baseColor != baseColor;
}
