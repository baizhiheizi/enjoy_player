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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EchoRegionSeriesPoint &&
          runtimeType == other.runtimeType &&
          t == other.t &&
          ampRef == other.ampRef &&
          pitchRefHz == other.pitchRefHz &&
          ampUser == other.ampUser &&
          pitchUserHz == other.pitchUserHz;

  @override
  int get hashCode => Object.hash(t, ampRef, pitchRefHz, ampUser, pitchUserHz);
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
  final merged = referencePoints
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
    out.add(EchoRegionSeriesPoint(t: e.t, ampRef: e.amp, pitchRefHz: hz));
  }
  return out;
}

/// Memoizes the merged reference+user pitch series keyed on the reference and
/// user analysis results (by identity) plus their durations.
///
/// The merge is identical across playback ticks — only the progress cursor
/// changes per tick — so caching the list (and returning the *same instance*)
/// lets `CustomPainter.shouldRepaint` short-circuit on the points clause and
/// avoids recomputing the O(n·m) nearest-match scan on every frame.
///
/// Call [invalidate] whenever the underlying reference or user result changes.
class EchoMergedSeriesMemo {
  EchoMergedSeriesMemo();

  _MergedKey? _key;
  List<EchoRegionSeriesPoint> _cache = const <EchoRegionSeriesPoint>[];

  /// Returns the merged series for the given inputs, recomputing only when the
  /// reference/user results or durations change. The returned list is the same
  /// instance across calls with identical inputs.
  List<EchoRegionSeriesPoint> resolve({
    required EchoRegionAnalysisResult? reference,
    required EchoRegionAnalysisResult? user,
    required double referenceDurationSec,
    required double userDurationSec,
  }) {
    final key = _MergedKey(
      reference: reference,
      user: user,
      referenceDurationSec: referenceDurationSec,
      userDurationSec: userDurationSec,
    );
    if (_key == key) return _cache;

    final ref = reference;
    if (ref == null) {
      _key = key;
      _cache = const <EchoRegionSeriesPoint>[];
      return _cache;
    }
    final u = user;
    final merged = (u != null && userDurationSec > 0)
        ? mergeUserPitchOntoReference(
            referencePoints: ref.points,
            userPoints: u.points,
            referenceDurationSec: referenceDurationSec,
            userDurationSec: userDurationSec,
          )
        : ref.points;
    _key = key;
    _cache = merged;
    return _cache;
  }

  /// Drops the cache so the next [resolve] recomputes.
  void invalidate() {
    _key = null;
    _cache = const <EchoRegionSeriesPoint>[];
  }
}

class _MergedKey {
  const _MergedKey({
    required this.reference,
    required this.user,
    required this.referenceDurationSec,
    required this.userDurationSec,
  });

  final EchoRegionAnalysisResult? reference;
  final EchoRegionAnalysisResult? user;
  final double referenceDurationSec;
  final double userDurationSec;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _MergedKey &&
          identical(other.reference, reference) &&
          identical(other.user, user) &&
          other.referenceDurationSec == referenceDurationSec &&
          other.userDurationSec == userDurationSec;

  @override
  int get hashCode => Object.hash(
    identityHashCode(reference),
    identityHashCode(user),
    referenceDurationSec,
    userDurationSec,
  );
}
