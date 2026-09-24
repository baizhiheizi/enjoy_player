/// Section-registry drift detection for the Settings hub.
///
/// Adding a Settings section touches the domain descriptors
/// ([SettingsSectionIds] + `kSettingsRegistry`), the presentation spec list
/// ([kSettingsSectionSpecs]), and the three ARB files — there is no
/// per-section `switch`/if-chain left to keep in sync. This test guards the
/// cross-layer seams that remain: spec ↔ registry coverage (both directions,
/// including rows and default-collapse flags) and per-locale title/hint
/// resolution. The locale check reads the raw ARB files as well as the
/// generated `AppLocalizations` classes, because zh_CN inherits missing keys
/// from zh at runtime — a key dropped from one locale's ARB would otherwise
/// silently fall back instead of failing here.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/features/settings/domain/settings_search_entry.dart';
import 'package:enjoy_player/features/settings/presentation/settings_section_spec.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:enjoy_player/l10n/app_localizations_en.dart';
import 'package:enjoy_player/l10n/app_localizations_zh.dart';

/// The spec file's `title:`/`hint:` accessors, keyed by their ARB message
/// name. Matches only the 4-space-indented top-level spec fields (row titles
/// inside `rows:` are indented deeper) so the count below can be asserted
/// against [kSettingsSectionSpecs] — if the spec file's formatting or the
/// accessor style changes, this fails loudly instead of silently checking
/// zero keys.
List<String> _sectionMessageKeysFromSpecSource() {
  final source = File(
    'lib/features/settings/presentation/settings_section_spec.dart',
  ).readAsStringSync();
  return RegExp(
    r'^    (?:title|hint): \(l10n\) => l10n\.(\w+),?$',
    multiLine: true,
  ).allMatches(source).map((m) => m.group(1)!).toList(growable: false);
}

void main() {
  final specsById = {
    for (final spec in kSettingsSectionSpecs) spec.sectionId: spec,
  };
  final registeredSectionIds = kSettingsRegistry
      .where((d) => d.isSectionHeader)
      .map((d) => d.sectionId)
      .toSet();

  group('kSettingsRegistry <-> kSettingsSectionSpecs', () {
    test('spec section ids exactly cover the registry section headers', () {
      final specIds = kSettingsSectionSpecs.map((s) => s.sectionId).toSet();
      expect(
        specIds,
        registeredSectionIds,
        reason:
            'kSettingsSectionSpecs must cover exactly the kSettingsRegistry '
            'section headers — add the spec or register the section (a spec '
            'without a header, or a header without a spec, renders/lays out '
            'nothing consistently)',
      );
      expect(
        kSettingsSectionSpecs.length,
        specIds.length,
        reason: 'duplicate sectionId in kSettingsSectionSpecs',
      );
    });

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

    test('every registry row has exactly one spec row (and vice versa)', () {
      for (final id in registeredSectionIds) {
        final spec = specsById[id]!;
        final registryRowIds = kSettingsRegistry
            .where((d) => d.sectionId == id && d.rowId != null)
            .map((d) => d.rowId)
            .toSet();
        final specRowIds = spec.rows.map((r) => r.rowId).toSet();
        expect(
          specRowIds,
          registryRowIds,
          reason:
              'search rows for "$id" must exist in both kSettingsRegistry '
              'and the spec — otherwise search and the section drift apart',
        );
        expect(
          spec.rows.length,
          registryRowIds.length,
          reason: 'duplicate rowId in the "$id" spec',
        );
      }
    });

    test('spec collapsedByDefault matches the registry header descriptor', () {
      for (final d in kSettingsRegistry.where((d) => d.isSectionHeader)) {
        final spec = specsById[d.sectionId]!;
        expect(
          spec.collapsedByDefault,
          d.collapsedByDefault,
          reason:
              '"${d.sectionId}" default-collapse disagrees between the '
              'registry (collapse-state seed) and the spec (layout frame)',
        );
      }
    });
  });

  group('per-locale title/hint resolution (en, zh, zh_CN)', () {
    final locales = <String, AppLocalizations>{
      'en': AppLocalizationsEn(),
      'zh': AppLocalizationsZh(),
      'zh_CN': AppLocalizationsZhCn(),
    };

    for (final entry in locales.entries) {
      final name = entry.key;
      final l10n = entry.value;

      test('every spec resolves a non-empty title and hint in $name', () {
        for (final spec in kSettingsSectionSpecs) {
          expect(
            spec.title(l10n),
            isNotEmpty,
            reason: '${spec.sectionId} title in $name',
          );
          expect(
            spec.hint(l10n),
            isNotEmpty,
            reason: '${spec.sectionId} hint in $name',
          );
        }
      });

      test('every registry entry resolves a non-empty title in $name', () {
        for (final searchEntry in localizedSettingsRegistry(l10n)) {
          expect(
            searchEntry.title,
            isNotEmpty,
            reason:
                'no spec/row case for ${searchEntry.sectionId}/'
                '${searchEntry.rowId ?? "<header>"} in $name — the search '
                'index would match nothing',
          );
        }
      });
    }

    test('every spec title/hint message key exists in all three ARB files', () {
      final keys = _sectionMessageKeysFromSpecSource();
      expect(
        keys,
        hasLength(2 * kSettingsSectionSpecs.length),
        reason:
            'expected exactly one title + one hint accessor per spec in the '
            'spec source — the extraction regex above must cover them',
      );
      for (final path in [
        'lib/l10n/app_en.arb',
        'lib/l10n/app_zh.arb',
        'lib/l10n/app_zh_CN.arb',
      ]) {
        final arb =
            json.decode(File(path).readAsStringSync()) as Map<String, dynamic>;
        for (final key in keys) {
          expect(
            arb.containsKey(key),
            isTrue,
            reason: '$path is missing the section message "$key"',
          );
          expect(
            arb[key],
            isNotEmpty,
            reason: '$path has an empty section message "$key"',
          );
        }
      }
    });
  });
}
