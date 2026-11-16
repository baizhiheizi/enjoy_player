import 'package:enjoy_player/core/echo/echo_region_key.dart';
import 'package:enjoy_player/features/shadow_reading/application/shadow_take_providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const key = EchoRegionKey(
    targetType: 'video',
    targetId: 'v-1',
    startMs: 1500,
    durationMs: 2500,
    referenceText: 'Hello world',
    language: 'en',
  );

  group('EchoRegionKey.fromSeconds', () {
    test('rounds the seconds window to whole milliseconds', () {
      final key = EchoRegionKey.fromSeconds(
        targetType: 'video',
        targetId: 'v-1',
        referenceText: 'Hello world',
        language: 'en',
        startSec: 1.2345,
        endSec: 4.5675,
      );
      expect(key.startMs, 1235);
      expect(key.durationMs, 3333);
    });

    test('rounds a sub-millisecond window down to zero duration', () {
      final key = EchoRegionKey.fromSeconds(
        targetType: 'video',
        targetId: 'v-1',
        referenceText: 'Hello world',
        language: 'en',
        startSec: 0.9995,
        endSec: 0.99999,
      );
      expect(key.startMs, 1000);
      expect(key.durationMs, 0);
    });

    test('endMs derives from startMs and durationMs', () {
      expect(key.endMs, key.startMs + key.durationMs);
      const zeroLength = EchoRegionKey(
        targetType: 'video',
        targetId: 'v-1',
        startMs: 7,
        durationMs: 0,
        referenceText: '',
        language: 'en',
      );
      expect(zeroLength.endMs, 7);
    });
  });

  group('EchoRegionRecordingsQuery.of', () {
    test('maps every field from the key without the reference text', () {
      final query = EchoRegionRecordingsQuery.of(key);
      expect(query.targetType, key.targetType);
      expect(query.targetId, key.targetId);
      expect(query.language, key.language);
      expect(query.echoStartMs, key.startMs);
      expect(query.echoEndMs, key.endMs);
    });

    test('reference text does not change the query identity', () {
      final other = const EchoRegionKey(
        targetType: 'video',
        targetId: 'v-1',
        startMs: 1500,
        durationMs: 2500,
        referenceText: 'A different cue wording',
        language: 'en',
      );
      expect(
        EchoRegionRecordingsQuery.of(other),
        EchoRegionRecordingsQuery.of(key),
      );
    });
  });

  group('EchoRegionKey equality', () {
    test('equal keys share hashCode', () {
      final same = const EchoRegionKey(
        targetType: 'video',
        targetId: 'v-1',
        startMs: 1500,
        durationMs: 2500,
        referenceText: 'Hello world',
        language: 'en',
      );
      expect(same, key);
      expect(same.hashCode, key.hashCode);
    });

    test('every field participates in equality', () {
      expect(
        const EchoRegionKey(
          targetType: 'audio',
          targetId: 'v-1',
          startMs: 1500,
          durationMs: 2500,
          referenceText: 'Hello world',
          language: 'en',
        ),
        isNot(key),
      );
      expect(
        const EchoRegionKey(
          targetType: 'video',
          targetId: 'v-2',
          startMs: 1500,
          durationMs: 2500,
          referenceText: 'Hello world',
          language: 'en',
        ),
        isNot(key),
      );
      expect(
        const EchoRegionKey(
          targetType: 'video',
          targetId: 'v-1',
          startMs: 1501,
          durationMs: 2500,
          referenceText: 'Hello world',
          language: 'en',
        ),
        isNot(key),
      );
      expect(
        const EchoRegionKey(
          targetType: 'video',
          targetId: 'v-1',
          startMs: 1500,
          durationMs: 2501,
          referenceText: 'Hello world',
          language: 'en',
        ),
        isNot(key),
      );
      expect(
        const EchoRegionKey(
          targetType: 'video',
          targetId: 'v-1',
          startMs: 1500,
          durationMs: 2500,
          referenceText: 'Hello there',
          language: 'en',
        ),
        isNot(key),
      );
      expect(
        const EchoRegionKey(
          targetType: 'video',
          targetId: 'v-1',
          startMs: 1500,
          durationMs: 2500,
          referenceText: 'Hello world',
          language: 'nb',
        ),
        isNot(key),
      );
    });
  });
}
