import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/ai/domain/models/asr_result.dart';
import 'package:enjoy_player/features/asr/domain/asr_timeline_builder.dart';

void main() {
  group('AsrTimelineBuilder — word-level path', () {
    test('groups consecutive words into a single readable line', () {
      final result = const AsrResult(
        text: 'Hello world.',
        segments: [
          AsrSegment(
            start: 0,
            end: 2.0,
            text: 'Hello world.',
            words: [
              AsrWord(word: 'Hello', start: 0.0, end: 0.5),
              AsrWord(word: 'world.', start: 0.6, end: 1.2),
            ],
          ),
        ],
      );

      final lines = buildAsrTranscriptLines(
        result: result,
        mediaDurationMs: 5000,
      );

      expect(lines, hasLength(1));
      expect(lines.first.text, 'Hello world.');
      expect(lines.first.startMs, 0);
      expect(lines.first.durationMs, 1200);
    });

    test('breaks on sentence terminator', () {
      final result = const AsrResult(
        text: 'Hi. There.',
        segments: [
          AsrSegment(
            start: 0,
            end: 2.0,
            text: 'Hi. There.',
            words: [
              AsrWord(word: 'Hi.', start: 0.0, end: 0.3),
              AsrWord(word: 'There.', start: 0.4, end: 1.0),
            ],
          ),
        ],
      );

      final lines = buildAsrTranscriptLines(
        result: result,
        mediaDurationMs: 5000,
      );

      expect(lines, hasLength(2));
      expect(lines[0].text, 'Hi.');
      expect(lines[1].text, 'There.');
    });

    test('breaks on long pause between words', () {
      final result = const AsrResult(
        text: 'Hello world',
        segments: [
          AsrSegment(
            start: 0,
            end: 5.0,
            text: 'Hello world',
            words: [
              AsrWord(word: 'Hello', start: 0.0, end: 0.5),
              // 800 ms gap > 350 ms threshold
              AsrWord(word: 'world', start: 1.3, end: 1.8),
            ],
          ),
        ],
      );

      final lines = buildAsrTranscriptLines(
        result: result,
        mediaDurationMs: 5000,
      );

      expect(lines, hasLength(2));
      expect(lines[0].text, 'Hello');
      expect(lines[1].text, 'world');
    });

    test('breaks on maxLineDurationMs cap', () {
      // 8 second total at default 6000 ms cap → 2 lines
      final result = AsrResult(
        text: 'a b c d e f g h',
        segments: [
          AsrSegment(
            start: 0,
            end: 8.0,
            text: 'a b c d e f g h',
            words: List.generate(8, (i) {
              return AsrWord(
                word: String.fromCharCode(97 + i),
                start: i * 1.0,
                end: i * 1.0 + 0.9,
              );
            }),
          ),
        ],
      );

      final lines = buildAsrTranscriptLines(
        result: result,
        mediaDurationMs: 8000,
      );

      expect(lines.length, greaterThanOrEqualTo(2));
    });

    test('output is deterministic for identical input', () {
      final result = const AsrResult(
        text: 'Same input',
        segments: [
          AsrSegment(
            start: 0,
            end: 1.0,
            text: 'Same input',
            words: [
              AsrWord(word: 'Same', start: 0.0, end: 0.5),
              AsrWord(word: 'input', start: 0.5, end: 1.0),
            ],
          ),
        ],
      );

      final a = buildAsrTranscriptLines(result: result, mediaDurationMs: 1000);
      final b = buildAsrTranscriptLines(result: result, mediaDurationMs: 1000);

      expect(a, equals(b));
    });
  });

  group('AsrTimelineBuilder — segment-level fallback', () {
    test('coalesces adjacent short segments with no words', () {
      final result = const AsrResult(
        text: 'One two three',
        segments: [
          AsrSegment(start: 0, end: 0.3, text: 'One', words: null),
          AsrSegment(start: 0.4, end: 0.7, text: 'two', words: null),
          AsrSegment(start: 0.8, end: 1.1, text: 'three.', words: null),
        ],
      );

      final lines = buildAsrTranscriptLines(
        result: result,
        mediaDurationMs: 5000,
      );

      // "three." ends with terminator → first two merge, then break.
      expect(lines.length, lessThanOrEqualTo(2));
      expect(lines.last.text.endsWith('three.'), isTrue);
    });
  });

  group('AsrTimelineBuilder — plain-text fallback', () {
    test('distributes evenly across media duration when no segments', () {
      final result = const AsrResult(text: 'Hello world.', segments: null);

      final lines = buildAsrTranscriptLines(
        result: result,
        mediaDurationMs: 10000,
      );

      expect(lines, hasLength(1));
      expect(lines.first.text, 'Hello world.');
      expect(lines.first.startMs, 0);
      expect(lines.first.durationMs, 10000);
    });

    test('splits on terminators when no segments', () {
      final result = const AsrResult(
        text: 'First. Second. Third.',
        segments: null,
      );

      final lines = buildAsrTranscriptLines(
        result: result,
        mediaDurationMs: 9000,
      );

      expect(lines.length, 3);
      expect(lines.map((l) => l.text).toList(), [
        'First.',
        'Second.',
        'Third.',
      ]);
      // Evenly distributed.
      expect(lines[0].startMs, 0);
      expect(lines[1].startMs, 3000);
      expect(lines[2].startMs, 6000);
      // Last line absorbs the remainder.
      expect(lines[2].startMs + lines[2].durationMs, 9000);
    });
  });

  group('AsrTimelineBuilder — empty input', () {
    test('returns [] for empty text and no segments', () {
      final result = const AsrResult(text: '', segments: null);
      expect(
        buildAsrTranscriptLines(result: result, mediaDurationMs: 1000),
        isEmpty,
      );
    });

    test('returns [] for whitespace text', () {
      final result = const AsrResult(text: '   \n  ', segments: null);
      expect(
        buildAsrTranscriptLines(result: result, mediaDurationMs: 1000),
        isEmpty,
      );
    });
  });

  group('AsrTimelineBuilder — round-trip', () {
    test('produces TranscriptLine with startMs / durationMs in ms', () {
      final result = const AsrResult(
        text: 'Hi.',
        segments: [
          AsrSegment(
            start: 1.5,
            end: 2.5,
            text: 'Hi.',
            words: [AsrWord(word: 'Hi.', start: 1.5, end: 2.5)],
          ),
        ],
      );
      final lines = buildAsrTranscriptLines(
        result: result,
        mediaDurationMs: 5000,
      );
      expect(lines, hasLength(1));
      final l = lines.first;
      expect(l, isA<TranscriptLine>());
      expect(l.startMs, 1500);
      expect(l.durationMs, 1000);
    });
  });
}
