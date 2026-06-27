/// Tests for [languageHintFromSubtitleFileName] — the BCP-47-ish language
/// hint extracted from a subtitle/sidecar filename (e.g. `movie.en.srt`).
///
/// The function is the single source of truth for guessing a track's
/// language from its filename. It is wired into transcript import
/// ([`TranscriptRepository`]), the transcript panel subtitle picker, and
/// the standalone subtitle track picker sheet — three independent call
/// sites that all need the same heuristic.
///
/// The regex is heuristic, not strict BCP-47; tests pin the *current*
/// behavior so callers can rely on a stable contract even if the regex
/// is later tightened.
library;

import 'package:enjoy_player/data/subtitle/subtitle_filename.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('languageHintFromSubtitleFileName', () {
    group('two-letter language codes', () {
      test('extracts code from `<name>.<lang>.srt`', () {
        expect(languageHintFromSubtitleFileName('movie.en.srt'), 'en');
        expect(languageHintFromSubtitleFileName('episode.fr.vtt'), 'fr');
        expect(languageHintFromSubtitleFileName('lesson.zh.srt'), 'zh');
      });

      test('extracts code from various subtitle extensions', () {
        // All common subtitle extensions should be recognized.
        expect(languageHintFromSubtitleFileName('movie.en.srt'), 'en');
        expect(languageHintFromSubtitleFileName('movie.en.vtt'), 'en');
        expect(languageHintFromSubtitleFileName('movie.en.sub'), 'en');
        expect(languageHintFromSubtitleFileName('movie.en.ass'), 'en');
      });

      test('extracts code separated by underscore', () {
        expect(languageHintFromSubtitleFileName('movie_en.srt'), 'en');
        expect(languageHintFromSubtitleFileName('movie_fr.vtt'), 'fr');
      });

      test('extracts code separated by hyphen', () {
        expect(languageHintFromSubtitleFileName('movie-en.srt'), 'en');
        expect(languageHintFromSubtitleFileName('lesson-fr.vtt'), 'fr');
      });

      test('is case-insensitive on the language tag', () {
        // Filename is lowercased internally, so mixed-case input still
        // resolves to its lowercase tag.
        expect(languageHintFromSubtitleFileName('Movie.EN.srt'), 'en');
        expect(languageHintFromSubtitleFileName('Movie.Fr.vtt'), 'fr');
      });
    });

    group('BCP-47 region tags', () {
      test('extracts `<lang>-<region>` separated by dots', () {
        expect(languageHintFromSubtitleFileName('movie.en-us.srt'), 'en-us');
        expect(languageHintFromSubtitleFileName('lesson.zh-cn.vtt'), 'zh-cn');
      });

      test('extracts `<lang>-<region>` separated by hyphens', () {
        // Basename: movie-en-us. Boundaries are `.`, `_`, `-`, or start/end.
        expect(languageHintFromSubtitleFileName('movie-en-us.srt'), 'en-us');
      });

      test('extracts region with 3-letter ISO 3166 code', () {
        // Region tag is 2-4 letters per BCP-47 subtag rules.
        expect(languageHintFromSubtitleFileName('lesson.en-gbr.srt'), 'en-gbr');
        expect(
          languageHintFromSubtitleFileName('lesson.zh-hans.vtt'),
          'zh-hans',
        );
      });

      test('uppercase region tag is lowercased', () {
        expect(languageHintFromSubtitleFileName('movie.EN-US.srt'), 'en-us');
      });
    });

    group('undetermined (no language hint)', () {
      test('returns "und" when no 2-letter tag is present', () {
        expect(languageHintFromSubtitleFileName('movie.srt'), 'und');
        expect(languageHintFromSubtitleFileName('random.vtt'), 'und');
        expect(languageHintFromSubtitleFileName('a.b.c.srt'), 'und');
      });

      test('returns "und" for single-letter segments', () {
        // Single letters cannot satisfy `[a-z]{2}`.
        expect(languageHintFromSubtitleFileName('movie.e.srt'), 'und');
      });

      test('returns "und" when code is sandwiched between non-boundaries', () {
        // `en` without a boundary on either side is not a tag.
        expect(languageHintFromSubtitleFileName('enjoyment.srt'), 'und');
      });

      test('returns "und" for empty filename', () {
        expect(languageHintFromSubtitleFileName(''), 'und');
      });
    });

    group('ambiguous / heuristic cases', () {
      test('first 2-letter tag wins when several are present', () {
        // `.en.us.` has `en` first, so it is returned (not `us`).
        expect(languageHintFromSubtitleFileName('foo.en.us.srt'), 'en');
      });

      test('treats any non-letter separator as a word boundary', () {
        expect(languageHintFromSubtitleFileName('lesson.en-fr.vtt'), 'en-fr');
      });

      test('matches a 2-letter tag at the start of the basename', () {
        expect(languageHintFromSubtitleFileName('en.movietitle.srt'), 'en');
      });

      test('matches a 2-letter tag at the end of the basename', () {
        expect(languageHintFromSubtitleFileName('movietitle.en.srt'), 'en');
      });
    });

    group('case behavior of the rest of the filename', () {
      test('non-language characters are lowercased before regex matching', () {
        // The regex is case-insensitive, but the basename itself is
        // lowercased so non-ASCII / mixed-case words still split correctly.
        expect(languageHintFromSubtitleFileName('MovieTitle.EN.srt'), 'en');
      });
    });
  });
}
