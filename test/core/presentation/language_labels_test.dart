import 'package:enjoy_player/core/application/app_language_catalog.dart';
import 'package:enjoy_player/core/application/language_descriptor.dart';
import 'package:enjoy_player/core/presentation/language_labels.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  group('focusLanguageLabel', () {
    test(
      'localized getters cover exactly the focus + native descriptor rows',
      () {
        final expectedKeys = <String>[
          for (final row in kLanguageDescriptorRows)
            if (row.focus || row.native) row.tag,
        ];
        expect(localizedLanguageLabelGetters.keys, expectedKeys);
        expect(localizedLanguageLabelGetters.keys.toSet(), <String>{
          ...kSupportedFocusLanguageTags,
          ...kSupportedNativeLanguageTags,
        });
      },
    );

    test('labels every supported focus tag with its own string', () {
      for (final tag in kSupportedFocusLanguageTags) {
        final label = focusLanguageLabel(l10n, tag);
        expect(label, isNot(tag), reason: '$tag fell through to the raw tag');
        expect(label.trim(), isNotEmpty, reason: 'empty label for $tag');
      }
    });

    test('labels every supported native tag with its own string', () {
      for (final tag in kSupportedNativeLanguageTags) {
        final label = localizedLanguageLabelGetters[tag]!(l10n);
        expect(label, isNot(tag), reason: '$tag fell through to the raw tag');
        expect(label.trim(), isNotEmpty, reason: 'empty label for $tag');
      }
    });

    test('labels nb-NO as Norwegian (Bokmål)', () {
      expect(focusLanguageLabel(l10n, 'nb-NO'), 'Norwegian (Bokmål)');
    });

    test('labels the unknown media tag', () {
      expect(focusLanguageLabel(l10n, 'und'), l10n.mediaLanguageUnknown);
    });

    test('resolves Norwegian macrolanguage and 639-2 aliases to Bokmål', () {
      for (final tag in <String>['no', 'no-NO', 'nb', 'nob', 'nor']) {
        expect(
          focusLanguageLabel(l10n, tag),
          'Norwegian (Bokmål)',
          reason: 'alias label for $tag',
        );
      }
    });

    test('resolves other supported aliases to their canonical label', () {
      expect(focusLanguageLabel(l10n, 'ja'), focusLanguageLabel(l10n, 'ja-JP'));
      expect(
        focusLanguageLabel(l10n, 'kor'),
        focusLanguageLabel(l10n, 'ko-KR'),
      );
    });

    test('keeps Nynorsk (nn) showing its raw tag, never "English"', () {
      expect(focusLanguageLabel(l10n, 'nn'), 'nn');
      expect(focusLanguageLabel(l10n, 'nn-NO'), 'nn-NO');
      expect(
        focusLanguageLabel(l10n, 'nn'),
        isNot(focusLanguageLabel(l10n, 'en-US')),
      );
    });

    test('keeps unrelated unsupported tags showing the raw tag', () {
      for (final tag in <String>['th-TH', 'vi-VN', 'xx-YY']) {
        expect(
          focusLanguageLabel(l10n, tag),
          tag,
          reason: 'raw label for $tag',
        );
      }
    });
  });

  group('focusLanguageChoices', () {
    test('exposes one entry per focus tag, in catalog order', () {
      final choices = focusLanguageChoices(l10n);
      expect(choices.map((c) => c.value).toList(), kSupportedFocusLanguageTags);
      expect(choices.any((c) => c.value == 'nb-NO'), isTrue);
    });
  });

  group('mediaLanguageChoices', () {
    test('includes Unknown plus every focus tag', () {
      final values = mediaLanguageChoices(l10n).map((c) => c.value).toList();
      expect(values.first, kUnknownMediaLanguageTag);
      expect(values.skip(1).toList(), kSupportedFocusLanguageTags);
      expect(values, contains('nb-NO'));
    });
  });
}
