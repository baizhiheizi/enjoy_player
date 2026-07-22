import 'package:enjoy_player/features/shadow_reading/domain/echo_region_analysis.dart';
import 'package:enjoy_player/features/shadow_reading/domain/waveform_envelope.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EchoRegionSeriesPoint.copyWith', () {
    const original = EchoRegionSeriesPoint(
      t: 1.0,
      ampRef: 0.5,
      pitchRefHz: 220,
      ampUser: 0.3,
      pitchUserHz: 200,
    );

    test('returns identical values when no arguments given', () {
      final copy = original.copyWith();
      expect(copy, equals(original));
    });

    test('overrides only specified fields', () {
      final copy = original.copyWith(t: 2.0, ampUser: 0.9);
      expect(copy.t, 2.0);
      expect(copy.ampRef, 0.5);
      expect(copy.pitchRefHz, 220);
      expect(copy.ampUser, 0.9);
      expect(copy.pitchUserHz, 200);
    });

    test('can override pitch fields', () {
      final copy = original.copyWith(pitchRefHz: 440, pitchUserHz: 430);
      expect(copy.pitchRefHz, 440);
      expect(copy.pitchUserHz, 430);
      expect(copy.t, 1.0);
    });
  });

  group('EchoRegionSeriesPoint equality', () {
    test('points with different t are not equal', () {
      const a = EchoRegionSeriesPoint(t: 0, ampRef: 0.5);
      const b = EchoRegionSeriesPoint(t: 1, ampRef: 0.5);
      expect(a, isNot(equals(b)));
    });

    test('points with different ampRef are not equal', () {
      const a = EchoRegionSeriesPoint(t: 0, ampRef: 0.5);
      const b = EchoRegionSeriesPoint(t: 0, ampRef: 0.8);
      expect(a, isNot(equals(b)));
    });

    test('points with different pitchRefHz are not equal', () {
      const a = EchoRegionSeriesPoint(t: 0, ampRef: 0.5, pitchRefHz: 100);
      const b = EchoRegionSeriesPoint(t: 0, ampRef: 0.5, pitchRefHz: 200);
      expect(a, isNot(equals(b)));
    });

    test('points with different ampUser are not equal', () {
      const a = EchoRegionSeriesPoint(t: 0, ampRef: 0.5, ampUser: 0.1);
      const b = EchoRegionSeriesPoint(t: 0, ampRef: 0.5, ampUser: 0.2);
      expect(a, isNot(equals(b)));
    });

    test('points with different pitchUserHz are not equal', () {
      const a = EchoRegionSeriesPoint(t: 0, ampRef: 0.5, pitchUserHz: 100);
      const b = EchoRegionSeriesPoint(t: 0, ampRef: 0.5, pitchUserHz: 200);
      expect(a, isNot(equals(b)));
    });

    test('null vs non-null pitch fields are not equal', () {
      const a = EchoRegionSeriesPoint(t: 0, ampRef: 0.5, pitchRefHz: null);
      const b = EchoRegionSeriesPoint(t: 0, ampRef: 0.5, pitchRefHz: 100);
      expect(a, isNot(equals(b)));
    });

    test('is not equal to a non-EchoRegionSeriesPoint object', () {
      const a = EchoRegionSeriesPoint(t: 0, ampRef: 0.5);
      // ignore: unrelated_type_equality_checks
      expect(a == 'not a point', isFalse);
    });

    test('identical instance is equal to itself', () {
      const a = EchoRegionSeriesPoint(t: 0, ampRef: 0.5, pitchRefHz: 100);
      expect(identical(a, a), isTrue);
      expect(a, equals(a));
    });

    test('hashCode differs for different points', () {
      const a = EchoRegionSeriesPoint(t: 0, ampRef: 0.5, pitchRefHz: 100);
      const b = EchoRegionSeriesPoint(t: 1, ampRef: 0.5, pitchRefHz: 100);
      // Not guaranteed, but extremely likely for distinct values.
      expect(a.hashCode, isNot(equals(b.hashCode)));
    });
  });

  group('mergeUserPitchOntoReference edge cases', () {
    test('returns empty list when referencePoints is empty', () {
      final result = mergeUserPitchOntoReference(
        referencePoints: [],
        userPoints: const [
          EchoRegionSeriesPoint(t: 0, ampRef: 0.5, pitchRefHz: 100),
        ],
        referenceDurationSec: 2,
        userDurationSec: 2,
      );
      expect(result, isEmpty);
    });

    test(
      'returns reference with zeroed user fields when userPoints is empty',
      () {
        const ref = [
          EchoRegionSeriesPoint(t: 0, ampRef: 0.5, pitchRefHz: 100),
          EchoRegionSeriesPoint(t: 1, ampRef: 0.7, pitchRefHz: 110),
        ];
        final result = mergeUserPitchOntoReference(
          referencePoints: ref,
          userPoints: [],
          referenceDurationSec: 2,
          userDurationSec: 2,
        );
        expect(result.length, 2);
        expect(result[0].ampUser, 0);
        expect(result[0].pitchUserHz, isNull);
        expect(result[1].ampUser, 0);
        expect(result[1].pitchUserHz, isNull);
        // Reference fields preserved.
        expect(result[0].ampRef, 0.5);
        expect(result[0].pitchRefHz, 100);
      },
    );

    test(
      'returns reference with zeroed user fields when userDurationSec <= 0',
      () {
        const ref = [EchoRegionSeriesPoint(t: 0, ampRef: 0.5, pitchRefHz: 100)];
        const user = [EchoRegionSeriesPoint(t: 0, ampRef: 0.3, pitchRefHz: 90)];
        final result = mergeUserPitchOntoReference(
          referencePoints: ref,
          userPoints: user,
          referenceDurationSec: 2,
          userDurationSec: 0,
        );
        expect(result.length, 1);
        expect(result[0].ampUser, 0);
        expect(result[0].pitchUserHz, isNull);
      },
    );

    test('user point beyond tolerance is not merged', () {
      // Reference points at t=0 and t=10; user point maps to t=5 which is
      // far from both (nearestDiff = 5 > 0.1 tolerance).
      const ref = [
        EchoRegionSeriesPoint(t: 0, ampRef: 0.5, pitchRefHz: 100),
        EchoRegionSeriesPoint(t: 10, ampRef: 0.5, pitchRefHz: 110),
      ];
      const user = [EchoRegionSeriesPoint(t: 5, ampRef: 0.3, pitchRefHz: 90)];
      final result = mergeUserPitchOntoReference(
        referencePoints: ref,
        userPoints: user,
        referenceDurationSec: 10,
        userDurationSec: 10,
      );
      expect(result.length, 2);
      // Neither reference point should have user data merged.
      expect(result[0].pitchUserHz, isNull);
      expect(result[1].pitchUserHz, isNull);
    });

    test('scales user time when durations differ', () {
      // Reference is 4s with points at t=0 and t=2.
      // User is 2s with a point at t=1 → mapped to 1*(4/2)=2.0 → matches ref[1].
      const ref = [
        EchoRegionSeriesPoint(t: 0, ampRef: 0.5, pitchRefHz: 100),
        EchoRegionSeriesPoint(t: 2, ampRef: 0.6, pitchRefHz: 110),
      ];
      const user = [EchoRegionSeriesPoint(t: 1, ampRef: 0.4, pitchRefHz: 95)];
      final result = mergeUserPitchOntoReference(
        referencePoints: ref,
        userPoints: user,
        referenceDurationSec: 4,
        userDurationSec: 2,
      );
      expect(result.length, 2);
      // User point at t=1 maps to t=2.0, matching ref[1].
      expect(result[1].pitchUserHz, 95);
      expect(result[1].ampUser, 0.4);
      // ref[0] untouched.
      expect(result[0].pitchUserHz, isNull);
    });

    test('multiple user points can map to the same reference point', () {
      const ref = [EchoRegionSeriesPoint(t: 0, ampRef: 0.5, pitchRefHz: 100)];
      const user = [
        EchoRegionSeriesPoint(t: 0, ampRef: 0.3, pitchRefHz: 90),
        EchoRegionSeriesPoint(t: 0.01, ampRef: 0.4, pitchRefHz: 95),
      ];
      final result = mergeUserPitchOntoReference(
        referencePoints: ref,
        userPoints: user,
        referenceDurationSec: 1,
        userDurationSec: 1,
      );
      // Last writer wins.
      expect(result[0].pitchUserHz, 95);
      expect(result[0].ampUser, 0.4);
    });
  });

  group('buildSeriesPoints', () {
    test('builds points from envelope and pitch list', () {
      const envelope = [
        WaveformPoint(t: 0.0, amp: 0.5),
        WaveformPoint(t: 0.5, amp: 0.8),
        WaveformPoint(t: 1.0, amp: 0.3),
      ];
      final pitchHz = <double?>[100, null, 200];
      final result = buildSeriesPoints(
        envelope: envelope,
        pitchHzList: pitchHz,
      );
      expect(result.length, 3);
      expect(result[0].t, 0.0);
      expect(result[0].ampRef, 0.5);
      expect(result[0].pitchRefHz, 100);
      expect(result[1].t, 0.5);
      expect(result[1].ampRef, 0.8);
      expect(result[1].pitchRefHz, isNull);
      expect(result[2].t, 1.0);
      expect(result[2].ampRef, 0.3);
      expect(result[2].pitchRefHz, 200);
    });

    test('returns empty list for empty inputs', () {
      final result = buildSeriesPoints(envelope: [], pitchHzList: []);
      expect(result, isEmpty);
    });

    test('user fields default to zero/null', () {
      const envelope = [WaveformPoint(t: 0.0, amp: 1.0)];
      final result = buildSeriesPoints(envelope: envelope, pitchHzList: [440]);
      expect(result[0].ampUser, 0);
      expect(result[0].pitchUserHz, isNull);
    });
  });

  group('EchoMergedSeriesMemo additional paths', () {
    test('returns empty list when reference is null', () {
      final memo = EchoMergedSeriesMemo();
      final result = memo.resolve(
        reference: null,
        user: null,
        referenceDurationSec: 2,
        userDurationSec: 0,
      );
      expect(result, isEmpty);
    });

    test('returns same empty instance for repeated null reference calls', () {
      final memo = EchoMergedSeriesMemo();
      final first = memo.resolve(
        reference: null,
        user: null,
        referenceDurationSec: 2,
        userDurationSec: 0,
      );
      final second = memo.resolve(
        reference: null,
        user: null,
        referenceDurationSec: 2,
        userDurationSec: 0,
      );
      expect(identical(first, second), isTrue);
    });

    test('returns ref.points directly when user is null', () {
      final ref = const EchoRegionAnalysisResult(
        points: [EchoRegionSeriesPoint(t: 0, ampRef: 0.5, pitchRefHz: 100)],
        durationSeconds: 2,
        sampleRate: 44100,
      );
      final memo = EchoMergedSeriesMemo();
      final result = memo.resolve(
        reference: ref,
        user: null,
        referenceDurationSec: 2,
        userDurationSec: 0,
      );
      expect(identical(result, ref.points), isTrue);
    });

    test('returns ref.points when userDurationSec is zero', () {
      final ref = const EchoRegionAnalysisResult(
        points: [EchoRegionSeriesPoint(t: 0, ampRef: 0.5, pitchRefHz: 100)],
        durationSeconds: 2,
        sampleRate: 44100,
      );
      final user = const EchoRegionAnalysisResult(
        points: [EchoRegionSeriesPoint(t: 0, ampRef: 0.3, pitchRefHz: 90)],
        durationSeconds: 1,
        sampleRate: 44100,
      );
      final memo = EchoMergedSeriesMemo();
      final result = memo.resolve(
        reference: ref,
        user: user,
        referenceDurationSec: 2,
        userDurationSec: 0,
      );
      // userDurationSec <= 0 means merge is skipped, ref.points returned.
      expect(identical(result, ref.points), isTrue);
    });

    test('recomputes when durations change but results stay same identity', () {
      final ref = const EchoRegionAnalysisResult(
        points: [EchoRegionSeriesPoint(t: 0, ampRef: 0.5, pitchRefHz: 100)],
        durationSeconds: 2,
        sampleRate: 44100,
      );
      final user = const EchoRegionAnalysisResult(
        points: [EchoRegionSeriesPoint(t: 0, ampRef: 0.3, pitchRefHz: 90)],
        durationSeconds: 1,
        sampleRate: 44100,
      );
      final memo = EchoMergedSeriesMemo();
      final first = memo.resolve(
        reference: ref,
        user: user,
        referenceDurationSec: 2,
        userDurationSec: 1,
      );
      final second = memo.resolve(
        reference: ref,
        user: user,
        referenceDurationSec: 3,
        userDurationSec: 1,
      );
      // Different duration → different key → recomputed.
      expect(identical(first, second), isFalse);
    });

    test('invalidate resets cache so next resolve recomputes', () {
      final ref = const EchoRegionAnalysisResult(
        points: [EchoRegionSeriesPoint(t: 0, ampRef: 0.5, pitchRefHz: 100)],
        durationSeconds: 2,
        sampleRate: 44100,
      );
      final user = const EchoRegionAnalysisResult(
        points: [EchoRegionSeriesPoint(t: 0, ampRef: 0.3, pitchRefHz: 90)],
        durationSeconds: 1,
        sampleRate: 44100,
      );
      final memo = EchoMergedSeriesMemo();
      final first = memo.resolve(
        reference: ref,
        user: user,
        referenceDurationSec: 2,
        userDurationSec: 1,
      );
      memo.invalidate();
      final second = memo.resolve(
        reference: ref,
        user: user,
        referenceDurationSec: 2,
        userDurationSec: 1,
      );
      // After invalidate, the merge is recomputed producing a new list.
      expect(identical(first, second), isFalse);
      // But the content is equivalent.
      expect(second, equals(first));
    });
  });

  group('EchoRegionAnalysisResult', () {
    test('stores points, durationSeconds, and sampleRate', () {
      const result = EchoRegionAnalysisResult(
        points: [
          EchoRegionSeriesPoint(t: 0, ampRef: 0.5, pitchRefHz: 100),
          EchoRegionSeriesPoint(t: 1, ampRef: 0.6, pitchRefHz: 110),
        ],
        durationSeconds: 2.5,
        sampleRate: 44100,
      );
      expect(result.points.length, 2);
      expect(result.durationSeconds, 2.5);
      expect(result.sampleRate, 44100);
    });
  });
}
