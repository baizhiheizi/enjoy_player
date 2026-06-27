import 'dart:async';

import 'package:enjoy_player/features/player/application/quantized_position.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('quantizedPositionStream', () {
    test(
      'quantizes a single position to the nearest lower bucket boundary',
      () async {
        final source = Stream<Duration>.fromIterable([
          const Duration(milliseconds: 430),
        ]);
        final result = await quantizedPositionStream(
          source,
          bucketMs: 400,
        ).toList();
        expect(result, [const Duration(milliseconds: 400)]);
      },
    );

    test('emits a new value when crossing a bucket boundary', () async {
      final source = Stream<Duration>.fromIterable([
        const Duration(milliseconds: 100),
        const Duration(milliseconds: 850),
      ]);
      final result = await quantizedPositionStream(
        source,
        bucketMs: 400,
      ).toList();
      expect(result, [
        const Duration(milliseconds: 0),
        const Duration(milliseconds: 800),
      ]);
    });

    test('deduplicates consecutive equal quantized values', () async {
      final source = Stream<Duration>.fromIterable([
        const Duration(milliseconds: 50),
        const Duration(milliseconds: 100),
        const Duration(milliseconds: 380),
        const Duration(milliseconds: 401),
        const Duration(milliseconds: 800),
      ]);
      // bucketMs = 400 → bucket boundaries: 0, 400, 800.
      // Values 50/100/380 all land in [0,400) → 0.
      // Values 401 lands at 400.
      // Value 800 lands at 800.
      final result = await quantizedPositionStream(
        source,
        bucketMs: 400,
      ).toList();
      expect(result, [
        const Duration(milliseconds: 0),
        const Duration(milliseconds: 400),
        const Duration(milliseconds: 800),
      ]);
    });

    test('respects a 50ms bucket size (slider use case)', () async {
      final source = Stream<Duration>.fromIterable([
        const Duration(milliseconds: 0),
        const Duration(milliseconds: 49),
        const Duration(milliseconds: 50),
        const Duration(milliseconds: 99),
        const Duration(milliseconds: 100),
      ]);
      final result = await quantizedPositionStream(
        source,
        bucketMs: 50,
      ).toList();
      expect(result, [
        const Duration(milliseconds: 0),
        const Duration(milliseconds: 50),
        const Duration(milliseconds: 100),
      ]);
    });

    test('truncates (floor), never rounds up', () async {
      final source = Stream<Duration>.fromIterable([
        const Duration(milliseconds: 399),
        const Duration(milliseconds: 400),
        const Duration(milliseconds: 999),
      ]);
      final result = await quantizedPositionStream(
        source,
        bucketMs: 400,
      ).toList();
      // 399 → bucket 0; 400 → bucket 400; 999 → bucket 800.
      expect(result, [
        const Duration(milliseconds: 0),
        const Duration(milliseconds: 400),
        const Duration(milliseconds: 800),
      ]);
    });

    test('deduplicates adjacent identical bucket values', () async {
      final source = Stream<Duration>.fromIterable([
        const Duration(milliseconds: 401),
        const Duration(milliseconds: 500),
        const Duration(milliseconds: 600),
      ]);
      // All three land in bucket 400; only the first should be emitted.
      final result = await quantizedPositionStream(
        source,
        bucketMs: 400,
      ).toList();
      expect(result, [const Duration(milliseconds: 400)]);
    });

    test('emits nothing for an empty source', () async {
      final source = const Stream<Duration>.empty();
      final result = await quantizedPositionStream(
        source,
        bucketMs: 400,
      ).toList();
      expect(result, isEmpty);
    });
  });
}
