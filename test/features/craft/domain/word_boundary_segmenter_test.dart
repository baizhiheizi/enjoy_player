import 'dart:convert';

import 'package:enjoy_player/features/craft/domain/craft_synthesizer.dart';
import 'package:enjoy_player/features/craft/domain/word_boundary_segmenter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('mergePunctuationTokens', () {
    test('attaches standalone period to previous word', () {
      final merged = mergePunctuationTokens(const [
        CraftWordBoundary(text: 'Hello', audioOffsetMs: 0, durationMs: 300),
        CraftWordBoundary(text: '.', audioOffsetMs: 300, durationMs: 50),
        CraftWordBoundary(text: 'World', audioOffsetMs: 400, durationMs: 300),
      ]);
      expect(merged, hasLength(2));
      expect(merged[0].text, 'Hello.');
      expect(merged[0].durationMs, 350);
      expect(merged[1].text, 'World');
    });

    test('drops leading punctuation-only tokens', () {
      final merged = mergePunctuationTokens(const [
        CraftWordBoundary(text: '.', audioOffsetMs: 0, durationMs: 50),
        CraftWordBoundary(text: 'Hello', audioOffsetMs: 50, durationMs: 300),
      ]);
      expect(merged, hasLength(1));
      expect(merged.first.text, 'Hello');
    });
  });

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

    test('does not start a line with standalone Azure punctuation tokens', () {
      final boundaries = [
        for (var i = 0; i < 6; i++)
          CraftWordBoundary(
            text: 'word$i',
            audioOffsetMs: i * 300,
            durationMs: 300,
          ),
        const CraftWordBoundary(text: '.', audioOffsetMs: 1800, durationMs: 50),
        const CraftWordBoundary(
          text: 'Next',
          audioOffsetMs: 2000,
          durationMs: 300,
        ),
      ];
      final segments = segmentWordBoundaries(
        boundaries,
        preferredWordsPerSegment: 6,
      );
      expect(segments, isNotEmpty);
      for (final s in segments) {
        expect(isPunctuationOnlyToken(s.text), isFalse);
        expect(s.text.trim().startsWith('.'), isFalse);
      }
      expect(segments.first.text, contains('word5.'));
    });

    test('prefers sentence end over mid-sentence word-count chop', () {
      // 8 words, sentence ends after word 3 — should flush at sentence, not wait for 6.
      final boundaries = [
        const CraftWordBoundary(text: 'One', audioOffsetMs: 0, durationMs: 100),
        const CraftWordBoundary(
          text: 'two',
          audioOffsetMs: 100,
          durationMs: 100,
        ),
        const CraftWordBoundary(
          text: 'three.',
          audioOffsetMs: 200,
          durationMs: 100,
        ),
        const CraftWordBoundary(
          text: 'Four',
          audioOffsetMs: 400,
          durationMs: 100,
        ),
        const CraftWordBoundary(
          text: 'five',
          audioOffsetMs: 500,
          durationMs: 100,
        ),
        const CraftWordBoundary(
          text: 'six',
          audioOffsetMs: 600,
          durationMs: 100,
        ),
        const CraftWordBoundary(
          text: 'seven',
          audioOffsetMs: 700,
          durationMs: 100,
        ),
        const CraftWordBoundary(
          text: 'eight.',
          audioOffsetMs: 800,
          durationMs: 100,
        ),
      ];
      final segments = segmentWordBoundaries(
        boundaries,
        preferredWordsPerSegment: 6,
      );
      expect(segments.first.text, 'One two three.');
      expect(segments.length, greaterThanOrEqualTo(2));
    });

    test('handles CJK full-width punctuation tokens', () {
      final segments = segmentWordBoundaries(const [
        CraftWordBoundary(text: '你好', audioOffsetMs: 0, durationMs: 300),
        CraftWordBoundary(text: '。', audioOffsetMs: 300, durationMs: 50),
        CraftWordBoundary(text: '世界', audioOffsetMs: 400, durationMs: 300),
        CraftWordBoundary(text: '！', audioOffsetMs: 700, durationMs: 50),
      ]);
      expect(segments, hasLength(2));
      expect(segments[0].text, '你好。');
      expect(segments[1].text, '世界！');
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

  group('buildCraftPrimaryTimelineJson', () {
    test('returns null for empty boundaries', () {
      expect(buildCraftPrimaryTimelineJson([]), isNull);
    });

    test('returns null for punctuation-only boundaries', () {
      expect(
        buildCraftPrimaryTimelineJson(const [
          CraftWordBoundary(text: '.', audioOffsetMs: 0, durationMs: 50),
          CraftWordBoundary(text: '?', audioOffsetMs: 50, durationMs: 50),
        ]),
        isNull,
      );
    });

    test('returns JSON when solid', () {
      final json = buildCraftPrimaryTimelineJson(const [
        CraftWordBoundary(text: 'Hello', audioOffsetMs: 0, durationMs: 300),
        CraftWordBoundary(text: '.', audioOffsetMs: 300, durationMs: 50),
      ]);
      expect(json, isNotNull);
      final decoded = jsonDecode(json!) as List<dynamic>;
      expect(decoded, hasLength(1));
      expect(decoded.first['text'], 'Hello.');
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
