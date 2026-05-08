/// RMS / peak envelope — ported from web `waveform.ts` `computeRmsEnvelope`.
library;

import 'dart:math' as math;
import 'dart:typed_data';

enum WaveformEnvelopeKind { rms, peak, hybrid }

class WaveformPoint {
  const WaveformPoint({required this.t, required this.amp});

  /// Seconds relative to segment start.
  final double t;

  /// Normalized amplitude in `[0, 1]`.
  final double amp;
}

/// Computes normalized amplitude envelope buckets over [samples].
List<WaveformPoint> computePeakEnvelope(
  Float32List samples,
  double sampleRate, {
  int points = 520,
  WaveformEnvelopeKind envelopeType = WaveformEnvelopeKind.peak,
  bool enhanceContrast = true,
}) {
  final nPts = points.clamp(8, 2000);
  if (samples.isEmpty || !sampleRate.isFinite || sampleRate <= 0) {
    return [];
  }

  final duration = samples.length / sampleRate;
  final bucketSize = (samples.length / nPts).floor().clamp(1, samples.length);

  final values = <double>[];
  for (var offset = 0; offset < samples.length; offset += bucketSize) {
    final end = offset + bucketSize > samples.length ? samples.length : offset + bucketSize;

    switch (envelopeType) {
      case WaveformEnvelopeKind.peak:
        var peak = 0.0;
        for (var i = offset; i < end; i++) {
          final a = samples[i].abs();
          if (a > peak) peak = a;
        }
        values.add(peak);
      case WaveformEnvelopeKind.hybrid:
        var sumSq = 0.0;
        var peak = 0.0;
        for (var i = offset; i < end; i++) {
          final x = samples[i];
          final a = x.abs();
          sumSq += x * x;
          if (a > peak) peak = a;
        }
        final rms = math.sqrt(sumSq / (end - offset).clamp(1, 1 << 30));
        values.add(0.6 * peak + 0.4 * rms);
      case WaveformEnvelopeKind.rms:
        var sumSq = 0.0;
        for (var i = offset; i < end; i++) {
          final x = samples[i];
          sumSq += x * x;
        }
        final meanSq = sumSq / (end - offset).clamp(1, 1 << 30);
        values.add(math.sqrt(meanSq));
    }
  }

  var max = 1e-9;
  for (final v in values) {
    if (v > max) max = v;
  }

  final out = <WaveformPoint>[];
  final n = values.length;
  for (var i = 0; i < n; i++) {
    final t = n == 1 ? 0.0 : (i / (n - 1)) * duration;
    var amp = values[i] / max;

    if (enhanceContrast) {
      amp = math.sqrt(amp);
      if (amp < 0.1) amp *= 0.5;
    }

    out.add(WaveformPoint(t: t, amp: amp));
  }
  return out;
}
