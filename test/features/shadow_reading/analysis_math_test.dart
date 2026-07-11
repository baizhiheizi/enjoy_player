import 'dart:typed_data';

import 'package:enjoy_player/features/shadow_reading/domain/echo_region_analysis.dart';
import 'package:enjoy_player/features/shadow_reading/domain/waveform_envelope.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('computePeakEnvelope', () {
    test('normalizes peak envelope', () {
      final samples = Float32List.fromList([0, 1, 0, -1, 0, 0.5]);
      final env = computePeakEnvelope(samples, 6.0, points: 8);
      expect(env.isNotEmpty, true);
      expect(env.every((p) => p.amp >= 0 && p.amp <= 1), true);
    });
  });

  group('mergeUserPitchOntoReference', () {
    test('scales user times onto reference duration', () {
      const ref = [
        EchoRegionSeriesPoint(t: 0, ampRef: 0.5, pitchRefHz: 100),
        EchoRegionSeriesPoint(t: 1, ampRef: 0.5, pitchRefHz: 110),
      ];
      const user = [
        EchoRegionSeriesPoint(t: 0, ampRef: 0.3, pitchRefHz: 90),
        EchoRegionSeriesPoint(t: 1, ampRef: 0.4, pitchRefHz: 95),
      ];
      final merged = mergeUserPitchOntoReference(
        referencePoints: ref,
        userPoints: user,
        referenceDurationSec: 2,
        userDurationSec: 2,
      );
      expect(merged.length, 2);
      expect(merged[0].pitchUserHz, 90);
    });

    test('EchoRegionSeriesPoint has value equality', () {
      const a = EchoRegionSeriesPoint(
        t: 1,
        ampRef: 0.5,
        pitchRefHz: 100,
        ampUser: 0.3,
        pitchUserHz: 90,
      );
      const b = EchoRegionSeriesPoint(
        t: 1,
        ampRef: 0.5,
        pitchRefHz: 100,
        ampUser: 0.3,
        pitchUserHz: 90,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });

  group('EchoMergedSeriesMemo', () {
    final ref = const EchoRegionAnalysisResult(
      points: [
        EchoRegionSeriesPoint(t: 0, ampRef: 0.5, pitchRefHz: 100),
        EchoRegionSeriesPoint(t: 1, ampRef: 0.5, pitchRefHz: 110),
      ],
      durationSeconds: 2,
      sampleRate: 44100,
    );
    final user = const EchoRegionAnalysisResult(
      points: [EchoRegionSeriesPoint(t: 0, ampRef: 0.3, pitchRefHz: 90)],
      durationSeconds: 1.5,
      sampleRate: 44100,
    );

    test('returns the same list instance across ticks (built once)', () {
      final memo = EchoMergedSeriesMemo();
      final first = memo.resolve(
        reference: ref,
        user: user,
        referenceDurationSec: 2,
        userDurationSec: 1.5,
      );
      // A playback tick only changes the progress cursor — not the merge
      // inputs — so the merged series must be the identical list instance.
      final second = memo.resolve(
        reference: ref,
        user: user,
        referenceDurationSec: 2,
        userDurationSec: 1.5,
      );
      expect(identical(first, second), isTrue);
    });

    test('recomputes when the reference or user result changes', () {
      final memo = EchoMergedSeriesMemo();
      final a = memo.resolve(
        reference: ref,
        user: null,
        referenceDurationSec: 2,
        userDurationSec: 0,
      );
      final b = memo.resolve(
        reference: ref,
        user: user,
        referenceDurationSec: 2,
        userDurationSec: 1.5,
      );
      expect(identical(a, b), isFalse);
    });

    test('invalidate forces a rebuild on the next resolve', () {
      final memo = EchoMergedSeriesMemo();
      final first = memo.resolve(
        reference: ref,
        user: user,
        referenceDurationSec: 2,
        userDurationSec: 1.5,
      );
      memo.invalidate();
      final second = memo.resolve(
        reference: ref,
        user: user,
        referenceDurationSec: 2,
        userDurationSec: 1.5,
      );
      expect(identical(first, second), isFalse);
    });
  });
}
