/// Aurora progress ring painter — one ring for every signature countdown /
/// progress dial (ADR-0089 §2).
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

/// Minimum second stop for the sweep gradient: a near-zero arc would put the
/// two stops almost on top of each other, rendering a hard color step instead
/// of a gradient across the short arc.
const double _kMinArcGradientStop = 0.02;

/// Circular ring: a track circle plus a clockwise progress arc starting at
/// 12 o'clock, stroked with round caps. The arc is either a solid color
/// ([progressColor]) or a sweep gradient ([gradientColors], e.g. the aurora),
/// whose second stop tracks the arc's own sweep so the gradient lands along
/// the lit portion.
///
/// Surfaces: the Today's Goal card (aurora gradient) and the shadow-reading
/// record FAB (solid countdown arc). Counting down is the caller's choice —
/// pass the *remaining* fraction as [progress].
class EnjoyProgressRingPainter extends CustomPainter {
  EnjoyProgressRingPainter({
    required this.progress,
    required this.trackColor,
    required this.strokeWidth,
    this.progressColor,
    this.gradientColors,
  }) : assert(
         (progressColor == null) != (gradientColors == null),
         'Provide exactly one of progressColor or gradientColors.',
       ),
       _trackPaint = Paint()
         ..color = trackColor
         ..style = PaintingStyle.stroke
         ..strokeWidth = strokeWidth
         ..strokeCap = StrokeCap.round,
       _arcPaint = Paint()
         ..style = PaintingStyle.stroke
         ..strokeWidth = strokeWidth
         ..strokeCap = StrokeCap.round;

  final double progress;
  final Color trackColor;
  final double strokeWidth;
  final Color? progressColor;
  final List<Color>? gradientColors;
  final Paint _trackPaint;
  final Paint _arcPaint;

  static void paintRing(
    Canvas canvas,
    Size size, {
    required double progress,
    required double strokeWidth,
    required Paint trackPaint,
    required Paint arcPaint,
    Color? progressColor,
    List<Color>? gradientColors,
  }) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(center, radius, trackPaint);

    final fraction = progress.clamp(0.0, 1.0);
    if (fraction <= 0) return;
    final sweep = 2 * math.pi * fraction;
    if (gradientColors != null) {
      arcPaint.color = const Color(0xFFFFFFFF);
      arcPaint.shader = SweepGradient(
        colors: gradientColors,
        stops: [0, math.max(fraction, _kMinArcGradientStop)],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(rect);
    } else {
      arcPaint.shader = null;
      arcPaint.color = progressColor!;
    }
    canvas.drawArc(rect, -math.pi / 2, sweep, false, arcPaint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    paintRing(
      canvas,
      size,
      progress: progress,
      strokeWidth: strokeWidth,
      trackPaint: _trackPaint,
      arcPaint: _arcPaint,
      progressColor: progressColor,
      gradientColors: gradientColors,
    );
  }

  @override
  bool shouldRepaint(covariant EnjoyProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.progressColor != progressColor ||
        !listEquals(oldDelegate.gradientColors, gradientColors);
  }
}
