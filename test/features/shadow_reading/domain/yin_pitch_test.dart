import 'dart:math' as math;
import 'dart:typed_data';

import 'package:enjoy_player/features/shadow_reading/domain/waveform_envelope.dart';
import 'package:enjoy_player/features/shadow_reading/domain/yin_pitch.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('estimatePitchYin', () {
    test('returns empty series for empty samples', () {
      final result = estimatePitchYin(Float32List(0), 44100);
      expect(result.pitchHz, isEmpty);
      expect(result.voicedProb, isEmpty);
      expect(result.sampleRate, 44100);
      expect(result.frameSize, 4096);
      expect(result.hopSize, 128);
    });

    test('returns empty series for non-positive sample rate', () {
      final samples = Float32List.fromList([0.1, 0.2, -0.1]);
      final result = estimatePitchYin(samples, 0);
      expect(result.pitchHz, isEmpty);
      expect(result.voicedProb, isEmpty);
    });

    test('returns empty series for negative sample rate', () {
      final samples = Float32List.fromList([0.1, 0.2, -0.1]);
      final result = estimatePitchYin(samples, -1);
      expect(result.pitchHz, isEmpty);
      expect(result.voicedProb, isEmpty);
    });

    test('pads short buffers to frameSize and computes result', () {
      final samples = Float32List(2048);
      for (var i = 0; i < samples.length; i++) {
        samples[i] = math.sin(2 * math.pi * 440 * i / 44100);
      }
      final result = estimatePitchYin(samples, 44100);
      expect(result.pitchHz.length, greaterThan(0));
      expect(result.voicedProb.length, result.pitchHz.length);
    });

    test('estimates pitch for a pure sine wave close to nominal frequency', () {
      const sampleRate = 44100.0;
      const freq = 440.0;
      final n = sampleRate.toInt();
      final samples = Float32List(n);
      for (var i = 0; i < n; i++) {
        samples[i] = math.sin(2 * math.pi * freq * i / sampleRate);
      }

      final result = estimatePitchYin(samples, sampleRate);
      expect(result.pitchHz.length, greaterThan(0));

      final firstPitch = result.pitchHz.cast<double?>().firstWhere(
        (p) => p != null,
        orElse: () => null,
      );
      expect(firstPitch, isNotNull);
      expect(firstPitch!, closeTo(freq, freq * 0.05));
    });

    test('passes through custom frameSize and hopSize', () {
      final samples = Float32List(8192);
      for (var i = 0; i < samples.length; i++) {
        samples[i] = math.sin(2 * math.pi * 440 * i / 44100);
      }

      const frameSize = 2048;
      const hopSize = 512;
      final result = estimatePitchYin(
        samples,
        44100,
        frameSize: frameSize,
        hopSize: hopSize,
      );

      expect(result.frameSize, frameSize);
      expect(result.hopSize, hopSize);

      expect(result.pitchHz.length, 13);
      expect(result.voicedProb.length, 13);
    });

    test('yinThreshold of 0 rejects all frames (no pitch found)', () {
      const sampleRate = 44100.0;
      final samples = Float32List(sampleRate.toInt());
      for (var i = 0; i < samples.length; i++) {
        samples[i] = math.sin(2 * math.pi * 440 * i / sampleRate);
      }

      final result = estimatePitchYin(samples, sampleRate, yinThreshold: 0.0);
      expect(result.pitchHz, everyElement(isNull));
      expect(result.voicedProb, everyElement(0.0));
    });
  });

  group('pitchAtEnvelopeTimes', () {
    YinPitchSeries makeSeries({
      int nFrames = 5,
      double sampleRate = 44100,
      int hopSize = 128,
      List<double?>? pitches,
    }) {
      final p =
          pitches ?? List<double?>.generate(nFrames, (i) => 200.0 + i * 50.0);
      return YinPitchSeries(
        sampleRate: sampleRate,
        frameSize: 4096,
        hopSize: hopSize,
        pitchHz: List<double?>.from(p),
        voicedProb: List<double>.generate(nFrames, (_) => 0.8),
      );
    }

    test('returns empty list for empty envelope', () {
      final yin = makeSeries();
      final result = pitchAtEnvelopeTimes(envelope: [], yin: yin);
      expect(result, isEmpty);
    });

    test('returns all nulls when no pitch frames exist', () {
      final yin = makeSeries(nFrames: 0, pitches: []);
      final envelope = [
        const WaveformPoint(t: 0.0, amp: 0.5),
        const WaveformPoint(t: 0.5, amp: 0.8),
      ];
      final result = pitchAtEnvelopeTimes(envelope: envelope, yin: yin);
      expect(result, [null, null]);
    });

    test('maps each envelope point to the nearest pitch frame', () {
      const sr = 44100.0;
      const hop = 128;
      final yin = makeSeries(nFrames: 5, sampleRate: sr, hopSize: hop);
      final hopSec = hop / sr;
      final envelope = [
        const WaveformPoint(t: 0.0, amp: 0.5),
        WaveformPoint(t: hopSec * 1.1, amp: 0.6),
        WaveformPoint(t: hopSec * 3.0, amp: 0.7),
      ];
      final result = pitchAtEnvelopeTimes(envelope: envelope, yin: yin);
      expect(result, [200.0, 250.0, 350.0]);
    });

    test('clamps index to valid frame range', () {
      const sr = 44100.0;
      const hop = 128;
      final yin = makeSeries(nFrames: 1, sampleRate: sr, hopSize: hop);
      final envelope = [
        const WaveformPoint(t: -1.0, amp: 0.5),
        const WaveformPoint(t: 100.0, amp: 0.8),
      ];
      final result = pitchAtEnvelopeTimes(envelope: envelope, yin: yin);
      expect(result, [200.0, 200.0]);
    });

    test('filters frames below minVoicedProb threshold', () {
      final yin = YinPitchSeries(
        sampleRate: 44100,
        frameSize: 4096,
        hopSize: 128,
        pitchHz: [200.0, null, 300.0],
        voicedProb: [0.9, 0.0, 0.1],
      );
      final envelope = [
        const WaveformPoint(t: 0.0, amp: 0.5),
        const WaveformPoint(t: 128 / 44100, amp: 0.6),
        const WaveformPoint(t: 2 * 128 / 44100, amp: 0.7),
      ];
      final result = pitchAtEnvelopeTimes(envelope: envelope, yin: yin);
      expect(result, [200.0, null, null]);
    });

    test('rejects non-positive or non-finite pitch values', () {
      final yin = YinPitchSeries(
        sampleRate: 44100,
        frameSize: 4096,
        hopSize: 128,
        pitchHz: [200.0, -5.0, double.infinity, double.nan, 0.0],
        voicedProb: [0.9, 0.9, 0.9, 0.9, 0.9],
      );
      final hopSec = 128 / 44100;
      final envelope = List<WaveformPoint>.generate(
        5,
        (i) => WaveformPoint(t: i * hopSec, amp: 0.5),
      );
      final result = pitchAtEnvelopeTimes(envelope: envelope, yin: yin);
      expect(result, [200.0, null, null, null, null]);
    });
  });
}
