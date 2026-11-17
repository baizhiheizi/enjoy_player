/// YIN pitch estimator — frame-hop contour aligned with web Essentia defaults.
library;

import 'dart:math' as math;
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
  double minHz = 55.0,
  double maxHz = 600.0,
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

  final padded = samples.length < frameSize ? Float32List(frameSize) : samples;
  if (samples.length < frameSize) {
    padded.setRange(0, samples.length, samples);
  }

  final buf = padded;
  final nHop = 1 + ((buf.length - frameSize) / hopSize).floor();
  final pitches = List<double?>.filled(nHop, null);
  final probs = List<double>.filled(nHop, 0);

  final half = frameSize ~/ 2;
  final maxPossibleTau = half - 1;
  final boundedMax = minHz > 0
      ? math.min(maxPossibleTau, (sampleRate / minHz).ceil() + 2)
      : maxPossibleTau;
  final tauMin = maxHz > 0 ? math.max(2, (sampleRate / maxHz).floor()) : 2;
  if (boundedMax < 2) {
    return YinPitchSeries(
      sampleRate: sampleRate,
      frameSize: frameSize,
      hopSize: hopSize,
      pitchHz: pitches,
      voicedProb: probs,
    );
  }

  final yinScratch = Float64List(boundedMax + 1);
  final voicedProbValue = (1.0 - yinThreshold).clamp(0.0, 1.0);

  for (var fi = 0; fi < nHop; fi++) {
    final start = fi * hopSize;
    if (start + frameSize > buf.length) break;

    final tauEstimate = _yinTauForFrame(
      buf,
      start,
      frameSize,
      tauMin,
      boundedMax,
      yinThreshold,
      yinScratch,
    );
    if (tauEstimate != null && tauEstimate > 1) {
      pitches[fi] = sampleRate / tauEstimate;
      probs[fi] = voicedProbValue;
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

/// Evaluates speech YIN F0 only at [envelope] timestamps, decimating high-rate
/// PCM (~44.1 kHz) toward ~16 kHz and reusing a single scratch buffer.
List<double?> estimatePitchAtEnvelopeTimes({
  required Float32List samples,
  required double sampleRate,
  required List<WaveformPoint> envelope,
  double yinThreshold = 0.15,
  double minVoicedProb = 0.35,
  double minHz = 55.0,
  double maxHz = 600.0,
}) {
  if (envelope.isEmpty) return const [];
  if (samples.isEmpty || sampleRate <= 0) {
    return List<double?>.filled(envelope.length, null);
  }
  final prob = (1.0 - yinThreshold).clamp(0.0, 1.0);
  if (prob < minVoicedProb) {
    return List<double?>.filled(envelope.length, null);
  }

  final decimation = sampleRate >= 28000 ? (sampleRate / 14700).floor() : 1;
  final Float32List workSamples;
  final double workRate;
  if (decimation > 1) {
    final outLen = samples.length ~/ decimation;
    if (outLen <= 0) {
      return List<double?>.filled(envelope.length, null);
    }
    final decimated = Float32List(outLen);
    final inv = 1.0 / decimation;
    for (var i = 0; i < outLen; i++) {
      final base = i * decimation;
      var sum = 0.0;
      for (var k = 0; k < decimation; k++) {
        sum += samples[base + k];
      }
      decimated[i] = sum * inv;
    }
    workSamples = decimated;
    workRate = sampleRate / decimation;
  } else {
    workSamples = samples;
    workRate = sampleRate;
  }

  final frameSize = (0.093 * workRate).round().clamp(512, 4096);
  final buf = workSamples.length < frameSize
      ? (Float32List(frameSize)..setRange(0, workSamples.length, workSamples))
      : workSamples;
  final maxStart = buf.length - frameSize;

  final half = frameSize ~/ 2;
  final tauMax = math.min(half - 1, (workRate / minHz).ceil() + 2);
  final tauMin = math.max(2, (workRate / maxHz).floor());
  if (tauMax < 2 || maxStart < 0) {
    return List<double?>.filled(envelope.length, null);
  }

  final yinScratch = Float64List(tauMax + 1);
  final out = List<double?>.filled(envelope.length, null);
  var lastStart = -1;
  double? lastHz;

  for (var i = 0; i < envelope.length; i++) {
    final start = (envelope[i].t * workRate).round().clamp(0, maxStart);
    if (start == lastStart) {
      out[i] = lastHz;
      continue;
    }
    lastStart = start;
    final tauEstimate = _yinTauForFrame(
      buf,
      start,
      frameSize,
      tauMin,
      tauMax,
      yinThreshold,
      yinScratch,
    );
    final double? hz = (tauEstimate != null && tauEstimate > 1)
        ? workRate / tauEstimate
        : null;
    lastHz = (hz != null && hz.isFinite && hz > 0) ? hz : null;
    out[i] = lastHz;
  }
  return out;
}

double? _yinTauForFrame(
  Float32List buf,
  int offset,
  int frameLen,
  int tauMin,
  int tauMax,
  double threshold,
  Float64List yin,
) {
  if (tauMax < 2) return null;

  for (var tau = 1; tau <= tauMax; tau++) {
    var s = 0.0;
    final limit = frameLen - tau;
    for (var i = 0; i < limit; i++) {
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

  var tau = math.max(2, tauMin);
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
