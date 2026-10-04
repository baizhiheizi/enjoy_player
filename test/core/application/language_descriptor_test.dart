import 'package:enjoy_player/core/application/language_descriptor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('splitLanguageTag', () {
    test('splits a regional BCP-47 tag on the hyphen', () {
      expect(splitLanguageTag('en-US'), ['en', 'US']);
      expect(splitLanguageTag('zh-Hant-HK'), ['zh', 'Hant', 'HK']);
    });

    test('accepts underscore separators (Java-style locales)', () {
      expect(splitLanguageTag('en_US'), ['en', 'US']);
    });

    test('returns a single-element list for a bare primary subtag', () {
      expect(splitLanguageTag('en'), ['en']);
    });
  });

  group('normalizeLanguageAlias', () {
    test('maps an ISO 639-2 / legacy alias to its primary subtag', () {
      expect(normalizeLanguageAlias('kor'), 'ko');
      expect(normalizeLanguageAlias('KOR'), 'ko');
    });

    test('rewrites a regional alias while preserving an uppercased region', () {
      expect(normalizeLanguageAlias('kor-US'), 'ko-US');
      expect(normalizeLanguageAlias('no-NO'), 'nb-NO');
    });

    test('returns the input trimmed when no alias matches', () {
      expect(normalizeLanguageAlias('en-US'), 'en-US');
      expect(normalizeLanguageAlias('fr'), 'fr');
    });

    test('returns empty for empty or whitespace input', () {
      expect(normalizeLanguageAlias(''), '');
      expect(normalizeLanguageAlias('   '), '');
    });
  });

  group('firstTagPerPrimary', () {
    test('returns the first row per primary, preserving list order', () {
      final rows = <LanguageDescriptorRow>[
        const LanguageDescriptorRow(tag: 'en-US'),
        const LanguageDescriptorRow(tag: 'en-GB'),
        const LanguageDescriptorRow(tag: 'ja-JP'),
      ];
      expect(firstTagPerPrimary(rows), {'en': 'en-US', 'ja': 'ja-JP'});
    });

    test('returns an empty map for empty input', () {
      expect(firstTagPerPrimary(const []), isEmpty);
    });

    test('canonicalizes legacy aliases before bucketing', () {
      final rows = <LanguageDescriptorRow>[
        const LanguageDescriptorRow(tag: 'kor-US'),
        const LanguageDescriptorRow(tag: 'ko-KR'),
      ];
      expect(firstTagPerPrimary(rows), {'ko': 'kor-US'});
    });
  });

  group('LanguageDescriptorRow.isLookupRow', () {
    test('is true when lookupLabel is set', () {
      const row = LanguageDescriptorRow(tag: 'en-US', lookupLabel: 'English');
      expect(row.isLookupRow, isTrue);
    });

    test('is false when lookupLabel is null (assessment-only rows)', () {
      const row = LanguageDescriptorRow(tag: 'ar-EG');
      expect(row.isLookupRow, isFalse);
    });
  });
}
