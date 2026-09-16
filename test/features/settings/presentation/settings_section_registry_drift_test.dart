/// Section-registry drift detection for the Settings hub.
///
/// Adding a Settings section touches seven hand-synced places:
/// [SettingsSectionIds], `kSettingsRegistry`, `_localize()` in
/// `settings_registry_localizer.dart`, `settingsSectionVisual()`, the
/// single-column if-chain, the two-pane rail list, and the ARB keys. This
/// test makes the registry-side drift detectable: an id that is declared
/// but not registered (the old `account` / `transcript` sections were
/// localized + iconed with zero registry entries), a registry entry
/// pointing at a removed id, or a missing visuals/localizer case all fail
/// here instead of shipping as silent dead code or an unlabeled section.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/features/settings/application/settings_registry_localizer.dart';
import 'package:enjoy_player/features/settings/domain/settings_search_entry.dart';
import 'package:enjoy_player/features/settings/presentation/widgets/settings_section_visuals.dart';
import 'package:enjoy_player/l10n/app_localizations_en.dart';

void main() {
  final l10n = AppLocalizationsEn();
  final registeredSectionIds = kSettingsRegistry
      .where((d) => d.isSectionHeader)
      .map((d) => d.sectionId)
      .toSet();

  group('SettingsSectionIds <-> kSettingsRegistry', () {
    test('every declared section id has a registry header entry', () {
      const declaredIds = [
        SettingsSectionIds.cloudSync,
        SettingsSectionIds.appearanceLanguage,
        SettingsSectionIds.aiProviders,
        SettingsSectionIds.recording,
        SettingsSectionIds.keyboardShortcuts,
        SettingsSectionIds.developer,
        SettingsSectionIds.about,
      ];
      for (final id in declaredIds) {
        expect(
          registeredSectionIds.contains(id),
          isTrue,
          reason:
              'SettingsSectionIds.$id has no kSettingsRegistry header — '
              'either register it or delete the id (localized-but-unregistered '
              'ids are dead code; see the removed account / transcript ids)',
        );
      }
    });

    test(
      'every registry section id is a declared SettingsSectionIds value',
      () {
        const declaredIds = {
          SettingsSectionIds.cloudSync,
          SettingsSectionIds.appearanceLanguage,
          SettingsSectionIds.aiProviders,
          SettingsSectionIds.recording,
          SettingsSectionIds.keyboardShortcuts,
          SettingsSectionIds.developer,
          SettingsSectionIds.about,
        };
        for (final id in registeredSectionIds) {
          expect(
            declaredIds.contains(id),
            isTrue,
            reason:
                'kSettingsRegistry references "$id" which is not a '
                'SettingsSectionIds value',
          );
        }
      },
    );

    test('row entries always belong to a registered section', () {
      for (final d in kSettingsRegistry) {
        expect(
          registeredSectionIds.contains(d.sectionId),
          isTrue,
          reason:
              'registry row ${d.sectionId}/${d.rowId ?? "<header>"} has no '
              'section header entry',
        );
      }
    });
  });

  group('localizer + visuals cover every registered section', () {
    test('every registry entry localizes to a non-empty title', () {
      for (final entry in localizedSettingsRegistry(l10n)) {
        expect(
          entry.title,
          isNotEmpty,
          reason:
              'no localizer case for ${entry.sectionId}/'
              '${entry.rowId ?? "<header>"} — the search index would match '
              'nothing',
        );
      }
    });

    test('every registered section has icon + title + hint visuals', () {
      for (final id in registeredSectionIds) {
        final visual = settingsSectionVisual(id, l10n);
        expect(
          visual.hint,
          isNotEmpty,
          reason:
              'settingsSectionVisual() has no case for "$id" — the fallback '
              'renders the raw id as the title with an empty hint',
        );
        expect(visual.title, isNotEmpty, reason: id);
      }
    });
  });
}
