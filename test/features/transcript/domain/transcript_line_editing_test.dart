import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/transcript/domain/transcript_line_editing.dart';

void main() {
  group('formatTranscriptTimingMs', () {
    test('drops trailing zeros', () {
      expect(formatTranscriptTimingMs(0), '0');
      expect(formatTranscriptTimingMs(1000), '1');
      expect(formatTranscriptTimingMs(1250), '1.25');
      expect(formatTranscriptTimingMs(12340), '12.34');
      expect(formatTranscriptTimingMs(12345), '12.345');
    });

    test('keeps the integer part on whole-minute and multi-hour cues', () {
      expect(formatTranscriptTimingMs(59999), '59.999');
      expect(formatTranscriptTimingMs(60000), '60');
      expect(formatTranscriptTimingMs(7254300), '7254.3');
      expect(formatTranscriptTimingMs(7254000), '7254');
    });
  });

  group('parseTranscriptTimingMs', () {
    test('accepts decimal seconds', () {
      expect(parseTranscriptTimingMs('1.25'), 1250);
      expect(parseTranscriptTimingMs(' 12 '), 12000);
      expect(parseTranscriptTimingMs('0'), 0);
    });

    test('rejects blank, non-numeric and negative input', () {
      expect(parseTranscriptTimingMs(''), isNull);
      expect(parseTranscriptTimingMs('abc'), isNull);
      expect(parseTranscriptTimingMs('-1'), isNull);
      expect(parseTranscriptTimingMs('1,25'), isNull);
    });
  });

  group('editedTranscriptLine', () {
    const word = TranscriptWord(text: 'Hello', startMs: 0, durationMs: 500);

    test('keeps word timings while the text is unchanged', () {
      const line = TranscriptLine(
        text: 'Hello',
        startMs: 1000,
        durationMs: 500,
        sourceKey: 'k',
        confidence: 0.9,
        timeline: [word],
      );

      final edited = editedTranscriptLine(
        line,
        text: 'Hello',
        startMs: 1500,
        durationMs: 400,
      );

      expect(edited.text, 'Hello');
      expect(edited.startMs, 1500);
      expect(edited.durationMs, 400);
      expect(edited.sourceKey, 'k');
      expect(edited.confidence, 0.9);
      expect(edited.timeline, [word]);
    });

    test('drops word timings once the text changed', () {
      const line = TranscriptLine(
        text: 'Hello',
        startMs: 1000,
        durationMs: 500,
        timeline: [word],
      );

      final edited = editedTranscriptLine(
        line,
        text: 'Hi there',
        startMs: 1000,
        durationMs: 500,
      );

      expect(edited.text, 'Hi there');
      expect(edited.timeline, isNull);
    });
  });
}
