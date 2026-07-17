import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/lookup/application/vocabulary_context_builder.dart';
import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';

TranscriptLine _line(String text, {int startMs = 0, int durationMs = 1000}) =>
    TranscriptLine(text: text, startMs: startMs, durationMs: durationMs);

void main() {
  group('isMoreThanOneSentence', () {
    test('false for a single sentence', () {
      expect(isMoreThanOneSentence('Hello world.', 'en'), isFalse);
    });

    test('true for two sentences', () {
      expect(isMoreThanOneSentence('Hello world. How are you?', 'en'), isTrue);
    });

    test('true for a sentence plus trailing fragment', () {
      expect(isMoreThanOneSentence('Hello world. How', 'en'), isTrue);
    });

    test('false when there is no terminator', () {
      expect(isMoreThanOneSentence('Hello world', 'en'), isFalse);
    });
  });

  group('buildVocabularyContext', () {
    test('echo with multiple sentences uses the full echo region', () {
      final lines = <TranscriptLine>[
        _line('Hello world.', startMs: 0),
        _line('How are you?', startMs: 1000),
        _line('Goodbye.', startMs: 2000),
      ];
      const echo = EchoState(
        active: true,
        startLineIndex: 0,
        endLineIndex: 1,
        startTimeSeconds: 0,
        endTimeSeconds: 2,
      );
      final ctx = buildVocabularyContext(
        lines: lines,
        echo: echo,
        currentTimeSeconds: 0.5,
        primaryLanguage: 'en',
      );
      expect(ctx, 'Hello world. How are you?');
    });

    test(
      'echo with one incomplete sentence expands outside echo to complete it',
      () {
        final lines = <TranscriptLine>[
          _line('She said hello', startMs: 0),
          _line('to the whole room.', startMs: 1000),
          _line('Then she left.', startMs: 2000),
        ];
        // Echo covers only the first fragment line — should grow to the sentence.
        const echo = EchoState(
          active: true,
          startLineIndex: 0,
          endLineIndex: 0,
          startTimeSeconds: 0,
          endTimeSeconds: 1,
        );
        final ctx = buildVocabularyContext(
          lines: lines,
          echo: echo,
          currentTimeSeconds: 0.2,
          primaryLanguage: 'en',
        );
        expect(ctx, 'She said hello to the whole room.');
      },
    );

    test(
      'multi-line echo that is still one sentence expands to that sentence',
      () {
        final lines = <TranscriptLine>[
          _line('Prev ends here.', startMs: 0),
          _line('She said hello', startMs: 1000),
          _line('to the whole room.', startMs: 2000),
          _line('After that.', startMs: 3000),
        ];
        const echo = EchoState(
          active: true,
          startLineIndex: 1,
          endLineIndex: 2,
          startTimeSeconds: 1,
          endTimeSeconds: 3,
        );
        final ctx = buildVocabularyContext(
          lines: lines,
          echo: echo,
          currentTimeSeconds: 1.5,
          primaryLanguage: 'en',
        );
        expect(ctx, 'She said hello to the whole room.');
      },
    );

    test(
      'without punctuation uses bounded ±radius window around active line',
      () {
        final lines = <TranscriptLine>[
          for (var i = 0; i < 5; i++) _line('line$i', startMs: i * 1000),
        ];
        const echo = EchoState(
          active: true,
          startLineIndex: 0,
          endLineIndex: 1,
          startTimeSeconds: 0,
          endTimeSeconds: 2,
        );
        final span = resolveVocabularyContextSpan(
          lines: lines,
          echo: echo,
          currentTimeSeconds: 0,
          primaryLanguage: 'en',
        );
        expect(span, isNotNull);
        // Seed line 0 → expand forward by radius only (no backward room).
        expect(span!.startLineIndex, 0);
        expect(span.endLineIndex, kVocabularyContextLineRadius);
        expect(span.text, 'line0 line1 line2 line3');
      },
    );

    test('large unpunctuated echo does not become the full transcript', () {
      final lines = <TranscriptLine>[
        for (var i = 0; i < 20; i++) _line('cue$i', startMs: i * 1000),
      ];
      const echo = EchoState(
        active: true,
        startLineIndex: 0,
        endLineIndex: 19,
        startTimeSeconds: 0,
        endTimeSeconds: 20,
      );
      final span = resolveVocabularyContextSpan(
        lines: lines,
        echo: echo,
        currentTimeSeconds: 10.5, // active ~ line 10
        primaryLanguage: 'en',
      );
      expect(span, isNotNull);
      final lineCount = span!.endLineIndex - span.startLineIndex + 1;
      expect(
        lineCount,
        lessThanOrEqualTo(1 + 2 * kVocabularyContextLineRadius),
      );
      expect(span.startLineIndex, 10 - kVocabularyContextLineRadius);
      expect(span.endLineIndex, 10 + kVocabularyContextLineRadius);
      expect(span.text.contains('cue0'), isFalse);
      expect(span.text.contains('cue19'), isFalse);
    });

    test('single active line expands to sentence when possible', () {
      final lines = <TranscriptLine>[
        _line('Prev line.', startMs: 0, durationMs: 900),
        _line('Hello world.', startMs: 900, durationMs: 2000),
        _line('After line.', startMs: 2900, durationMs: 1000),
      ];
      const echo = EchoState.inactive;
      final ctx = buildVocabularyContext(
        lines: lines,
        echo: echo,
        currentTimeSeconds: 1.0,
        primaryLanguage: 'en',
      );
      expect(ctx, 'Hello world.');
    });

    test('inactive echo expands across lines to complete a sentence', () {
      final lines = <TranscriptLine>[
        _line('She said hello', startMs: 0, durationMs: 1000),
        _line('to the whole room.', startMs: 1000, durationMs: 1000),
        _line('Then she left.', startMs: 2000, durationMs: 1000),
      ];
      const echo = EchoState.inactive;
      final ctx = buildVocabularyContext(
        lines: lines,
        echo: echo,
        currentTimeSeconds: 0.5,
        primaryLanguage: 'en',
      );
      expect(ctx, 'She said hello to the whole room.');
    });
  });
}
