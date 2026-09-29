import 'dart:convert';

import 'package:enjoy_player/features/craft/domain/craft_synthesizer.dart';
import 'package:enjoy_player/features/craft/domain/word_boundary_segmenter.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds a [CraftWordBoundary] with offset/duration in milliseconds.
CraftWordBoundary wb(int offsetMs, int durMs, String text) =>
    CraftWordBoundary(text: text, audioOffsetMs: offsetMs, durationMs: durMs);

void main() {
  group('mergePunctuationTokens', () {
    test('attaches standalone period to previous word', () {
      final merged = mergePunctuationTokens([
        wb(0, 300, 'Hello'),
        wb(300, 50, '.'),
        wb(400, 300, 'World'),
      ]);
      expect(merged, hasLength(2));
      expect(merged[0].text, 'Hello.');
      expect(merged[0].durationMs, 350);
      expect(merged[1].text, 'World');
    });

    test('drops leading punctuation-only tokens', () {
      final merged = mergePunctuationTokens([
        wb(0, 50, '.'),
        wb(50, 300, 'Hello'),
      ]);
      expect(merged, hasLength(1));
      expect(merged.first.text, 'Hello');
    });

    test('skips empty-trimmed tokens', () {
      final merged = mergePunctuationTokens([
        wb(0, 300, 'Hello'),
        wb(300, 0, '   '),
        wb(350, 300, 'world'),
      ]);
      expect(merged, hasLength(2));
      expect(merged[0].text, 'Hello');
      expect(merged[1].text, 'world');
    });

    test('attaches standalone clause punctuation to previous word', () {
      final merged = mergePunctuationTokens([
        wb(0, 300, 'Hello'),
        wb(300, 40, ','),
        wb(400, 300, 'world'),
      ]);
      expect(merged, hasLength(2));
      expect(merged[0].text, 'Hello,');
      expect(merged[0].audioOffsetMs, 0);
      expect(merged[0].durationMs, 340);
      expect(merged[1].text, 'world');
    });

    test('attaches standalone CJK clause punctuation to previous word', () {
      final merged = mergePunctuationTokens([
        wb(0, 300, '早上好'),
        wb(300, 40, '，'),
        wb(400, 300, '朋友'),
      ]);
      expect(merged, hasLength(2));
      expect(merged[0].text, '早上好，');
      expect(merged[1].text, '朋友');
    });
  });

  group('segmentWordBoundaries — locked contracts', () {
    test('returns empty for empty input', () {
      expect(segmentWordBoundaries([]), isEmpty);
    });

    test('groups short text into one segment', () {
      final segments = segmentWordBoundaries([
        wb(0, 400, 'Hello'),
        wb(400, 500, 'world.'),
      ]);
      expect(segments, hasLength(1));
      expect(segments.first.text, 'Hello world.');
      expect(segments.first.startMs, 0);
      expect(segments.first.durationMs, 900);
    });

    test('splits on sentence-ending punctuation', () {
      final segments = segmentWordBoundaries([
        wb(0, 300, 'Hello'),
        wb(300, 400, 'world.'),
        wb(800, 300, 'How'),
        wb(1100, 300, 'are'),
        wb(1400, 400, 'you?'),
      ]);
      expect(segments, hasLength(2));
      expect(segments[0].text, 'Hello world.');
      expect(segments[1].text, 'How are you?');
      expect(segments[0].startMs, 0);
      expect(segments[1].startMs, 800);
    });

    test('does not start a line with standalone Azure punctuation tokens', () {
      final segments = segmentWordBoundaries([
        for (var i = 0; i < 6; i++) wb(i * 300, 300, 'word$i'),
        wb(1800, 50, '.'),
        wb(2000, 300, 'Next'),
      ]);
      expect(segments, isNotEmpty);
      for (final s in segments) {
        expect(isPunctuationOnlyToken(s.text), isFalse);
        expect(s.text.trim().startsWith('.'), isFalse);
      }
      expect(segments.first.text, contains('word5.'));
    });

    test('handles CJK full-width sentence punctuation tokens', () {
      final segments = segmentWordBoundaries([
        wb(0, 300, '你好'),
        wb(300, 50, '。'),
        wb(400, 300, '世界'),
        wb(700, 50, '！'),
      ]);
      expect(segments, hasLength(2));
      expect(segments[0].text, '你好。');
      expect(segments[1].text, '世界！');
    });
  });

  group('segmentWordBoundaries — timing accuracy (FR-008)', () {
    test('start equals first word onset; duration spans to last release', () {
      final segments = segmentWordBoundaries([
        wb(100, 400, 'Hello'),
        wb(600, 500, 'world.'),
      ]);
      expect(segments.first.startMs, 100);
      expect(segments.first.durationMs, 1000);
    });

    test('silence between lines is not included in a line duration', () {
      final segments = segmentWordBoundaries([
        wb(0, 300, 'A.'),
        wb(500, 300, 'B.'),
      ]);
      expect(segments, hasLength(2));
      expect(segments[0].startMs, 0);
      expect(segments[0].durationMs, 300);
      expect(segments[1].startMs, 500);
      expect(segments[1].durationMs, 300);
    });

    test(
      'merges standalone fragments shorter than minLineMs within a sentence',
      () {
        final segments = segmentWordBoundaries([
          wb(0, 1000, 'one'),
          wb(1100, 1000, 'two'),
          wb(2200, 1000, 'three'),
          wb(3300, 1000, 'four'),
          wb(4400, 1000, 'five'),
          wb(5500, 1000, 'six'),
          wb(6600, 100, 'seven.'),
        ]);
        for (final s in segments) {
          expect(s.durationMs, greaterThanOrEqualTo(1200));
        }
      },
    );
  });

  group('segmentWordBoundaries — shadow-friendly sizing (FR-003/FR-004)', () {
    test('splits a long sentence so no line exceeds hardMaxMs', () {
      final segments = segmentWordBoundaries([
        wb(0, 1000, 'one'),
        wb(1100, 1000, 'two'),
        wb(2200, 1000, 'three'),
        wb(3300, 1000, 'four'),
        wb(4400, 1000, 'five'),
        wb(5500, 1000, 'six'),
        wb(6600, 1000, 'seven.'),
      ]);
      expect(segments.length, greaterThanOrEqualTo(2));
      for (final s in segments) {
        expect(s.durationMs, lessThanOrEqualTo(7000));
      }
    });

    test(
      'prefers largest silence gap when no clause punctuation is present',
      () {
        final segments = segmentWordBoundaries([
          wb(0, 500, 'one'),
          wb(600, 500, 'two'),
          wb(1200, 500, 'three'),
          wb(4000, 500, 'four'),
          wb(4600, 500, 'five'),
          wb(5200, 500, 'six'),
          wb(5800, 500, 'seven.'),
        ]);
        expect(segments.length, greaterThanOrEqualTo(2));
        expect(segments.first.text, contains('three'));
        expect(segments.last.text, contains('four'));
      },
    );

    test('merges standalone fragments shorter than minLineMs', () {
      final segments = segmentWordBoundaries([wb(0, 100, 'hi.')]);
      expect(segments, hasLength(1));
      expect(segments.first.text, 'hi.');
    });

    test('a short single sentence stays as one line', () {
      final segments = segmentWordBoundaries([
        wb(0, 1500, 'Hello'),
        wb(1600, 1500, 'there.'),
      ]);
      expect(segments, hasLength(1));
    });

    test('zero-duration word does not produce a zero-duration line', () {
      final segments = segmentWordBoundaries([
        wb(0, 0, 'Hello'),
        wb(0, 300, 'world.'),
      ]);
      expect(segments, hasLength(1));
      expect(segments.first.durationMs, greaterThan(0));
    });
  });

  group('segmentWordBoundaries — clause punctuation (FR-005)', () {
    test('Latin clause marks are preferred break points', () {
      final segments = segmentWordBoundaries([
        wb(0, 1000, 'one'),
        wb(1100, 1000, 'two'),
        wb(2200, 1000, 'three,'),
        wb(3300, 1000, 'four'),
        wb(4400, 1000, 'five'),
        wb(5500, 1000, 'six.'),
      ]);
      expect(segments.length, greaterThanOrEqualTo(2));
      for (final s in segments) {
        expect(s.text.trim().startsWith(RegExp(r'[,;:]')), isFalse);
      }
      expect(segments.any((s) => s.text.contains(',')), isTrue);
    });

    test('standalone Azure clause tokens merge cleanly (no " ," spacing)', () {
      final segments = segmentWordBoundaries([
        wb(0, 1000, 'one'),
        wb(1100, 1000, 'two'),
        wb(2200, 1000, 'three'),
        wb(3200, 40, ','),
        wb(3300, 1000, 'four'),
        wb(4400, 1000, 'five'),
        wb(5500, 1000, 'six.'),
      ]);
      final joined = segments.map((s) => s.text).join(' ');
      expect(joined.contains(' ,'), isFalse);
      expect(joined.contains('three,'), isTrue);
    });

    test('CJK full-width clause punctuation (、，；：) guides breaks', () {
      final segments = segmentWordBoundaries([
        wb(0, 1000, '我'),
        wb(1100, 1000, '早上'),
        wb(2200, 1000, '起床，'),
        wb(3300, 1000, '喝了'),
        wb(4400, 1000, '咖啡，'),
        wb(5500, 1000, '然后'),
        wb(6600, 1000, '去上班。'),
      ], language: 'zh-CN');
      expect(segments.length, greaterThanOrEqualTo(2));
      for (final s in segments) {
        expect(isPunctuationOnlyToken(s.text), isFalse);
      }
      expect(segments.any((s) => s.text.endsWith('，')), isTrue);
    });

    test('CJK joins segment text spaceless', () {
      final segments = segmentWordBoundaries([
        wb(0, 300, '你好'),
        wb(300, 50, '。'),
      ], language: 'zh-CN');
      expect(segments, hasLength(1));
      expect(segments.first.text, '你好。');
      expect(segments.first.text.contains(' '), isFalse);
    });

    test('CJK clause mark adjacent to sentence end: sentence end wins', () {
      final segments = segmentWordBoundaries([
        wb(0, 300, '你好。'),
        wb(400, 300, '世界！'),
      ], language: 'zh-CN');
      expect(segments, hasLength(2));
      expect(segments[0].text, '你好。');
      expect(segments[1].text, '世界！');
    });
  });

  group('segmentWordBoundaries — crafted text invariant (FR-010)', () {
    test(
      'segment text equals joined crafted boundary text, no STT rewrite',
      () {
        final crafted = [
          wb(0, 400, 'Shadowing'),
          wb(500, 400, 'is'),
          wb(1000, 400, 'great.'),
        ];
        final segments = segmentWordBoundaries(crafted);
        final craftedJoined = crafted.map((w) => w.text).join(' ').trim();
        final segmentsJoined = segments.map((s) => s.text).join(' ').trim();
        expect(segmentsJoined, craftedJoined);
      },
    );
  });

  group('buildCraftPrimaryTimelineJson', () {
    test('returns null for empty boundaries', () {
      expect(buildCraftPrimaryTimelineJson([]), isNull);
    });

    test('returns null for punctuation-only boundaries', () {
      expect(
        buildCraftPrimaryTimelineJson([wb(0, 50, '.'), wb(50, 50, '?')]),
        isNull,
      );
    });

    test('returns JSON when solid', () {
      final json = buildCraftPrimaryTimelineJson([
        wb(0, 300, 'Hello'),
        wb(300, 50, '.'),
      ]);
      expect(json, isNotNull);
      final decoded = jsonDecode(json!) as List<dynamic>;
      expect(decoded, hasLength(1));
      expect(decoded.first['text'], 'Hello.');
    });

    test('threads language parameter through to segmentation', () {
      final json = buildCraftPrimaryTimelineJson([
        wb(0, 300, '你好'),
        wb(300, 50, '。'),
      ], language: 'zh-CN');
      expect(json, isNotNull);
      final decoded = jsonDecode(json!) as List<dynamic>;
      expect(decoded, hasLength(1));
      expect(decoded.first['text'], '你好。');
    });
  });

  group('segmentsToTimelineJson', () {
    test('produces valid JSON with text, start, duration', () {
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

    test('encodes multiple segments as a JSON array', () {
      final segments = [
        const TranscriptSegment(text: 'One.', startMs: 0, durationMs: 300),
        const TranscriptSegment(text: 'Two.', startMs: 400, durationMs: 300),
      ];
      final decoded = jsonDecode(segmentsToTimelineJson(segments)) as List;
      expect(decoded, hasLength(2));
      expect(decoded[0]['text'], 'One.');
      expect(decoded[1]['text'], 'Two.');
    });
  });
}
