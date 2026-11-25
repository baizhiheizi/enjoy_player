import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:forced_alignment/src/constants.dart';
import 'package:forced_alignment/src/dtw/windowed_dtw.dart';
import 'package:forced_alignment/src/mfcc/mfcc_extractor.dart';
import 'package:mcfcc_nsn/mcfcc_nsn.dart';

final class _Oracle {
  _Oracle._(this.flat, this.frameCount, this.stride);

  final Float64List flat;
  final int frameCount;
  final int stride;

  MfccFrames get frames =>
      MfccFrames(data: flat, stride: stride, frameCount: frameCount);
}

_Oracle _legacyExtractMfccFrames(Float32List signal, MfccPreset preset) {
  final window = preset.windowLength;
  final fftSize = preset.fftSize;
  Float32List samples;
  if (signal.length < window) {
    samples = Float32List(window);
    samples.setRange(0, signal.length, signal);
  } else {
    samples = signal;
  }
  final stride = preset.windowStride;
  final rawCount = ((samples.length - window) ~/ stride) + 1;
  final frameCount = rawCount < 1 ? 1 : rawCount;
  const numCoefs = 13;
  final processor = MFCC(
    sampleRate: kAlignmentSampleRate,
    fftSize: fftSize,
    numFilters: 26,
    numCoefs: numCoefs,
  );
  final scratch = Float64List(fftSize);
  final singleFrame = <List<double>>[scratch];
  final flat = Float64List(frameCount * numCoefs);
  var outOffset = 0;
  for (var i = 0; i + window <= samples.length; i += stride) {
    scratch.setRange(0, window, samples, i);
    final coefs = processor.processFrames(singleFrame).first;
    flat.setRange(outOffset, outOffset + numCoefs, coefs);
    outOffset += numCoefs;
  }
  return _Oracle._(flat, frameCount, numCoefs);
}

final class _DiffAccumulator {
  double maxAbs = 0;
  double maxRel = 0;
  int checks = 0;

  void add(MfccFrames legacy, MfccFrames fast, String reason) {
    expect(fast.frameCount, legacy.frameCount, reason: 'frameCount: $reason');
    expect(fast.stride, legacy.stride, reason: 'stride: $reason');
    for (var i = 0; i < legacy.data.length; i++) {
      final a = legacy.data[i];
      final b = fast.data[i];
      final d = (a - b).abs();
      if (d > maxAbs) maxAbs = d;
      final rel = d / math.max(1.0, math.max(a.abs(), b.abs()));
      if (rel > maxRel) maxRel = rel;
      checks++;
    }
  }
}

Float32List _corpus(int seconds, int kind, {double amplitude = 1.0}) {
  final length = seconds * kAlignmentSampleRate;
  final pcm = Float32List(length);
  var seed = 0x5eed1234 ^ (kind << 16);
  double next() {
    seed = (seed * 1664525 + 1013904223) & 0x7fffffff;
    return seed / 0x3fffffff - 1.0;
  }

  for (var i = 0; i < length; i++) {
    final t = i / kAlignmentSampleRate;
    switch (kind) {
      case 0:
        pcm[i] =
            amplitude *
            (0.4 * math.sin(2 * math.pi * 220 * t) +
                0.2 * math.sin(2 * math.pi * 880 * t));
      case 1:
        pcm[i] = amplitude * next() * 0.5;
      case 2:
        final env = 0.5 + 0.5 * math.sin(2 * math.pi * 2.0 * t);
        pcm[i] =
            amplitude *
            env *
            (0.5 *
                    math.sin(
                      2 *
                          math.pi *
                          (150 + 60 * math.sin(2 * math.pi * 0.7 * t)) *
                          t,
                    ) +
                0.15 * next());
      case 3:
        pcm[i] = amplitude * 0.9;
      default:
        pcm[i] = amplitude * next() * 1e-6;
    }
  }
  return pcm;
}

