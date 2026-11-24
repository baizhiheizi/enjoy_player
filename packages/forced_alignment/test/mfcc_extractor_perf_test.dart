import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:forced_alignment/src/constants.dart';
import 'package:forced_alignment/src/mfcc/mfcc_extractor.dart';
import 'package:mcfcc_nsn/mcfcc_nsn.dart';

final class _LegacyFrames {
  _LegacyFrames(this.flat, this.frameCount);

  final Float64List flat;
  final int frameCount;
}

_LegacyFrames _legacyExtract(Float32List signal, MfccPreset preset) {
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
  return _LegacyFrames(flat, frameCount);
}

int _sink(MfccFrames frames) {
  var sink = 0;
  for (var i = 0; i < frames.data.length; i += 7) {
    sink = (sink + (frames.data[i] * 1000).round()) & 0x7fffffff;
  }
  return sink + frames.frameCount;
}

int _legacySink(_LegacyFrames frames) {
  var sink = 0;
  for (var i = 0; i < frames.flat.length; i += 7) {
    sink = (sink + (frames.flat[i] * 1000).round()) & 0x7fffffff;
  }
  return sink + frames.frameCount;
}

Float32List _benchCorpus(int seconds) {
  final length = seconds * kAlignmentSampleRate;
  final pcm = Float32List(length);
  var seed = 0x5eed1234;
  double next() {
    seed = (seed * 1664525 + 1013904223) & 0x7fffffff;
    return seed / 0x3fffffff - 1.0;
  }

  for (var i = 0; i < length; i++) {
    final t = i / kAlignmentSampleRate;
    pcm[i] =
        (0.5 + 0.5 * math.sin(2 * math.pi * 2.0 * t)) *
        (0.5 * math.sin(2 * math.pi * 170 * t) + 0.15 * next());
  }
  return pcm;
}

void main() {
  test('bench: 5 s corpus, legacy boxed extractor', skip: true, () {
    final pcm = _benchCorpus(5);
    const passes = 40;
    var sink = 0;
    final sw = Stopwatch()..start();
    for (var p = 0; p < passes; p++) {
      sink =
          (sink + _legacySink(_legacyExtract(pcm, kMfccPresetMedium))) &
          0x7fffffff;
    }
    sw.stop();
    // ignore: avoid_print
    print(
      'legacy 5s passes=$passes totalMs=${sw.elapsedMilliseconds} '
      'perExtractMs=${sw.elapsedMicroseconds / passes / 1000} sink=$sink',
    );
  });

  test('bench: 5 s corpus, typed-data extractor', skip: true, () {
    final pcm = _benchCorpus(5);
    const passes = 40;
    var sink = 0;
    final sw = Stopwatch()..start();
    for (var p = 0; p < passes; p++) {
      sink =
          (sink + _sink(extractMfccFrames(pcm, kMfccPresetMedium))) &
          0x7fffffff;
    }
    sw.stop();
    // ignore: avoid_print
    print(
      'typed-data 5s passes=$passes totalMs=${sw.elapsedMilliseconds} '
      'perExtractMs=${sw.elapsedMicroseconds / passes / 1000} sink=$sink',
    );
  });

  test('bench: 30 s corpus, legacy boxed extractor', skip: true, () {
    final pcm = _benchCorpus(30);
    const passes = 10;
    var sink = 0;
    final sw = Stopwatch()..start();
    for (var p = 0; p < passes; p++) {
      sink =
          (sink + _legacySink(_legacyExtract(pcm, kMfccPresetMedium))) &
          0x7fffffff;
    }
    sw.stop();
    // ignore: avoid_print
    print(
      'legacy 30s passes=$passes totalMs=${sw.elapsedMilliseconds} '
      'perExtractMs=${sw.elapsedMicroseconds / passes / 1000} sink=$sink',
    );
  });

  test('bench: 30 s corpus, typed-data extractor', skip: true, () {
    final pcm = _benchCorpus(30);
    const passes = 10;
    var sink = 0;
    final sw = Stopwatch()..start();
    for (var p = 0; p < passes; p++) {
      sink =
          (sink + _sink(extractMfccFrames(pcm, kMfccPresetMedium))) &
          0x7fffffff;
    }
    sw.stop();
    // ignore: avoid_print
    print(
      'typed-data 30s passes=$passes totalMs=${sw.elapsedMilliseconds} '
      'perExtractMs=${sw.elapsedMicroseconds / passes / 1000} sink=$sink',
    );
  });

  test('sink parity: sampler strips agree across implementations', () {
    final pcm = _benchCorpus(2);
    final legacy = _legacyExtract(pcm, kMfccPresetMedium);
    final fast = extractMfccFrames(pcm, kMfccPresetMedium);
    expect(_legacySink(legacy), _sink(fast));
  });
}
