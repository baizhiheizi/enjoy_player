import 'dart:math' as math;
import 'dart:typed_data';

import 'package:enjoy_player/features/shadow_reading/application/echo_region_pitch_analyzer.dart';
import 'package:flutter_test/flutter_test.dart';

Float32List _silent(int n) => Float32List(n);

Float32List _tone({required int n, required double hz, required double sr}) {
  final out = Float32List(n);
  for (var i = 0; i < n; i++) {
    out[i] = 0.5 * math.sin(2 * math.pi * hz * i / sr);
  }
  return out;
}

Float32List _alternatingTones({
  required int n,
  required double lowHz,
  required double highHz,
  required double sr,
}) {
  final out = Float32List(n);
  final half = n ~/ 2;
  for (var i = 0; i < half; i++) {
    out[i] = 0.5 * math.sin(2 * math.pi * lowHz * i / sr);
  }
  for (var i = half; i < n; i++) {
    out[i] = 0.5 * math.sin(2 * math.pi * highHz * (i - half) / sr);
  }
  return out;
}

void main() {
  group('analyzePcmSamples', () {
    test('returns the expected sampleRate and durationSeconds', () {
      final samples = _tone(n: 16000 * 2, hz: 200, sr: 16000);
      final result = analyzePcmSamples(samples, 16000);
      expect(result.sampleRate, 16000);
      expect(result.durationSeconds, closeTo(2.0, 1e-9));
      expect(result.points.length, greaterThanOrEqualTo(520));
      expect(result.points.length, lessThan(560));
    });

    test('silent input still produces envelope points with amp near 0', () {
      final samples = _silent(16000 * 1);
      final result = analyzePcmSamples(samples, 16000);
      expect(result.points, isNotEmpty);
      for (final p in result.points) {
        expect(p.ampRef, lessThan(0.5));
      }
      for (final p in result.points) {
        expect(p.pitchRefHz, anyOf(isNull, lessThan(50.0)));
      }
    });

    test('each series point carries the envelope timestamp and amp', () {
      final samples = _tone(n: 16000, hz: 220, sr: 16000);
      final result = analyzePcmSamples(samples, 16000);
      expect(result.points.first.t, closeTo(0.0, 1e-6));
      expect(result.points.last.t, closeTo(1.0, 1e-3));
      for (var i = 1; i < result.points.length; i++) {
        expect(
          result.points[i].t,
          greaterThanOrEqualTo(result.points[i - 1].t),
        );
      }
    });

    test('tonal input near A 220 Hz yields a non-empty pitch series', () {
      final samples = _tone(n: 16000 * 2, hz: 220, sr: 16000);
      final result = analyzePcmSamples(samples, 16000);
      final voicedHz = result.points
          .map((p) => p.pitchRefHz)
          .whereType<double>()
          .toList();
      expect(voicedHz, isNotEmpty);
      for (final hz in voicedHz) {
        expect(hz, greaterThan(110));
        expect(hz, lessThan(440));
      }
    });

    test('different pitches in the same buffer show up as different Hz', () {
      final samples = _alternatingTones(
        n: 16000 * 2,
        lowHz: 150,
        highHz: 300,
        sr: 16000,
      );
      final result = analyzePcmSamples(samples, 16000);
      final voiced = result.points
          .map((p) => p.pitchRefHz)
          .whereType<double>()
          .toList();
      expect(voiced, isNotEmpty);
      final minHz = voiced.reduce(math.min);
      final maxHz = voiced.reduce(math.max);
      expect(maxHz / minHz, greaterThan(1.5));
    });
  });
}
