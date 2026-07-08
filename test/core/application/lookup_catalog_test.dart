import 'package:enjoy_player/core/application/app_language_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('kSupportedLookupLanguageTags', () {
    test('contains the first-wave 14 entries in a stable order', () {
      expect(kSupportedLookupLanguageTags, <String>[
        'en-US',
        'en-GB',
        'zh-CN',
        'ja-JP',
        'ko-KR',
        'es-ES',
        'es-MX',
        'fr-FR',
        'fr-CA',
        'de-DE',
        'it-IT',
        'pt-BR',
        'pt-PT',
        'ru-RU',
      ]);
    });

    test('every tag has a label in kLookupLanguageLabels', () {
      for (final tag in kSupportedLookupLanguageTags) {
        expect(
          kLookupLanguageLabels.containsKey(tag),
          isTrue,
          reason: 'missing label for $tag',
        );
        expect(
          (kLookupLanguageLabels[tag] ?? '').trim(),
          isNotEmpty,
          reason: 'empty label for $tag',
        );
      }
    });

    test('no tag is in kInvalidLanguageTags', () {
      for (final tag in kSupportedLookupLanguageTags) {
        expect(kInvalidLanguageTags.contains(tag), isFalse);
        expect(kInvalidLanguageTags.contains(_primary(tag)), isFalse);
      }
    });

    test('every tag round-trips through normalizeBcp47Tag', () {
      for (final tag in kSupportedLookupLanguageTags) {
        expect(normalizeBcp47Tag(tag), tag);
      }
    });

    test('every tag yields a non-empty workerLanguageBase', () {
      for (final tag in kSupportedLookupLanguageTags) {
        expect(workerLanguageBase(tag).isNotEmpty, isTrue);
      }
    });
  });

  group('sortLookupLanguages', () {
    test('places the learning language first (primary subtag match)', () {
      final sorted = sortLookupLanguages(
        kSupportedLookupLanguageTags,
        learningTag: 'ko-KR',
      );
      expect(sorted.first, 'ko-KR');
    });

    test('falls back to alphabetical when learning is unknown', () {
      final sorted = sortLookupLanguages(
        kSupportedLookupLanguageTags,
        learningTag: 'ar-SA',
      );
      expect(sorted.first, 'de-DE');
    });

    test('is stable for ties (preserves input order)', () {
      final input = <String>['ru-RU', 'pt-PT', 'ja-JP'];
      final sorted = sortLookupLanguages(input, learningTag: 'en-US');
      expect(sorted, <String>['ja-JP', 'pt-PT', 'ru-RU']);
    });

    test('does not mutate the input list', () {
      final input = <String>['ru-RU', 'ja-JP', 'de-DE'];
      final snapshot = List<String>.of(input);
      sortLookupLanguages(input, learningTag: 'en-US');
      expect(input, snapshot);
    });
  });
}

String _primary(String tag) =>
    normalizeLanguageAlias(tag).split(RegExp(r'[-_]')).first.toLowerCase();