void main() {
  group('differential: extractor equals the mcfcc_nsn composition', () {
    test('tonal, noisy, formant, dc, and near-silent corpora', () {
      final acc = _DiffAccumulator();
      for (var kind = 0; kind < 5; kind++) {
        for (final amplitude in [1.0, 1e-4, 4.0]) {
          final pcm = _corpus(2, kind, amplitude: amplitude);
          acc.add(
            _legacyExtractMfccFrames(pcm, kMfccPresetMedium).frames,
            extractMfccFrames(pcm, kMfccPresetMedium),
            'kind=$kind amplitude=$amplitude',
          );
        }
      }
      expect(acc.checks, greaterThan(30000));
      expect(acc.maxAbs, lessThan(1e-8), reason: 'maxAbs=${acc.maxAbs}');
      expect(acc.maxRel, lessThan(1e-9), reason: 'maxRel=${acc.maxRel}');
    });

    test('edge lengths: below, at, and past the window', () {
      const lengths = [
        1,
        2,
        100,
        399,
        400,
        401,
        559,
        560,
        561,
        1599,
        1600,
        1601,
        8000,
        48017,
      ];
      final acc = _DiffAccumulator();
      var seed = 0xbeefcace;
      double next() {
        seed = (seed * 1664525 + 1013904223) & 0x7fffffff;
        return seed / 0x3fffffff - 1.0;
      }

      for (final length in lengths) {
        final pcm = Float32List(length);
        for (var i = 0; i < length; i++) {
          pcm[i] = next() * 0.6;
        }
        acc.add(
          _legacyExtractMfccFrames(pcm, kMfccPresetMedium).frames,
          extractMfccFrames(pcm, kMfccPresetMedium),
          'length=$length',
        );
      }
      expect(acc.maxAbs, lessThan(1e-8), reason: 'maxAbs=${acc.maxAbs}');
      expect(acc.maxRel, lessThan(1e-9), reason: 'maxRel=${acc.maxRel}');
    });
  });

  test('same input extracts identical frames', () {
    final pcm = _corpus(1, 1);
    final first = extractMfccFrames(pcm, kMfccPresetMedium);
    final second = extractMfccFrames(pcm, kMfccPresetMedium);
    expect(first.frameCount, second.frameCount);
    expect(first.data, second.data);
  });

  test('short signal aligns with the oracle over the padded window', () {
    final pcm = Float32List(100);
    for (var i = 0; i < pcm.length; i++) {
      pcm[i] = math.sin(2 * math.pi * 300 * i / kAlignmentSampleRate);
    }
    final legacy = _legacyExtractMfccFrames(pcm, kMfccPresetMedium);
    final fast = extractMfccFrames(pcm, kMfccPresetMedium);
    expect(fast.frameCount, 1);
    expect(fast.frameCount, legacy.frameCount);
    for (var i = 0; i < legacy.flat.length; i++) {
      expect(
        (fast.data[i] - legacy.flat[i]).abs(),
        lessThan(1e-8),
        reason: 'index $i',
      );
    }
  });

  test('frame count follows the hop arithmetic', () {
    final frames1s = extractMfccFrames(
      Float32List(kAlignmentSampleRate),
      kMfccPresetMedium,
    );
    expect(frames1s.frameCount, ((kAlignmentSampleRate - 400) ~/ 160) + 1);
    expect(frames1s.stride, 13);
    final frames90s = extractMfccFrames(
      Float32List(90 * kAlignmentSampleRate),
      kMfccPresetMedium,
    );
    expect(
      frames90s.frameCount,
      ((90 * kAlignmentSampleRate - 400) ~/ 160) + 1,
    );
  });

  test('DTW maps agree between oracle frames and extractor frames', () {
    final reference = _corpus(2, 2);
    final source = Float32List(reference.length + 800);
    for (var i = 0; i < source.length; i++) {
      source[i] =
          reference[(i * (reference.length - 1) ~/ (source.length - 1))] * 0.98;
    }
    final oracleFrames = _legacyExtractMfccFrames(
      reference,
      kMfccPresetMedium,
    ).frames;
    final extractorFrames = extractMfccFrames(reference, kMfccPresetMedium);
    final oracleSource = extractMfccFrames(source, kMfccPresetMedium);
    final oracleMap = mapReferenceFramesToSource(oracleFrames, oracleSource);
    final extractorMap = mapReferenceFramesToSource(
      extractorFrames,
      oracleSource,
    );
    expect(extractorMap, oracleMap);
  });
}
