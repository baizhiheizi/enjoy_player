import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/lookup/application/vocabulary_context_builder.dart';
import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';

TranscriptLine _line(String text) =>
    TranscriptLine(text: text, startMs: 0, durationMs: 1000);

void main() {
  group('buildVocabularyContext', () {
    test('echo with two or more lines joins primary text', () {
      final lines = <TranscriptLine>[_line('A'), _line('B'), _line('C')];
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
        currentTimeSeconds: 0,
        primaryLanguage: 'en',
      );
      expect(ctx, 'A B');
    });

    test('single active line expands to sentence when possible', () {
      final lines = <TranscriptLine>[
        const TranscriptLine(text: 'Prev line. ', startMs: 0, durationMs: 900),
        const TranscriptLine(
          text: 'Hello world. ',
          startMs: 900,
          durationMs: 2000,
        ),
        const TranscriptLine(
          text: 'After line.',
          startMs: 2900,
          durationMs: 1000,
        ),
      ];
      const echo = EchoState.inactive;
      final ctx = buildVocabularyContext(
        lines: lines,
        echo: echo,
        currentTimeSeconds: 1.0,
        primaryLanguage: 'en',
      );
      expect(ctx, isNotNull);
      expect(ctx!.isNotEmpty, isTrue);
      expect(ctx.contains('Hello') || ctx.contains('Prev'), isTrue);
    });
  });
}
