import 'dart:convert';

import 'package:enjoy_player/features/craft/domain/transcript_timestamp_estimator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('estimateTimeline', () {
    test('single sentence returns one entry spanning full duration', () {
      final timeline = estimateTimeline(
        text: 'Hello world.',
        totalDurationMs: 5000,
      );
      expect(timeline, hasLength(1));
      expect(timeline.first['start'], 0);
      expect(timeline.first['duration'], 5000);
    });

    test('multiple sentences distribute duration proportionally', () {
      final timeline = estimateTimeline(
        text: 'Short. Longer sentence here.',
        totalDurationMs: 10000,
      );
      expect(timeline.length, greaterThanOrEqualTo(2));

      // First sentence has fewer chars → shorter duration.
      expect(timeline.first['start'], 0);
      expect(timeline.last['start'], greaterThan(0));

      // Total durations should sum to approximately totalDurationMs.
      final sumDurations = timeline
          .map((e) => e['duration'] as int)
          .fold(0, (a, b) => a + b);
      expect(sumDurations, closeTo(10000, 100));
    });

    test('empty text returns single entry with full duration', () {
      final timeline = estimateTimeline(text: '', totalDurationMs: 3000);
      expect(timeline, hasLength(1));
      expect(timeline.first['start'], 0);
    });

    test('CJK sentence boundaries are respected', () {
      final timeline = estimateTimeline(
        text: '你好世界。这是一个测试。',
        totalDurationMs: 8000,
      );
      expect(timeline.length, greaterThanOrEqualTo(2));
    });

    test('encodeTimelineJson produces valid JSON', () {
      final json = encodeTimelineJson(
        text: 'Test sentence one. Test sentence two.',
        totalDurationMs: 6000,
      );
      final decoded = jsonDecode(json) as List;
      expect(decoded.length, greaterThanOrEqualTo(2));
      expect(decoded.first, isA<Map>());
      expect(decoded.first['text'], isA<String>());
      expect(decoded.first['start'], isA<int>());
      expect(decoded.first['duration'], isA<int>());
    });
  });
}
