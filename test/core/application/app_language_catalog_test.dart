import 'package:enjoy_player/core/application/app_language_catalog.dart';
import 'package:enjoy_player/features/ai/data/azure_language_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isValidLanguageTag', () {
    test('rejects null, empty, and denylisted primaries', () {
      expect(isValidLanguageTag(null), false);
      expect(isValidLanguageTag(''), false);
      expect(isValidLanguageTag('   '), false);
      expect(isValidLanguageTag('und'), false);
      expect(isValidLanguageTag('UND'), false);
      expect(isValidLanguageTag('und-US'), false);
      expect(isValidLanguageTag('mul'), false);
      expect(isValidLanguageTag('mis'), false);
      expect(isValidLanguageTag('zxx'), false);
    });

    test('accepts en/zh and unknown real primaries', () {
      expect(isValidLanguageTag('en'), true);
      expect(isValidLanguageTag('zh-CN'), true);
      expect(isValidLanguageTag('ja'), true);
    });
  });

  group('normalizeLanguageAlias', () {
    test('maps kor to ko primary', () {
      expect(normalizeLanguageAlias('kor'), 'ko');
      expect(normalizeLanguageAlias('KOR'), 'ko');
    });
  });

  group('canonicalFocusLanguageTag', () {
    test('maps broad tags to preferred focus tags', () {
      expect(canonicalFocusLanguageTag('ja'), 'ja-JP');
      expect(canonicalFocusLanguageTag('ko'), 'ko-KR');
      expect(canonicalFocusLanguageTag('kor'), 'ko-KR');
      expect(canonicalFocusLanguageTag('es'), 'es-ES');
      expect(canonicalFocusLanguageTag('fr'), 'fr-FR');
    });

    test('preserves regional English and Spanish tags', () {
      expect(canonicalFocusLanguageTag('en-GB'), 'en-GB');
      expect(canonicalFocusLanguageTag('es-MX'), 'es-MX');
    });

    test('falls back to default for unknown', () {
      expect(canonicalFocusLanguageTag(null), kDefaultLearningLanguageTag);
      expect(canonicalFocusLanguageTag('xx'), kDefaultLearningLanguageTag);
    });
  });

  group('canonicalMediaLanguageTag', () {
    test('allows unknown media language', () {
      expect(canonicalMediaLanguageTag('und'), kUnknownMediaLanguageTag);
      expect(canonicalMediaLanguageTag(null), kUnknownMediaLanguageTag);
    });

    test('normalizes ja/ko aliases', () {
      expect(canonicalMediaLanguageTag('ja'), 'ja-JP');
      expect(canonicalMediaLanguageTag('kor'), 'ko-KR');
    });
  });

  group('matchesLanguageBroad', () {
    test('matches primary subtags across tag shapes', () {
      expect(matchesLanguageBroad('en', 'en-US'), true);
      expect(matchesLanguageBroad('ja-JP', 'ja'), true);
      expect(matchesLanguageBroad('es-ES', 'es-MX'), true);
      expect(matchesLanguageBroad('fr', 'ja'), false);
    });
  });

  group('resolveAzureAssessmentLocale', () {
    test('returns exact supported locales', () {
      expect(resolveAzureAssessmentLocale('en-US'), 'en-US');
      expect(resolveAzureAssessmentLocale('en-GB'), 'en-GB');
      expect(resolveAzureAssessmentLocale('ja-JP'), 'ja-JP');
      expect(resolveAzureAssessmentLocale('ko-KR'), 'ko-KR');
    });

    test('defaults broad tags to documented preferred locale', () {
      expect(resolveAzureAssessmentLocale('ja'), 'ja-JP');
      expect(resolveAzureAssessmentLocale('ko'), 'ko-KR');
    });

    test('returns null for unknown or invalid', () {
      expect(resolveAzureAssessmentLocale('und'), isNull);
      expect(resolveAzureAssessmentLocale(null), isNull);
      expect(resolveAzureAssessmentLocale('xx'), isNull);
    });
  });

  group('resolveAzureAssessmentLocaleForPractice', () {
    test('falls back for und / empty via learning language', () {
      expect(
        resolveAzureAssessmentLocaleForPractice(
          'und',
          learningLanguage: 'ja-JP',
        ),
        'ja-JP',
      );
      expect(
        resolveAzureAssessmentLocaleForPractice('', learningLanguage: 'en-GB'),
        'en-GB',
      );
      expect(
        resolveAzureAssessmentLocaleForPractice(null, learningLanguage: null),
        'en-US',
      );
    });

    test('does not fall back for a real unsupported language', () {
      expect(
        resolveAzureAssessmentLocaleForPractice(
          'xx',
          learningLanguage: 'en-US',
        ),
        isNull,
      );
      expect(
        isAzurePronunciationAssessmentSupportedForPractice(
          'sw',
          learningLanguage: 'en-US',
        ),
        isFalse,
      );
    });

    test('keeps exact supported locales', () {
      expect(
        resolveAzureAssessmentLocaleForPractice(
          'fr-CA',
          learningLanguage: 'en-US',
        ),
        'fr-CA',
      );
    });
  });

  group('mapTranscriptLanguageToAzure', () {
    test('maps a supported ASR catalog language', () {
      expect(mapTranscriptLanguageToAzure('fr-CA'), 'fr-CA');
    });

    test('does not fall back to en-US for unsupported languages', () {
      expect(mapTranscriptLanguageToAzure('und'), isNull);
      expect(mapTranscriptLanguageToAzure('xx'), isNull);
    });
  });

  group('canonicalLookupTag', () {
    test('maps en variants to en-US', () {
      expect(canonicalLookupTag('en'), 'en-US');
      expect(canonicalLookupTag('EN'), 'en-US');
      expect(canonicalLookupTag('en-us'), 'en-US');
      expect(canonicalLookupTag('en-US'), 'en-US');
      expect(canonicalLookupTag('en-GB'), 'en-US');
    });

    test('maps zh variants to zh-CN', () {
      expect(canonicalLookupTag('zh'), 'zh-CN');
      expect(canonicalLookupTag('zh-cn'), 'zh-CN');
      expect(canonicalLookupTag('zh-CN'), 'zh-CN');
      expect(canonicalLookupTag('zh-Hans'), 'zh-CN');
    });

    test('returns null for invalid or unsupported lookup tags', () {
      expect(canonicalLookupTag(null), null);
      expect(canonicalLookupTag('und'), null);
      expect(canonicalLookupTag('ja'), null);
      expect(canonicalLookupTag('fr-FR'), null);
    });
  });

  group('workerLanguageBase', () {
    test('strips region script', () {
      expect(workerLanguageBase('en-US'), 'en');
      expect(workerLanguageBase('zh-CN'), 'zh');
      expect(workerLanguageBase('  EN-us  '), 'en');
    });

    test('empty falls back to en', () {
      expect(workerLanguageBase(''), 'en');
      expect(workerLanguageBase('   '), 'en');
    });
  });

  group('coerceLookupSource', () {
    test('uses default learning when transcript unsupported', () {
      expect(coerceLookupSource('und'), kDefaultLearningLanguageTag);
      expect(coerceLookupSource('ja'), kDefaultLearningLanguageTag);
    });
  });

  group('allowedNativeTags', () {
    test('excludes learning language from native choices', () {
      expect(allowedNativeTags('en-US'), contains('zh-CN'));
      expect(allowedNativeTags('zh-CN'), contains('en-US'));
      expect(allowedNativeTags('ja-JP'), isNot(contains('ja-JP')));
    });
  });
}
