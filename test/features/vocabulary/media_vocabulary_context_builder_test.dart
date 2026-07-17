import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';
import 'package:enjoy_player/features/vocabulary/application/media_vocabulary_context_builder.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_models.dart';

void main() {
  group('buildMediaVocabularyContext', () {
    test('echo with two or more lines joins text and spans locator ms', () {
      final lines = <TranscriptLine>[
        const TranscriptLine(text: 'A', startMs: 1000, durationMs: 500),
        const TranscriptLine(text: 'B', startMs: 1500, durationMs: 500),
        const TranscriptLine(text: 'C', startMs: 2000, durationMs: 500),
      ];
      const echo = EchoState(
        active: true,
        startLineIndex: 0,
        endLineIndex: 1,
        startTimeSeconds: 1,
        endTimeSeconds: 2,
      );
      final ctx = buildMediaVocabularyContext(
        lines: lines,
        echo: echo,
        currentTimeSeconds: 1.2,
        primaryLanguage: 'en',
        sourceType: VocabularySourceType.video,
        sourceId: 'media-1',
      );
      expect(ctx, isNotNull);
      expect(ctx!.text, 'A B');
      expect(ctx.sourceType, VocabularySourceType.video);
      expect(ctx.sourceId, 'media-1');
      expect(ctx.locator.start, 1000);
      expect(ctx.locator.duration, 1000); // 1000 → 2000
    });

    test('inactive echo expands around active line', () {
      final lines = <TranscriptLine>[
        const TranscriptLine(
          text: 'Hello world. ',
          startMs: 0,
          durationMs: 2000,
        ),
        const TranscriptLine(text: 'After.', startMs: 2000, durationMs: 1000),
      ];
      const echo = EchoState.inactive;
      final ctx = buildMediaVocabularyContext(
        lines: lines,
        echo: echo,
        currentTimeSeconds: 0.5,
        primaryLanguage: 'en',
        sourceType: VocabularySourceType.audio,
        sourceId: 'audio-1',
      );
      expect(ctx, isNotNull);
      expect(ctx!.text.isNotEmpty, isTrue);
      expect(ctx.locator.start, greaterThanOrEqualTo(0));
      expect(ctx.locator.duration, greaterThanOrEqualTo(0));
    });
  });
}
