/// Pitch + amplitude chart for echo region (web `PitchContourChart` parity, simplified).
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/echo_region_analysis.dart';

class PitchContourVisibility {
  const PitchContourVisibility({
    this.showWaveform = true,
    this.showReference = true,
    this.showUser = true,
  });

  final bool showWaveform;
  final bool showReference;
  final bool showUser;

  PitchContourVisibility copyWith({
    bool? showWaveform,
    bool? showReference,
    bool? showUser,
  }) {
    return PitchContourVisibility(
      showWaveform: showWaveform ?? this.showWaveform,
      showReference: showReference ?? this.showReference,
      showUser: showUser ?? this.showUser,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PitchContourVisibility &&
          runtimeType == other.runtimeType &&
          showWaveform == other.showWaveform &&
          showReference == other.showReference &&
          showUser == other.showUser;

  @override
  int get hashCode => Object.hash(showWaveform, showReference, showUser);
}

class PitchContourChart extends StatelessWidget {
  const PitchContourChart({
    required this.points,
    required this.referenceColor,
    required this.userColor,
    this.visibility = const PitchContourVisibility(),
    this.progress,
    super.key,
  });

  final List<EchoRegionSeriesPoint> points;
  final Color referenceColor;
  final Color userColor;
  final PitchContourVisibility visibility;

  /// Optional playback progress within segment `0..1`.
  final double? progress;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox.shrink();
    }
    return LayoutBuilder(
      builder: (context, c) {
        final h = math.max(120.0, c.maxHeight.isFinite ? c.maxHeight : 180.0);
        return SizedBox(
          height: h,
          width: double.infinity,
          child: CustomPaint(
            painter: _PitchContourPainter(
              points: points,
              referenceColor: referenceColor,
              userColor: userColor,
              visibility: visibility,
              progress: progress,
            ),
          ),
        );
      },
    );
  }
}

class _PitchContourPainter extends CustomPainter {
  _PitchContourPainter({
    required this.points,
    required this.referenceColor,
    required this.userColor,
    required this.visibility,
    required this.progress,
  });

  final List<EchoRegionSeriesPoint> points;
  final Color referenceColor;
  final Color userColor;
  final PitchContourVisibility visibility;
  final double? progress;

  Offset _xy(Rect chart, double maxT, double t, double normY) {
    final x = chart.left + (t / maxT) * chart.width;
    final y = chart.bottom - normY.clamp(0.0, 1.0) * chart.height;
    return Offset(x, y);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final maxT = points.last.t;
    if (maxT <= 0) return;

    var maxPitch = 1.0;
    for (final p in points) {
      if (p.pitchRefHz != null && p.pitchRefHz!.isFinite && p.pitchRefHz! > 0) {
        maxPitch = math.max(maxPitch, p.pitchRefHz!);
      }
      if (p.pitchUserHz != null && p.pitchUserHz!.isFinite && p.pitchUserHz! > 0) {
        maxPitch = math.max(maxPitch, p.pitchUserHz!);
      }
    }

    final chart = Rect.fromLTWH(0, 8, size.width, size.height - 16);

    // 1) Reference amplitude (dim)
    if (visibility.showWaveform && visibility.showReference) {
      final ampPaint = Paint()
        ..color = referenceColor.withValues(alpha: 0.18)
        ..strokeWidth = 0.8
        ..style = PaintingStyle.stroke;
      for (var i = 1; i < points.length; i++) {
        final a = points[i - 1];
        final b = points[i];
        final o1 = _xy(chart, maxT, a.t, a.ampRef * 0.28);
        final o2 = _xy(chart, maxT, b.t, b.ampRef * 0.28);
        canvas.drawLine(o1, o2, ampPaint);
      }
    }

    // 2) Reference pitch area + stroke
    if (visibility.showReference) {
      final line = Path();
      var first = true;
      for (final p in points) {
        if (p.pitchRefHz == null || p.pitchRefHz! <= 0) continue;
        final ny = p.pitchRefHz! / maxPitch;
        final o = _xy(chart, maxT, p.t, ny);
        if (first) {
          line.moveTo(o.dx, o.dy);
          first = false;
        } else {
          line.lineTo(o.dx, o.dy);
        }
      }
      if (!first) {
        final fill = Path()..addPath(line, Offset.zero);
        fill.lineTo(chart.right, chart.bottom);
        fill.lineTo(chart.left, chart.bottom);
        fill.close();
        canvas.drawPath(
          fill,
          Paint()
            ..color = referenceColor.withValues(alpha: 0.30)
            ..style = PaintingStyle.fill,
        );
        canvas.drawPath(
          line,
          Paint()
            ..color = referenceColor
            ..strokeWidth = 2.5
            ..style = PaintingStyle.stroke
            ..strokeJoin = StrokeJoin.round,
        );
      }
    }

    // 3) User amplitude
    if (visibility.showWaveform && visibility.showUser) {
      final uAmp = Paint()
        ..color = userColor.withValues(alpha: 0.15)
        ..strokeWidth = 0.6
        ..style = PaintingStyle.stroke;
      for (var i = 1; i < points.length; i++) {
        final a = points[i - 1];
        final b = points[i];
        if (a.ampUser <= 0 && b.ampUser <= 0) continue;
        final o1 = _xy(chart, maxT, a.t, a.ampUser * 0.25);
        final o2 = _xy(chart, maxT, b.t, b.ampUser * 0.25);
        canvas.drawLine(o1, o2, uAmp);
      }
    }

    // 4) User pitch stroke
    if (visibility.showUser) {
      final userLine = Path();
      var uFirst = true;
      for (final p in points) {
        if (p.pitchUserHz == null || p.pitchUserHz! <= 0) continue;
        final ny = p.pitchUserHz! / maxPitch;
        final o = _xy(chart, maxT, p.t, ny);
        if (uFirst) {
          userLine.moveTo(o.dx, o.dy);
          uFirst = false;
        } else {
          userLine.lineTo(o.dx, o.dy);
        }
      }
      if (!uFirst) {
        canvas.drawPath(
          userLine,
          Paint()
            ..color = userColor.withValues(alpha: 0.85)
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke,
        );
      }
    }

    final prog = progress;
    if (prog != null && prog >= 0 && prog <= 1) {
      final x = chart.left + prog * chart.width;
      canvas.drawLine(
        Offset(x, chart.top),
        Offset(x, chart.bottom),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.5)
          ..strokeWidth = 1.2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PitchContourPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.progress != progress ||
        oldDelegate.visibility != visibility ||
        oldDelegate.referenceColor != referenceColor ||
        oldDelegate.userColor != userColor;
  }
}
