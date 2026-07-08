import 'package:enjoy_player/core/application/app_language_catalog.dart';
import 'package:enjoy_player/features/lookup/application/lookup_target_languages.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const learn = kDefaultLearningLanguageTag;

  group('resolveLookupSource', () {
    test('falls back to learning tag for und / empty / unknown', () {
      expect(resolveLookupSource(null, learningTag: learn), learn);
      expect(resolveLookupSource('', learningTag: learn), learn);
      expect(resolveLookupSource('   ', learningTag: learn), learn);
      expect(resolveLookupSource('und', learningTag: learn), learn);
    });

    test('canonicalizes en and zh short tags', () {
      expect(resolveLookupSource('en', learningTag: learn), 'en-US');
      expect(resolveLookupSource('EN-us', learningTag: learn), 'en-US');
      expect(resolveLookupSource('en-US', learningTag: learn), 'en-US');
      expect(resolveLookupSource('zh', learningTag: learn), 'zh-CN');
      expect(resolveLookupSource('zh-CN', learningTag: learn), 'zh-CN');
      expect(resolveLookupSource('zh-Hans', learningTag: learn), 'zh-CN');
    });

    test('recognizes lookup-catalog tracks (ko / ja / de / it / ru)', () {
      expect(resolveLookupSource('ko-KR', learningTag: learn), 'ko-KR');
      expect(resolveLookupSource('ja-JP', learningTag: learn), 'ja-JP');
      expect(resolveLookupSource('de-DE', learningTag: learn), 'de-DE');
      expect(resolveLookupSource('ru-RU', learningTag: learn), 'ru-RU');
    });

    test('canonicalizes primary-subtag-only track (ja → ja-JP)', () {
      expect(resolveLookupSource('ja', learningTag: learn), 'ja-JP');
      expect(resolveLookupSource('de', learningTag: learn), 'de-DE');
    });
  });

  group('resolveLookupSourceOverride', () {
    test('returns null for null / empty / whitespace', () {
      expect(resolveLookupSourceOverride(null), isNull);
      expect(resolveLookupSourceOverride(''), isNull);
      expect(resolveLookupSourceOverride('   '), isNull);
    });

    test('returns null for denylisted primaries (und / mul / mis / zxx)', () {
      expect(resolveLookupSourceOverride('und'), isNull);
      expect(resolveLookupSourceOverride('mul'), isNull);
      expect(resolveLookupSourceOverride('mis'), isNull);
      expect(resolveLookupSourceOverride('zxx'), isNull);
    });

    test('canonicalizes valid tags', () {
      expect(resolveLookupSourceOverride('ko-KR'), 'ko-KR');
      expect(resolveLookupSourceOverride('ja'), 'ja-JP');
      expect(resolveLookupSourceOverride('EN-us'), 'en-US');
      expect(resolveLookupSourceOverride('kor'), 'ko-KR');
    });
  });

  group('resolveLookupTarget', () {
    test('canonicalizes supported native tags when distinct from learning', () {
      expect(resolveLookupTarget('zh-CN', learningTag: learn), 'zh-CN');
      expect(resolveLookupTarget('zh', learningTag: learn), 'zh-CN');
    });

    test('prefers lookup-catalog entry over narrow coercion (en-GB → en-GB)', () {
      // en-GB is now in the lookup catalog; the new spec returns en-GB directly
      // (the user can change to zh-CN in the picker if they want).
      expect(resolveLookupTarget('en-GB', learningTag: learn), 'en-GB');
    });

    test('when native equals learning, coerces to other supported', () {
      expect(resolveLookupTarget('en-US', learningTag: learn), 'zh-CN');
      expect(resolveLookupTarget(null, learningTag: learn), 'zh-CN');
    });

    test('allows en-US target when learning is zh-CN', () {
      expect(resolveLookupTarget('en-US', learningTag: 'zh-CN'), 'en-US');
    });

    test('normalizes learning tag in fallback path', () {
      expect(resolveLookupSource('und', learningTag: 'zh-cn'), 'zh-CN');
    });

    test('prefers direct lookup catalog entry over primary-subtag fallback', () {
      expect(resolveLookupTarget('ja-JP', learningTag: learn), 'ja-JP');
      expect(resolveLookupTarget('de-DE', learningTag: learn), 'de-DE');
      expect(resolveLookupTarget('it-IT', learningTag: learn), 'it-IT');
      expect(resolveLookupTarget('ru-RU', learningTag: learn), 'ru-RU');
    });

    test('falls back to primary-subtag match when stored native is not in lookup list', () {
      // de-AT → primary 'de' → first de-* in lookup list is de-DE
      expect(resolveLookupTarget('de-AT', learningTag: learn), 'de-DE');
      // fr-CH → primary 'fr' → first fr-* is fr-FR
      expect(resolveLookupTarget('fr-CH', learningTag: learn), 'fr-FR');
      // en-AU (not in lookup list, primary 'en', learning 'en-US') →
      // first en-* != en-US = en-GB
      expect(resolveLookupTarget('en-AU', learningTag: learn), 'en-GB');
    });

    test('avoids picking source when a source tag is provided', () {
      expect(
        resolveLookupTarget('de-AT', learningTag: learn, sourceLanguage: 'de-DE'),
        isNot('de-DE'),
      );
    });

    test('preserves en-US / zh-CN parity (US3)', () {
      expect(resolveLookupTarget('en-US', learningTag: 'zh-CN'), 'en-US');
      expect(resolveLookupTarget('zh-CN', learningTag: 'en-US'), 'zh-CN');
      expect(resolveLookupTarget(null, learningTag: 'en-US'), 'zh-CN');
      expect(resolveLookupSource('und', learningTag: 'en-US'), 'en-US');
      expect(resolveLookupSource('ko-KR', learningTag: 'en-US'), 'ko-KR');
    });
  });
}
