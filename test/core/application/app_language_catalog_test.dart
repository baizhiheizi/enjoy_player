import 'package:enjoy_player/core/application/app_language_catalog.dart';
import 'package:enjoy_player/core/application/language_descriptor.dart';
import 'package:enjoy_player/features/ai/data/azure_language_mapper.dart';
import 'package:flutter/widgets.dart';
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

  group('descriptor derivations', () {
    test('media tags are Unknown followed by the focus tags', () {
      expect(kSupportedMediaLanguageTags, <String>[
        kUnknownMediaLanguageTag,
        ...kSupportedFocusLanguageTags,
      ]);
    });

    test(
      'azure default-by-primary keys are exactly the focus + native primaries',
      () {
        final expectedPrimaries = <String>{
          for (final tag in kSupportedFocusLanguageTags)
            primaryLanguageSubtag(tag),
          for (final tag in kSupportedNativeLanguageTags)
            primaryLanguageSubtag(tag),
        };
        expect(kAzureDefaultLocaleByPrimary.keys.toSet(), expectedPrimaries);
      },
    );

    test(
      'azure broad-tag defaults stay inside their primary and the Azure set',
      () {
        for (final entry in kAzureDefaultLocaleByPrimary.entries) {
          expect(
            primaryLanguageSubtag(entry.value),
            entry.key,
            reason: 'default for ${entry.key} crosses primaries',
          );
          expect(
            kAzurePronunciationAssessmentLocales.contains(entry.value),
            isTrue,
            reason: 'default ${entry.value} is not an assessment locale',
          );
        }
      },
    );

    test('azure assessment locales are exactly the azureAssessment rows', () {
      final azureRows = <String>{
        for (final row in kLanguageDescriptorRows)
          if (row.azureAssessment) row.tag,
      };
      expect(kAzurePronunciationAssessmentLocales, azureRows);
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

  group('allowedNativeTags', () {
    test('excludes learning language from native choices', () {
      expect(allowedNativeTags('en-US'), contains('zh-CN'));
      expect(allowedNativeTags('zh-CN'), contains('en-US'));
      expect(allowedNativeTags('ja-JP'), isNot(contains('ja-JP')));
    });
  });

  group('primaryLanguageSubtag', () {
    test('extracts the primary subtag lowercased', () {
      expect(primaryLanguageSubtag('en-US'), 'en');
      expect(primaryLanguageSubtag('zh-CN'), 'zh');
      expect(primaryLanguageSubtag('JA-jp'), 'ja');
    });

    test('accepts both hyphen and underscore separators', () {
      expect(primaryLanguageSubtag('en_US'), 'en');
      expect(primaryLanguageSubtag('zh_CN'), 'zh');
    });

    test('normalizes legacy aliases before splitting', () {
      expect(primaryLanguageSubtag('kor'), 'ko');
      expect(primaryLanguageSubtag('KOR-US'), 'ko');
    });

    test('returns the trimmed string for empty input', () {
      expect(primaryLanguageSubtag(''), '');
      expect(primaryLanguageSubtag('   '), '');
    });
  });

  group('normalizeBcp47Tag', () {
    test('lowercases primary and uppercases region', () {
      expect(normalizeBcp47Tag('en-us'), 'en-US');
      expect(normalizeBcp47Tag('zh-cn'), 'zh-CN');
      expect(normalizeBcp47Tag('ja-jp'), 'ja-JP');
    });

    test('accepts underscore input and normalizes separator', () {
      expect(normalizeBcp47Tag('en_us'), 'en-US');
    });

    test('keeps primary-only tags lowercased', () {
      expect(normalizeBcp47Tag('EN'), 'en');
      expect(normalizeBcp47Tag('Ja'), 'ja');
    });

    test('returns trimmed empty string for empty input', () {
      expect(normalizeBcp47Tag(''), '');
      expect(normalizeBcp47Tag('   '), '');
    });
  });

  group('tagsEqual', () {
    test('matches tags across separator and case shapes', () {
      expect(tagsEqual('en-US', 'en_us'), true);
      expect(tagsEqual('EN-us', 'en-US'), true);
      expect(tagsEqual('zh-CN', 'zh-cn'), true);
    });

    test('rejects different languages', () {
      expect(tagsEqual('en-US', 'zh-CN'), false);
      expect(tagsEqual('en', 'fr'), false);
    });

    test('matches primary-only and regional pairs when primary matches', () {
      expect(tagsEqual('en', 'en-US'), false);
      expect(tagsEqual('en', 'en'), true);
    });
  });

  group('displayLocaleFromRawOrDefault', () {
    test('returns default for null and empty input', () {
      expect(displayLocaleFromRawOrDefault(null), kAppDefaultDisplayLocale);
      expect(displayLocaleFromRawOrDefault(''), kAppDefaultDisplayLocale);
      expect(displayLocaleFromRawOrDefault('   '), kAppDefaultDisplayLocale);
    });

    test('matches by language code when region is missing or unsupported', () {
      expect(displayLocaleFromRawOrDefault('en'), const Locale('en', 'US'));
      expect(displayLocaleFromRawOrDefault('EN'), const Locale('en', 'US'));
      expect(displayLocaleFromRawOrDefault('zh'), const Locale('zh', 'CN'));
    });

    test('preserves a supported region when present', () {
      expect(displayLocaleFromRawOrDefault('en-US'), const Locale('en', 'US'));
      expect(displayLocaleFromRawOrDefault('zh-CN'), const Locale('zh', 'CN'));
    });

    test('accepts underscore-separated input', () {
      expect(displayLocaleFromRawOrDefault('en_US'), const Locale('en', 'US'));
    });
  });

  group('Norwegian Bokmål (nb-NO)', () {
    // ADR-0087: `no` is a macrolanguage tag; essentially all Norwegian
    // content in the wild is Bokmål, so `no` / `nob` / `nor` collapse onto
    // `nb-NO`. Nynorsk (`nn`) is deliberately left unsupported.
    const bokmalAliases = <String>['no', 'no-NO', 'nb', 'nb-NO', 'nob', 'nor'];

    test('is in the focus, media, and lookup catalogs', () {
      expect(kSupportedFocusLanguageTags, contains('nb-NO'));
      expect(kSupportedMediaLanguageTags, contains('nb-NO'));
      expect(kSupportedLookupLanguageTags, contains('nb-NO'));
      expect(kLookupLanguageLabels, contains('nb-NO'));
    });

    test('macrolanguage and 639-2 aliases canonicalize for focus', () {
      for (final tag in bokmalAliases) {
        expect(
          canonicalFocusLanguageTag(tag),
          'nb-NO',
          reason: 'focus canonicalization for $tag',
        );
      }
    });

    test('macrolanguage and 639-2 aliases canonicalize for media', () {
      for (final tag in bokmalAliases) {
        expect(
          canonicalMediaLanguageTag(tag),
          'nb-NO',
          reason: 'media canonicalization for $tag',
        );
      }
    });

    test('macrolanguage and 639-2 aliases resolve an Azure locale', () {
      for (final tag in bokmalAliases) {
        expect(
          resolveAzureAssessmentLocale(tag),
          'nb-NO',
          reason: 'Azure assessment locale for $tag',
        );
      }
      expect(isAzurePronunciationAssessmentSupportedForPractice('no'), isTrue);
    });

    test('worker base is nb for every alias shape', () {
      for (final tag in bokmalAliases) {
        expect(
          workerLanguageBase(tag),
          'nb',
          reason: 'workerLanguageBase for $tag',
        );
      }
    });

    test('aliases collapse to the nb primary subtag', () {
      for (final tag in bokmalAliases) {
        expect(primaryLanguageSubtag(tag), 'nb', reason: 'primary for $tag');
      }
    });

    test('keeps Nynorsk (nn) unsupported rather than coercing to en-US', () {
      expect(resolveAzureAssessmentLocale('nn'), isNull);
      expect(resolveAzureAssessmentLocale('nn-NO'), isNull);
      expect(canonicalMediaLanguageTag('nn'), 'nn');
      expect(canonicalLookupTag('nb-NO'), isNull);
      expect(kSupportedFocusLanguageTags, isNot(contains('nn-NO')));
    });

    test('is not a native / display language', () {
      expect(kSupportedNativeLanguageTags, isNot(contains('nb-NO')));
      expect(kAppDisplayLocales, isNot(contains(const Locale('nb', 'NO'))));
    });
  });

  group('coerceNativeIfEqualsLearning', () {
    test('returns the first allowed native when input is null', () {
      final coerced = coerceNativeIfEqualsLearning(null, 'en-US');
      expect(kSupportedNativeLanguageTags, contains(coerced));
      expect(coerced, isNot(equals('en-US')));
    });

    test('returns the first allowed native when input equals learning', () {
      final coerced = coerceNativeIfEqualsLearning('en-US', 'en-US');
      expect(coerced, isNot(equals('en-US')));
      expect(kSupportedNativeLanguageTags, contains(coerced));
    });

    test('returns the first allowed native for unsupported input', () {
      final coerced = coerceNativeIfEqualsLearning('xx-YY', 'en-US');
      expect(kSupportedNativeLanguageTags, contains(coerced));
    });

    test(
      'passes through a valid supported native that differs from learning',
      () {
        expect(coerceNativeIfEqualsLearning('zh-CN', 'en-US'), 'zh-CN');
      },
    );
  });
}
