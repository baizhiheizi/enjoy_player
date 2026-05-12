import 'dart:typed_data';

import 'package:enjoy_player/core/audio/wav_signal_peak.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List _pcm16MonoWav(int sampleRate, List<int> s16Samples) {
  final dataBytes = s16Samples.length * 2;
  final riffSize = 4 + (8 + 16) + (8 + dataBytes);
  final b = BytesBuilder();
  void w(List<int> bytes) => b.add(bytes);

  w([0x52, 0x49, 0x46, 0x46]);
  w(_le32(riffSize));
  w([0x57, 0x41, 0x56, 0x45]);
  // fmt
  w([0x66, 0x6d, 0x74, 0x20]);
  w(_le32(16));
  w(_le16(1)); // PCM
  w(_le16(1)); // mono
  w(_le32(sampleRate));
  w(_le32(sampleRate * 2)); // byte rate
  w(_le16(2)); // block align
  w(_le16(16)); // bits
  // data
  w([0x64, 0x61, 0x74, 0x61]);
  w(_le32(dataBytes));
  for (final s in s16Samples) {
    w(_le16(s));
  }
  return b.toBytes();
}

List<int> _le32(int v) => [v & 0xff, (v >> 8) & 0xff, (v >> 16) & 0xff, (v >> 24) & 0xff];
List<int> _le16(int v) => [v & 0xff, (v >> 8) & 0xff];

void main() {
  test('scanWavDataPeakFromBytes detects silence', () {
    final bytes = _pcm16MonoWav(48000, List.filled(200, 0));
    final r = scanWavDataPeakFromBytes(bytes);
    expect(r, isNotNull);
    expect(r!.peakNormalized, 0);
    expect(r.rmsNormalized, 0);
    expect(r.nonZeroRatio, 0);
    expect(r.totalSamples, 200);
  });

  test('scanWavDataPeakFromBytes detects non-zero PCM16', () {
    final bytes = _pcm16MonoWav(48000, [0, 1000, -3000, 0]);
    final r = scanWavDataPeakFromBytes(bytes);
    expect(r, isNotNull);
    expect(r!.peakNormalized, closeTo(3000 / 32768.0, 1e-6));
    expect(r.totalSamples, 4);
    expect(r.nonZeroRatio, 0.5);
    expect(r.rmsNormalized, greaterThan(0));
    expect(r.rmsNormalized, lessThan(r.peakNormalized));
  });

  test(
    'scanWavDataPeakFromBytes flags single-spike-mostly-zero as silent by RMS',
    () {
      final samples = List<int>.filled(16000, 0);
      samples[100] = 32000;
      final bytes = _pcm16MonoWav(16000, samples);
      final r = scanWavDataPeakFromBytes(bytes);
      expect(r, isNotNull);
      expect(r!.peakNormalized, closeTo(32000 / 32768.0, 1e-6));
      expect(r.nonZeroRatio, lessThan(0.001));
      expect(r.rmsNormalized, lessThan(0.01));
    },
  );
}
