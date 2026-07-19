import 'package:enjoy_player/features/asr/domain/asr_long_form_mapper.dart';
import 'package:enjoy_player/features/asr/domain/asr_long_form_models.dart';
import 'package:enjoy_player/features/asr/domain/asr_timeline_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps segments into AsrResult', () {
    final result = mapLongFormTranscriptToAsrResult(
      const AsrLongFormTranscript(
        text: 'Hello world',
        language: 'en',
        actualDurationSeconds: 3,
        segments: [
          {'start': 0.0, 'end': 1.5, 'text': 'Hello'},
          {'start': 1.5, 'end': 3.0, 'text': 'world'},
        ],
      ),
    );
    expect(result.text, 'Hello world');
    expect(result.language, 'en');
    expect(result.segments, isNotNull);
    expect(result.segments!.length, 2);
  });

  test('wraps root words into a segment for timeline builder', () {
    final result = mapLongFormTranscriptToAsrResult(
      AsrLongFormTranscript(
        text: 'Hello there friend',
        language: 'en',
        words: [
          {'word': 'Hello', 'start': 0.0, 'end': 0.4},
          {'word': 'there', 'start': 0.45, 'end': 0.8},
          {'word': 'friend', 'start': 0.9, 'end': 1.3},
        ],
      ),
    );
    final lines = buildAsrTranscriptLines(
      result: result,
      mediaDurationMs: 2000,
    );
    expect(lines, isNotEmpty);
    expect(lines.every((l) => l.durationMs > 0), isTrue);
    expect(lines.map((l) => l.text).join(' '), contains('Hello'));
  });

  test('empty text maps to empty AsrResult text', () {
    final result = mapLongFormTranscriptToAsrResult(
      const AsrLongFormTranscript(text: ''),
    );
    expect(result.text, isEmpty);
  });
}
