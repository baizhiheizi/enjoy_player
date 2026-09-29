import 'package:enjoy_player/core/application/app_language_catalog.dart';
import 'package:enjoy_player/core/application/language_descriptor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('kSupportedLookupLanguageTags', () {
    test('is exactly the descriptor rows carrying a lookup label', () {
      final labeledTags = <String>[
        for (final row in kLanguageDescriptorRows)
          if (row.lookupLabel != null) row.tag,
      ];
      expect(kSupportedLookupLanguageTags, labeledTags);
      expect(kLookupLanguageLabels.keys.toSet(), labeledTags.toSet());
      for (final row in kLanguageDescriptorRows) {
        final label = row.lookupLabel;
        if (label == null) continue;
        expect(label.trim(), isNotEmpty, reason: 'empty label for ${row.tag}');
      }
    });

    test(
      'keeps the shipped policy counts (2 native / 9 focus / 15 lookup)',
      () {
        expect(kSupportedNativeLanguageTags, hasLength(2));
        expect(kSupportedFocusLanguageTags, hasLength(9));
        expect(kSupportedLookupLanguageTags, hasLength(15));
        expect(kAzurePronunciationAssessmentLocales, hasLength(33));
      },
    );

    test(
      'focus and native tags are lookup tags (narrower pickers never widen)',
      () {
        final lookup = kSupportedLookupLanguageTags.toSet();
        expect(lookup.containsAll(kSupportedFocusLanguageTags), isTrue);
        expect(lookup.containsAll(kSupportedNativeLanguageTags), isTrue);
      },
    );

    test('every lookup tag is an Azure assessment locale', () {
      expect(
        kAzurePronunciationAssessmentLocales.containsAll(
          kSupportedLookupLanguageTags,
        ),
        isTrue,
      );
    });

    test('nb-NO is in every catalog and nn-NO is in none', () {
      expect(kSupportedNativeLanguageTags, isNot(contains('nb-NO')));
      expect(kSupportedFocusLanguageTags, contains('nb-NO'));
      expect(kSupportedLookupLanguageTags, contains('nb-NO'));
      expect(kLookupLanguageLabels['nb-NO'], 'Norsk (bokmål)');
      expect(kAzurePronunciationAssessmentLocales, contains('nb-NO'));
      expect(
        kLanguageDescriptorRows.map((row) => row.tag),
        isNot(contains('nn-NO')),
      );
    });

    test('no tag is in kInvalidLanguageTags', () {
      for (final tag in kSupportedLookupLanguageTags) {
        expect(kInvalidLanguageTags.contains(tag), isFalse);
        expect(
          kInvalidLanguageTags.contains(primaryLanguageSubtag(tag)),
          isFalse,
        );
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
