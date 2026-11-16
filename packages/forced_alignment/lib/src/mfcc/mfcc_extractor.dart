import 'dart:typed_data';

import 'package:mcfcc_nsn/mcfcc_nsn.dart';

import '../constants.dart';

int _nextPowerOfTwo(int n) {
  var p = 1;
  while (p < n) {
    p <<= 1;
  }
  return p;
}

/// Echogarden-ish hop/window presets (issue #540 § MFCC).
///
/// [windowLength] comes from [windowSeconds]. [fftSize] is the next power of
/// two so `mcfcc_nsn` / FFT can run; frames are zero-padded to that length.
final class MfccPreset {
  const MfccPreset({required this.windowSeconds, required this.hopSeconds})
    : assert(windowSeconds > 0, 'windowSeconds must be positive'),
      assert(hopSeconds > 0, 'hopSeconds must be positive');

  final double windowSeconds;
  final double hopSeconds;

  int get windowLength =>
      (windowSeconds * kAlignmentSampleRate).round().clamp(32, 8192);

  int get fftSize => _nextPowerOfTwo(windowLength);

  int get windowStride =>
      (hopSeconds * kAlignmentSampleRate).round().clamp(16, windowLength);
}

/// The one preset: the app hardcodes medium-granularity alignment, so the
/// low/high presets and the `mfccPresetFor` knob were deleted (audit #695).
const MfccPreset kMfccPresetMedium = MfccPreset(
  windowSeconds: 0.025,
  hopSeconds: 0.010,
);

/// MFCC frames in one flat row-major [Float64List] of `frameCount × stride`
/// cells — one typed allocation and no boxed per-coefficient doubles, which
/// the DTW then walks by offset (issue #827 A3).
final class MfccFrames {
  const MfccFrames({
    required this.data,
    required this.stride,
    required this.frameCount,
  });

  /// Flattens boxed `mcfcc_nsn` output (one `List<double>` per frame) into
  /// contiguous rows. Every frame must share the first frame's length —
  /// a shorter tail frame would otherwise write garbage into its
  /// neighbor's row, so it throws [ArgumentError] instead.
  factory MfccFrames.fromBoxed(List<List<double>> frames) {
    final count = frames.length;
    final stride = count == 0 ? 0 : frames.first.length;
    final flat = Float64List(count * stride);
    var offset = 0;
    for (final frame in frames) {
      if (frame.length != stride) {
        throw ArgumentError.value(
          frame.length,
          'frame $offset',
          'expected $stride coefficients per frame',
        );
      }
      flat.setRange(offset, offset + frame.length, frame);
      offset += frame.length;
    }
    return MfccFrames(data: flat, stride: stride, frameCount: count);
  }

  final Float64List data;
  final int stride;
  final int frameCount;

  int offsetOf(int frame) => frame * stride;
}

/// MFCC frames for 16 kHz mono PCM. Pads short signals to one window.
MfccFrames extractMfccFrames(Float32List signal, MfccPreset preset) {
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
  if (samples.length < window || rawCount < 1) {
    final coefs = processor.processFrames(singleFrame).first;
    final flat = Float64List(numCoefs)..setRange(0, numCoefs, coefs);
    return MfccFrames(data: flat, stride: numCoefs, frameCount: 1);
  }

  final flat = Float64List(frameCount * numCoefs);
  var outOffset = 0;
  for (var i = 0; i + window <= samples.length; i += stride) {
    scratch.setRange(0, window, samples, i);
    final coefs = processor.processFrames(singleFrame).first;
    flat.setRange(outOffset, outOffset + numCoefs, coefs);
    outOffset += numCoefs;
  }
  return MfccFrames(data: flat, stride: numCoefs, frameCount: frameCount);
}
