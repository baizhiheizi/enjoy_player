/// YIN pitch estimator — frame-hop contour aligned with web Essentia defaults.
library;

import 'dart:typed_data';

import 'waveform_envelope.dart';

/// One pitch estimate per hop starting at 0.
class YinPitchSeries {
  YinPitchSeries({
    required this.sampleRate,
    required this.frameSize,
    required this.hopSize,
    required this.pitchHz,
    required this.voicedProb,
  });

  final double sampleRate;
  final int frameSize;
  final int hopSize;

  /// Length = number of hop positions covering the buffer.
  final List<double?> pitchHz;

  /// Heuristic voice likelihood `[0,1]` per hop (high when periodic).
  final List<double> voicedProb;
}

/// Runs YIN on overlapping frames (Essentia-like: fixed frame/hop across signal).
YinPitchSeries estimatePitchYin(
  Float32List samples,
  double sampleRate, {
  int frameSize = 4096,
  int hopSize = 128,
  double yinThreshold = 0.15,
}) {
  if (samples.isEmpty || sampleRate <= 0) {
    return YinPitchSeries(
      sampleRate: sampleRate,
      frameSize: frameSize,
      hopSize: hopSize,
      pitchHz: [],
      voicedProb: [],
    );
  }

  final padded =
      samples.length < frameSize
          ? Float32List(frameSize)
          : samples;
  if (samples.length < frameSize) {
    padded.setRange(0, samples.length, samples);
  }

  final buf = padded;
  final nHop = 1 + ((buf.length - frameSize) / hopSize).floor();
  final pitches = List<double?>.filled(nHop, null);
  final probs = List<double>.filled(nHop, 0);

  final half = frameSize ~/ 2;
  final tauMax = half - 1;

  for (var fi = 0; fi < nHop; fi++) {
    final start = fi * hopSize;
    if (start + frameSize > buf.length) break;

    final tauEstimate = _yinTauForFrame(
      buf,
      start,
      frameSize,
      tauMax,
      yinThreshold,
    );
    if (tauEstimate != null && tauEstimate > 1) {
      pitches[fi] = sampleRate / tauEstimate;
      probs[fi] = (1.0 - yinThreshold).clamp(0.0, 1.0);
    }
  }

  return YinPitchSeries(
    sampleRate: sampleRate,
    frameSize: frameSize,
    hopSize: hopSize,
    pitchHz: pitches,
    voicedProb: probs,
  );
}

double? _yinTauForFrame(
  Float32List buf,
  int offset,
  int frameLen,
  int tauMax,
  double threshold,
) {
  if (tauMax < 2) return null;

  final yin = List<double>.filled(tauMax + 1, 0);

  for (var tau = 1; tau <= tauMax; tau++) {
    var s = 0.0;
    for (var i = 0; i < frameLen - tau; i++) {
      final delta = buf[offset + i] - buf[offset + i + tau];
      s += delta * delta;
    }
    yin[tau] = s;
  }

  yin[0] = 1;
  var running = 0.0;
  for (var tau = 1; tau <= tauMax; tau++) {
    running += yin[tau];
    if (running == 0) {
      yin[tau] = 1;
    } else {
      yin[tau] *= tau / running;
    }
  }

  var tau = 2;
  while (tau < tauMax) {
    if (yin[tau] < threshold) {
      while (tau + 1 < tauMax && yin[tau + 1] < yin[tau]) {
        tau++;
      }
      return _parabolicMin(yin, tau);
    }
    tau++;
  }
  return null;
}

double _parabolicMin(List<double> yin, int tau) {
  if (tau <= 0 || tau >= yin.length - 1) return tau.toDouble();
  final s0 = yin[tau - 1];
  final s1 = yin[tau];
  final s2 = yin[tau + 1];
  final denom = s0 - 2 * s1 + s2;
  if (denom.abs() < 1e-12) return tau.toDouble();
  final x = tau + (s0 - s2) / (2 * denom);
  return x.clamp(1.0, yin.length - 2.0);
}

/// Maps hop-space pitch curve onto envelope time stamps (web `mapPitchToEnvelopeTimes`).
List<double?> pitchAtEnvelopeTimes({
  required List<WaveformPoint> envelope,
  required YinPitchSeries yin,
  double minVoicedProb = 0.35,
}) {
  if (envelope.isEmpty) return [];
  final frames = yin.pitchHz.length;
  if (frames == 0) {
    return envelope.map((_) => null).toList();
  }

  final hopSec = yin.hopSize / yin.sampleRate;
  final out = <double?>[];
  for (final p in envelope) {
    final idx = (p.t / hopSec).round().clamp(0, frames - 1);
    final hz = yin.pitchHz[idx];
    final prob = idx < yin.voicedProb.length ? yin.voicedProb[idx] : 0.0;
    final voiced = hz != null && hz.isFinite && hz > 0 && prob >= minVoicedProb;
    out.add(voiced ? hz : null);
  }
  return out;
}
