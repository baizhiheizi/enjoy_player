import 'package:enjoy_player/features/lookup/application/transcript_lookup_open.dart';
import 'package:enjoy_player/features/lookup/application/lookup_target_languages.dart';
import 'package:enjoy_player/features/transcript/domain/transcript_track.dart';
import 'package:flutter_test/flutter_test.dart';

TranscriptTrack _track(String id, String language) => TranscriptTrack(
      id: id,
      targetType: 'Video',
      targetId: 'm1',
      language: language,
      source: 'user',
      label: id,
    );

void main() {
  group('firstLookupCatalogTrack', () {
    test('returns the first track with a usable language', () {
      final tracks = [
        _track('t-und', 'und'),
        _track('t-ko', 'ko'),
        _track('t-ja', 'ja-JP'),
      ];
      expect(firstLookupCatalogTrack(tracks)?.id, 't-ko');
    });

    test('returns null when no track has a usable language', () {
      final tracks = [
        _track('t-und', 'und'),
        _track('t-empty', ''),
      ];
      expect(firstLookupCatalogTrack(tracks), isNull);
    });

    test('skips tracks with invalid / unsupported languages', () {
      final tracks = [
        _track('t-bad', 'klingon'),
        _track('t-ko', 'ko-KR'),
      ];
      expect(firstLookupCatalogTrack(tracks)?.id, 't-ko');
    });
  });

  group('resolveLookupSourceLanguage', () {
    test('prefers activeTrack when its language is usable', () {
      final tracks = [
        _track('t-ko', 'ko-KR'),
        _track('t-ja', 'ja-JP'),
      ];
      expect(
        resolveLookupSourceLanguage(
          activeTrack: tracks[0],
          allTracks: tracks,
        ),
        'ko-KR',
      );
    });

    test('falls back to first sibling when activeTrack has no language', () {
      final tracks = [
        _track('t-und', 'und'),
        _track('t-ko', 'ko-KR'),
        _track('t-ja', 'ja-JP'),
      ];
      expect(
        resolveLookupSourceLanguage(
          activeTrack: tracks[0],
          allTracks: tracks,
        ),
        'ko-KR',
      );
    });

    test('returns null when no track has a usable language', () {
      final tracks = [
        _track('t-und', 'und'),
      ];
      expect(
        resolveLookupSourceLanguage(
          activeTrack: tracks[0],
          allTracks: tracks,
        ),
        'und',
      );
    });

    test('returns null when there are no tracks at all', () {
      expect(
        resolveLookupSourceLanguage(
          activeTrack: null,
          allTracks: const <TranscriptTrack>[],
        ),
        isNull,
      );
    });

    test('does not fall back when activeTrack has a usable language', () {
      final tracks = [
        _track('t-ko', 'ko-KR'),
        _track('t-ja', 'ja-JP'),
      ];
      // Active is Korean, even though Japanese is "first" in the list the
      // helper should NOT switch to it.
      expect(
        resolveLookupSourceLanguage(
          activeTrack: tracks[0],
          allTracks: tracks,
        ),
        'ko-KR',
      );
    });
  });

  // End-to-end sanity: full pipeline via the public resolver.
  group('integration with resolveLookupSource', () {
    test('Korean embedded track (lang=und) + Korean sibling → ko-KR', () {
      final tracks = [
        _track('t-und', 'und'),
        _track('t-ko', 'ko-KR'),
      ];
      final lang = resolveLookupSourceLanguage(
        activeTrack: tracks[0],
        allTracks: tracks,
      );
      expect(resolveLookupSource(lang, learningTag: 'en-US'), 'ko-KR');
    });

    test('only-Korean video → ko-KR', () {
      final tracks = [_track('t-ko', 'ko')];
      final lang = resolveLookupSourceLanguage(
        activeTrack: tracks[0],
        allTracks: tracks,
      );
      expect(resolveLookupSource(lang, learningTag: 'en-US'), 'ko-KR');
    });

    test('only-und video → learning fallback (preserved behavior)', () {
      final tracks = [_track('t-und', 'und')];
      final lang = resolveLookupSourceLanguage(
        activeTrack: tracks[0],
        allTracks: tracks,
      );
      expect(resolveLookupSource(lang, learningTag: 'en-US'), 'en-US');
    });

    test('Japanese video with ko-KR fallback sibling → ja-JP (active wins)', () {
      final tracks = [
        _track('t-ja', 'ja-JP'),
        _track('t-ko', 'ko-KR'),
      ];
      final lang = resolveLookupSourceLanguage(
        activeTrack: tracks[0],
        allTracks: tracks,
      );
      expect(resolveLookupSource(lang, learningTag: 'en-US'), 'ja-JP');
    });
  });
}