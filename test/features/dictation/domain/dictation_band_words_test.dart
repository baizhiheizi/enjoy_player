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
          currentPlaybackMs: 0,
        );

        // 'I' -> letters.length 1 -> max(3, 1) = 3 -> round(3 * 9.5) = 29
        expect(words[0].text, 'I');
        expect(words[0].blockWidth, 29.0);

        // 'am' -> letters.length 2 -> max(3, 2) = 3 -> round(3 * 9.5) = 29
        expect(words[1].text, 'am');
        expect(words[1].blockWidth, 29.0);

        // 'learning' -> 8 -> round(8 * 9.5) = 76
        expect(words[2].text, 'learning');
        expect(words[2].blockWidth, 76.0);

        // 'Flutter' -> 7 -> round(7 * 9.5) = 67
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
        currentPlaybackMs: 1200,
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
  });
}
