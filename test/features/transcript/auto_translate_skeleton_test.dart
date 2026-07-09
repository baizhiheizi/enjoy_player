import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/transcript/domain/auto_translate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildAutoTranslateSkeleton', () {
    test('copies timings with empty text', () {
      const primary = [
        TranscriptLine(text: 'Hello', startMs: 0, durationMs: 1000),
        TranscriptLine(text: 'World', startMs: 1000, durationMs: 500),
      ];
      final skeleton = buildAutoTranslateSkeleton(primary);
      expect(skeleton.length, 2);
      expect(skeleton[0].text, '');
      expect(skeleton[0].startMs, 0);
      expect(skeleton[0].durationMs, 1000);
      expect(skeleton[1].startMs, 1000);
    });
  });

  group('orderPendingLineIndexes', () {
    test('prefers lines near anchor index', () {
      final ordered = orderPendingLineIndexes(
        anchorIndex: 10,
        pending: [0, 5, 11, 20],
      );
      expect(ordered.first, 11);
      expect(ordered[1], 5);
    });
  });

  group('isAutoTranslateTimelineStale', () {
    test('stale when reference primary id mismatches', () {
      const primary = [
        TranscriptLine(text: 'a', startMs: 0, durationMs: 1000),
      ];
      const ai = [TranscriptLine(text: '', startMs: 0, durationMs: 1000)];
      expect(
        isAutoTranslateTimelineStale(
          referencePrimaryId: 'old',
          primaryId: 'new',
          primaryLines: primary,
          aiLines: ai,
        ),
        isTrue,
      );
    });

    test('stale when length differs', () {
      const primary = [
        TranscriptLine(text: 'a', startMs: 0, durationMs: 1000),
        TranscriptLine(text: 'b', startMs: 1000, durationMs: 500),
      ];
      const ai = [TranscriptLine(text: 'x', startMs: 0, durationMs: 1000)];
      expect(
        isAutoTranslateTimelineStale(
          referencePrimaryId: 'p1',
          primaryId: 'p1',
          primaryLines: primary,
          aiLines: ai,
        ),
        isTrue,
      );
    });
  });
}
