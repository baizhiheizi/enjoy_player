import 'dart:math' as math;
import 'dart:typed_data';

import 'radix2_fft.dart';

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
/// two so the FFT can run; frames are zero-padded to that length.
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

  /// Flattens boxed `List<List<double>>` frames. Every frame must share the
  /// first frame's length — a shorter tail frame would otherwise write
  /// garbage into its neighbor's row, so it throws [ArgumentError] instead.
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

final class _SparseMelFilterbank {
  _SparseMelFilterbank({
    required int sampleRate,
    required int numFilters,
    required int binCount,
  }) : starts = Int32List(numFilters),
       weights = List<Float64List>.generate(numFilters, (_) => Float64List(0)) {
    final interval = 1127 * math.log(1 + sampleRate / 700) / (numFilters + 1);
    final gridIndexes = Int32List(numFilters + 2);
    for (var i = 0; i < gridIndexes.length; i++) {
      final mel = i * interval;
      final hertz = 700 * (math.exp(mel / 1127) - 1);
      gridIndexes[i] = (hertz * binCount / sampleRate).floor();
    }
    for (var i = 0; i < numFilters; i++) {
      final leftLength = gridIndexes[i + 1] - gridIndexes[i];
      final rightLength = gridIndexes[i + 2] - gridIndexes[i + 1];
      final supportEnd = math.min(
        gridIndexes[i] + leftLength + 1 + rightLength,
        binCount,
      );
      final weightCount = supportEnd - gridIndexes[i];
      final filterWeights = Float64List(weightCount);
      for (var v = 0; v < leftLength && v < weightCount; v++) {
        filterWeights[v] = v / leftLength;
      }
      if (leftLength < weightCount) {
        filterWeights[leftLength] = 1.0;
      }
      for (
        var v = 0;
        leftLength + 1 + v < weightCount && v < rightLength;
        v++
      ) {
        filterWeights[leftLength + 1 + v] = (rightLength - 1 - v) / rightLength;
      }
      starts[i] = gridIndexes[i];
      weights[i] = filterWeights;
    }
  }

  final Int32List starts;
  final List<Float64List> weights;
}

final class _MfccTables {
  _MfccTables({required this.fftSize, required this.windowLength})
    : binCount = (fftSize ~/ 2) + 1,
      spectrum = Float64List((fftSize ~/ 2) + 1),
      mel = Float64List(kMelFilterCount),
      filterbank = _SparseMelFilterbank(
        sampleRate: kAlignmentSampleRate,
        numFilters: kMelFilterCount,
        binCount: (fftSize ~/ 2) + 1,
      ),
      dctCosines = Float64List(
        (kCepstralCoefficientCount - 1) * kMelFilterCount,
      ),
      fft = Radix2FftPlan(fftSize) {
    for (var k = 1; k < kCepstralCoefficientCount; k++) {
      for (var n = 0; n < kMelFilterCount; n++) {
        dctCosines[(k - 1) * kMelFilterCount + n] = math.cos(
          math.pi * k * (2 * n + 1) / (2 * kMelFilterCount),
        );
      }
    }
  }

  final int fftSize;
  final int windowLength;
  final int binCount;
  final Float64List spectrum;
  final Float64List mel;
  final _SparseMelFilterbank filterbank;
  final Float64List dctCosines;
  final Radix2FftPlan fft;

  double get dctScalingFactor => math.sqrt(1 / (2 * kMelFilterCount));
}

const int kMelFilterCount = 26;
const int kCepstralCoefficientCount = 13;
const double kPreEmphasisFactor = 0.97;

double _safeLog(double value) =>
    value <= 0 ? math.log(double.minPositive) : math.log(value);

/// MFCC frames for 16 kHz mono PCM. Pads short signals to one window.
MfccFrames extractMfccFrames(Float32List signal, MfccPreset preset) {
  const numCoefs = kCepstralCoefficientCount;
  final window = preset.windowLength;
  final fftSize = preset.fftSize;
  final tables = _MfccTables(fftSize: fftSize, windowLength: window);
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
  final flat = Float64List(frameCount * numCoefs);
  final frame = Float64List(fftSize);
  final imag = Float64List(fftSize);
  final dctScalingFactor = tables.dctScalingFactor;
  var outOffset = 0;
  for (var i = 0; i + window <= samples.length; i += stride) {
    for (var j = 0; j < window; j++) {
      frame[j] = samples[i + j];
    }
    frame.fillRange(window, fftSize, 0.0);
    var previous = 0.0;
    for (var j = 0; j < fftSize; j++) {
      final original = frame[j];
      frame[j] = original - previous * kPreEmphasisFactor;
      previous = original;
    }
    imag.fillRange(0, fftSize, 0.0);
    tables.fft.transform(frame, imag);
    final spectrum = tables.spectrum;
    for (var j = 0; j < tables.binCount; j++) {
      final re = frame[j];
      final im = imag[j];
      spectrum[j] = (re * re + im * im) / fftSize;
    }
    final filterbank = tables.filterbank;
    final mel = tables.mel;
    for (var f = 0; f < kMelFilterCount; f++) {
      final start = filterbank.starts[f];
      final weights = filterbank.weights[f];
      var sum = 0.0;
      for (var j = 0; j < weights.length; j++) {
        sum += spectrum[start + j] * weights[j];
      }
      mel[f] = _safeLog(sum);
    }
    var energy = 0.0;
    for (var j = 0; j < tables.binCount; j++) {
      energy += spectrum[j];
    }
    flat[outOffset] = _safeLog(energy);
    final dctCosines = tables.dctCosines;
    for (var k = 1; k < numCoefs; k++) {
      var sum = 0.0;
      final row = (k - 1) * kMelFilterCount;
      for (var n = 0; n < kMelFilterCount; n++) {
        sum += mel[n] * dctCosines[row + n];
      }
      flat[outOffset + k] = sum * 2 * dctScalingFactor;
    }
    outOffset += numCoefs;
  }
  return MfccFrames(data: flat, stride: numCoefs, frameCount: frameCount);
}
