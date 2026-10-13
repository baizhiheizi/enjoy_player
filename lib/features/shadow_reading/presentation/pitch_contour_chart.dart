/// Pitch + amplitude chart for an echo region: the reference as a translucent
/// original-blue band, the take as a you-violet line, both on a semitone axis
/// fitted to the voiced range, over a quiet amplitude envelope.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../domain/echo_region_analysis.dart';

/// Voiced points further apart than this start a new contour run; shorter
/// detection dropouts inside a word are bridged.
const double kPitchContourMaxGapSec = 0.25;

/// Points further than this from the series' median pitch are octave errors
/// (the detector locked onto a half or double frequency) and are folded back
/// by 12 semitones.
const double kPitchContourOctaveFoldSemitones = 9;

/// Runs shorter than this are detection noise and are not drawn.
const double kPitchContourMinRunSec = 0.06;

/// Smallest vertical range of the chart, so a monotone line stays flat-ish
/// instead of being stretched to full height.
const double kPitchContourMinSpanSemitones = 8;

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
    this.progressColor,
    super.key,
  });

  final List<EchoRegionSeriesPoint> points;
  final Color referenceColor;
  final Color userColor;
  final PitchContourVisibility visibility;

  /// Optional playback progress within segment `0..1`.
  final double? progress;

  /// When null, resolved from [ThemeData.colorScheme] in [build].
  final Color? progressColor;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox.shrink();
    }
    final resolvedProgressColor =
        progressColor ??
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55);
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
              progressColor: resolvedProgressColor,
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
    required this.progressColor,
  });

  final List<EchoRegionSeriesPoint> points;
  final Color referenceColor;
  final Color userColor;
  final PitchContourVisibility visibility;
  final double? progress;
  final Color progressColor;

  static double _semitones(double hz) => 12 * math.log(hz) / math.ln2;

  static bool _voiced(double? hz) => hz != null && hz.isFinite && hz > 0;

  /// Splits a series into voiced runs: a run ends at a time gap wider than
  /// [kPitchContourMaxGapSec], so pauses never get bridged by a straight line.
  /// Runs shorter than [kPitchContourMinRunSec] are dropped, octave errors
  /// are folded toward the median pitch, and each run is median-filtered
  /// (5 points) to remove single-frame spikes.
  List<List<(double, double)>> _runs(
    double? Function(EchoRegionSeriesPoint) hz,
  ) {
    final raw = <List<(double, double)>>[];
    List<(double, double)>? current;
    double? lastT;
    for (final p in points) {
      final v = hz(p);
      if (!_voiced(v)) continue;
      if (current == null ||
          (lastT != null && p.t - lastT > kPitchContourMaxGapSec)) {
        current = [];
        raw.add(current);
      }
      current.add((p.t, _semitones(v!)));
      lastT = p.t;
    }
    final kept = [
      for (final run in raw)
        if (run.last.$1 - run.first.$1 >= kPitchContourMinRunSec) run,
    ];
    final all = [
      for (final run in kept)
        for (final (_, st) in run) st,
    ]..sort();
    if (all.isEmpty) return const [];
    final center = all[all.length ~/ 2];
    double fold(double st) {
      var v = st;
      while (v - center > kPitchContourOctaveFoldSemitones) {
        v -= 12;
      }
      while (center - v > kPitchContourOctaveFoldSemitones) {
        v += 12;
      }
      return v;
    }

    return [
      for (final run in kept)
        _median([for (final (t, st) in run) (t, fold(st))]),
    ];
  }

  static List<(double, double)> _median(List<(double, double)> run) {
    if (run.length < 5) return run;
    return [
      for (var i = 0; i < run.length; i++)
        (
          run[i].$1,
          (([
            for (
              var j = math.max(0, i - 2);
              j <= math.min(run.length - 1, i + 2);
              j++
            )
              run[j].$2,
          ]..sort())[(math.min(run.length - 1, i + 2) - math.max(0, i - 2)) ~/
              2]),
        ),
    ];
  }

  @override
  void paint(Canvas canvas, Size size) {
    final maxT = points.last.t;
    if (maxT <= 0) return;

    final refRuns = visibility.showReference
        ? _runs((p) => p.pitchRefHz)
        : const <List<(double, double)>>[];
    final userRuns = visibility.showUser
        ? _runs((p) => p.pitchUserHz)
        : const <List<(double, double)>>[];

    var lo = double.infinity;
    var hi = double.negativeInfinity;
    for (final run in [...refRuns, ...userRuns]) {
      for (final (_, st) in run) {
        lo = math.min(lo, st);
        hi = math.max(hi, st);
      }
    }
    if (!lo.isFinite) {
      lo = 0;
      hi = 1;
    }
    final span = math.max(hi - lo, kPitchContourMinSpanSemitones);
    final mid = (lo + hi) / 2;
    lo = mid - span * 0.6;
    hi = mid + span * 0.6;

    final chart = Rect.fromLTWH(0, 10, size.width, size.height - 20);
    double x(double t) => chart.left + (t / maxT) * chart.width;
    double y(double st) =>
        chart.bottom - ((st - lo) / (hi - lo)).clamp(0.0, 1.0) * chart.height;

    if (visibility.showWaveform) {
      final envelope = Path()..moveTo(chart.left, chart.bottom);
      for (final p in points) {
        final amp = math.max(
          visibility.showReference ? p.ampRef : 0.0,
          visibility.showUser ? p.ampUser : 0.0,
        );
        envelope.lineTo(x(p.t), chart.bottom - amp * chart.height * 0.22);
      }
      envelope
        ..lineTo(chart.right, chart.bottom)
        ..close();
      canvas.drawPath(
        envelope,
        Paint()..color = referenceColor.withValues(alpha: 0.12),
      );
    }

    void stroke(List<List<(double, double)>> runs, Paint paint) {
      for (final run in runs) {
        final path = Path()..moveTo(x(run.first.$1), y(run.first.$2));
        if (run.length == 1) {
          path.lineTo(x(run.first.$1) + 0.5, y(run.first.$2));
        }
        for (final (t, st) in run.skip(1)) {
          path.lineTo(x(t), y(st));
        }
        canvas.drawPath(path, paint);
      }
    }

    stroke(
      refRuns,
      Paint()
        ..color = referenceColor
        ..strokeWidth = 9
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    stroke(
      userRuns,
      Paint()
        ..color = userColor
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final prog = progress;
    if (prog != null && prog >= 0 && prog <= 1) {
      final px = chart.left + prog * chart.width;
      canvas.drawLine(
        Offset(px, chart.top),
        Offset(px, chart.bottom),
        Paint()
          ..color = progressColor
          ..strokeWidth = 1.2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PitchContourPainter oldDelegate) {
    return !listEquals(oldDelegate.points, points) ||
        oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.visibility != visibility ||
        oldDelegate.referenceColor != referenceColor ||
        oldDelegate.userColor != userColor;
  }
}
