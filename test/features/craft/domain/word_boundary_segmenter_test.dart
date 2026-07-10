import 'package:enjoy_player/features/craft/domain/craft_synthesizer.dart';
import 'package:enjoy_player/features/craft/domain/word_boundary_segmenter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('segmentWordBoundaries', () {
    test('returns empty for empty input', () {
      expect(segmentWordBoundaries([]), isEmpty);
    });

    test('groups short text into one segment', () {
      final boundaries = [
        const CraftWordBoundary(
          text: 'Hello',
          audioOffsetMs: 0,
          durationMs: 400,
        ),
        const CraftWordBoundary(
          text: 'world.',
          audioOffsetMs: 400,
          durationMs: 500,
        ),
      ];
      final segments = segmentWordBoundaries(boundaries);
      expect(segments, hasLength(1));
      expect(segments.first.text, 'Hello world.');
      expect(segments.first.startMs, 0);
      expect(segments.first.durationMs, 900);
    });

    test('splits on sentence-ending punctuation', () {
      final boundaries = [
        const CraftWordBoundary(
          text: 'Hello',
          audioOffsetMs: 0,
          durationMs: 300,
        ),
        const CraftWordBoundary(
          text: 'world.',
          audioOffsetMs: 300,
          durationMs: 400,
        ),
        const CraftWordBoundary(
          text: 'How',
          audioOffsetMs: 800,
          durationMs: 300,
        ),
        const CraftWordBoundary(
          text: 'are',
          audioOffsetMs: 1100,
          durationMs: 300,
        ),
        const CraftWordBoundary(
          text: 'you?',
          audioOffsetMs: 1400,
          durationMs: 400,
        ),
      ];
      final segments = segmentWordBoundaries(boundaries);
      expect(segments, hasLength(2));
      expect(segments[0].text, 'Hello world.');
      expect(segments[1].text, 'How are you?');
      expect(segments[0].startMs, 0);
      expect(segments[1].startMs, 800);
    });

    test('splits long sentences at preferred word count', () {
      final boundaries = [
        for (var i = 0; i < 12; i++)
          CraftWordBoundary(
            text: 'word$i',
            audioOffsetMs: i * 300,
            durationMs: 300,
          ),
      ];
      final segments = segmentWordBoundaries(
        boundaries,
        preferredWordsPerSegment: 6,
      );
      expect(segments.length, greaterThanOrEqualTo(2));
    });

    test('timestamps come from word boundaries', () {
      final boundaries = [
        const CraftWordBoundary(
          text: 'Hello',
          audioOffsetMs: 100,
          durationMs: 400,
        ),
        const CraftWordBoundary(
          text: 'world.',
          audioOffsetMs: 600,
          durationMs: 500,
        ),
      ];
      final segments = segmentWordBoundaries(boundaries);
      expect(segments.first.startMs, 100);
      expect(segments.first.durationMs, 1000);
    });
  });

  group('segmentsToTimelineJson', () {
    test('produces valid JSON', () {
      final segments = [
        const TranscriptSegment(
          text: 'Hello world.',
          startMs: 0,
          durationMs: 900,
        ),
      ];
      final json = segmentsToTimelineJson(segments);
      expect(json, contains('Hello world.'));
      expect(json, contains('"start":0'));
      expect(json, contains('"duration":900'));
    });
  });
}
