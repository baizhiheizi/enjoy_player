import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/dictation/domain/dictation_band_words.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildDictationBandWords', () {
    test(
      'computes word block pixel width as max(3, letters) * 9.5 rounded',
      () {
        final words = buildDictationBandWords(
          lines: const [
            TranscriptLine(
              startMs: 0,
              durationMs: 1000,
              text: 'I am learning Flutter',
            ),
          ],
          fallbackReferenceText: '',
          regionStartMs: 0,
          regionDurationMs: 1000,
        );

        expect(words[0].text, 'I');
        expect(words[0].blockWidth, 29.0);

        expect(words[1].text, 'am');
        expect(words[1].blockWidth, 29.0);

        expect(words[2].text, 'learning');
        expect(words[2].blockWidth, 76.0);

        expect(words[3].text, 'Flutter');
        expect(words[3].blockWidth, 67.0);
      },
    );

    test('uses word timeline when available', () {
      final words = buildDictationBandWords(
        lines: const [
          TranscriptLine(
            startMs: 1000,
            durationMs: 2000,
            text: 'hello world',
            timeline: [
              TranscriptWord(text: 'hello', startMs: 100, durationMs: 400),
              TranscriptWord(text: 'world', startMs: 600, durationMs: 500),
            ],
          ),
        ],
        fallbackReferenceText: '',
        regionStartMs: 1000,
        regionDurationMs: 2000,
      );

      expect(words.length, 2);
      expect(words[0].startMs, 1100);
      expect(words[0].endMs, 1500);
      expect(words[1].startMs, 1600);
      expect(words[1].endMs, 2100);

      expect(
        findActiveDictationWordIndex(words: words, currentPlaybackMs: 1200),
        0,
      );
      expect(
        findActiveDictationWordIndex(words: words, currentPlaybackMs: 1550),
        isNull,
      );
      expect(
        findActiveDictationWordIndex(words: words, currentPlaybackMs: 1700),
        1,
      );
    });

    test('skips pure punctuation tokens in timeline and text', () {
      final words = buildDictationBandWords(
        lines: const [
          TranscriptLine(
            startMs: 0,
            durationMs: 1000,
            text: 'Hello — world',
            timeline: [
              TranscriptWord(text: 'Hello', startMs: 0, durationMs: 400),
              TranscriptWord(text: '—', startMs: 400, durationMs: 100),
              TranscriptWord(text: 'world', startMs: 500, durationMs: 500),
            ],
          ),
        ],
        fallbackReferenceText: '',
        regionStartMs: 0,
        regionDurationMs: 1000,
      );

      expect(words.length, 2);
      expect(words[0].text, 'Hello');
      expect(words[1].text, 'world');
    });
  });
}
