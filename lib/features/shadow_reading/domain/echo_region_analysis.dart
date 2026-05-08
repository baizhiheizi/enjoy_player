/// Echo-region pitch series types — mirrors web `echo-region-analysis.ts`.
library;

import 'waveform_envelope.dart';

class EchoRegionSeriesPoint {
  const EchoRegionSeriesPoint({
    required this.t,
    required this.ampRef,
    this.pitchRefHz,
    this.ampUser = 0,
    this.pitchUserHz,
  });

  /// Time relative to region start (seconds).
  final double t;

  /// Reference normalized amplitude `[0, 1]`.
  final double ampRef;

  final double? pitchRefHz;

  /// User waveform amplitude overlay `[0, 1]` (defaults 0).
  final double ampUser;

  final double? pitchUserHz;

  EchoRegionSeriesPoint copyWith({
    double? t,
    double? ampRef,
    double? pitchRefHz,
    double? ampUser,
    double? pitchUserHz,
  }) {
    return EchoRegionSeriesPoint(
      t: t ?? this.t,
      ampRef: ampRef ?? this.ampRef,
      pitchRefHz: pitchRefHz ?? this.pitchRefHz,
      ampUser: ampUser ?? this.ampUser,
      pitchUserHz: pitchUserHz ?? this.pitchUserHz,
    );
  }
}

class EchoRegionAnalysisResult {
  const EchoRegionAnalysisResult({
    required this.points,
    required this.durationSeconds,
    required this.sampleRate,
  });

  final List<EchoRegionSeriesPoint> points;
  final double durationSeconds;
  final double sampleRate;
}

/// Merge user recording analysis onto reference points — mirrors web `mergedAnalysis`.
List<EchoRegionSeriesPoint> mergeUserPitchOntoReference({
  required List<EchoRegionSeriesPoint> referencePoints,
  required List<EchoRegionSeriesPoint> userPoints,
  required double referenceDurationSec,
  required double userDurationSec,
}) {
  if (referencePoints.isEmpty) return [];
  if (userPoints.isEmpty || userDurationSec <= 0) {
    return referencePoints
        .map(
          (p) => EchoRegionSeriesPoint(
            t: p.t,
            ampRef: p.ampRef,
            pitchRefHz: p.pitchRefHz,
            ampUser: 0,
            pitchUserHz: null,
          ),
        )
        .toList();
  }

  final scale = referenceDurationSec / userDurationSec;
  final merged =
      referencePoints
          .map(
            (p) => EchoRegionSeriesPoint(
              t: p.t,
              ampRef: p.ampRef,
              pitchRefHz: p.pitchRefHz,
              ampUser: 0,
              pitchUserHz: null,
            ),
          )
          .toList();

  const nearestTol = 0.1;
  for (final userPoint in userPoints) {
    final mappedTime = userPoint.t * scale;
    var nearestIdx = -1;
    var nearestDiff = double.infinity;
    for (var i = 0; i < merged.length; i++) {
      final diff = (merged[i].t - mappedTime).abs();
      if (diff < nearestDiff) {
        nearestDiff = diff;
        nearestIdx = i;
      }
    }
    if (nearestIdx >= 0 && nearestDiff < nearestTol) {
      final p = merged[nearestIdx];
      merged[nearestIdx] = EchoRegionSeriesPoint(
        t: p.t,
        ampRef: p.ampRef,
        pitchRefHz: p.pitchRefHz,
        ampUser: userPoint.ampRef,
        pitchUserHz: userPoint.pitchRefHz,
      );
    }
  }

  return merged;
}

List<EchoRegionSeriesPoint> buildSeriesPoints({
  required List<WaveformPoint> envelope,
  required List<double?> pitchHzList,
}) {
  assert(envelope.length == pitchHzList.length);
  final out = <EchoRegionSeriesPoint>[];
  for (var i = 0; i < envelope.length; i++) {
    final e = envelope[i];
    final hz = pitchHzList[i];
    out.add(
      EchoRegionSeriesPoint(
        t: e.t,
        ampRef: e.amp,
        pitchRefHz: hz,
      ),
    );
  }
  return out;
}
