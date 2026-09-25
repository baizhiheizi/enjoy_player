/// Section-registry drift detection for the Settings hub.
///
/// Adding a Settings section touches the domain descriptors
/// ([SettingsSectionIds] + `kSettingsRegistry`), the presentation spec list
/// ([kSettingsSectionSpecs]), and the three ARB files — there is no
/// per-section `switch`/if-chain left to keep in sync. This test guards the
/// cross-layer seams that remain: spec ↔ registry coverage (both directions,
/// including rows and default-collapse flags), per-locale title/hint
/// resolution, and the const-body identity contract. The locale check reads
/// the raw ARB files as well as the generated `AppLocalizations` classes,
/// because zh_CN inherits missing keys from zh at runtime — a key dropped from
/// one locale's ARB would otherwise silently fall back instead of failing
/// here. The spec's message keys are discovered structurally by invoking each
/// accessor on a recording `AppLocalizations`, so reformatting or rewriting
/// the spec source cannot silently detach the test from the keys it guards.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/features/settings/domain/settings_search_entry.dart';
import 'package:enjoy_player/features/settings/presentation/settings_section_spec.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:enjoy_player/l10n/app_localizations_en.dart';
import 'package:enjoy_player/l10n/app_localizations_zh.dart';

/// Records every l10n getter a spec accessor reads and answers `''` for each,
/// so `title`/`hint`/`searchableText` closures can be invoked without a real
/// locale. The recorded member names *are* the ARB message keys the spec
/// depends on — a structural replacement for grepping the spec source, immune
/// to reformatting.
class _RecordingLocalizations implements AppLocalizations {
  /// ARB message keys read so far, in invocation order (duplicates kept so
  /// the per-spec guard below counts accesses, not distinct keys).
  final List<String> accessed = <String>[];

  @override
  dynamic noSuchMethod(Invocation invocation) {
    // Spec accessors only read getters; record the key and answer `''`.
    if (invocation.isGetter) {
      accessed.add(_symbolName(invocation.memberName));
    }
    return '';
  }
}

/// `Symbol('foo').toString()` is `Symbol("foo")` on the Dart VM that
/// `flutter test` runs on; fall back to the raw text so an unexpected format
/// fails the ARB check visibly instead of passing a phantom key.
String _symbolName(Symbol symbol) {
  final text = symbol.toString();
  final match = RegExp(r'^Symbol\("(.*)"\)$').firstMatch(text);
  return match?.group(1) ?? text;
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

    test('every SettingsSectionIds constant is a registered section', () {
      // Hand-listed because Dart cannot reflect over static consts. A
      // declared-but-unregistered id renders nowhere (dead code); adding a
      // constant here without a kSettingsRegistry header entry fails.
      const declaredIds = <String>{
        SettingsSectionIds.cloudSync,
        SettingsSectionIds.appearanceLanguage,
        SettingsSectionIds.aiProviders,
        SettingsSectionIds.recording,
        SettingsSectionIds.keyboardShortcuts,
        SettingsSectionIds.developer,
        SettingsSectionIds.about,
      };
      expect(
        declaredIds,
        registeredSectionIds,
        reason:
            'a SettingsSectionIds constant that is neither registered nor '
            'specced is dead code — register it or delete it',
      );
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

    test(
      'body() returns the same canonical const widget instance per call',
      () {
        // `() => const XSectionBody()` closures return the canonical const
        // instance; an `XSectionBody.new` tear-off would allocate a fresh
        // widget per call (regression guard for the pre-spec `const` literals).
        for (final spec in kSettingsSectionSpecs) {
          expect(
            identical(spec.body(), spec.body()),
            isTrue,
            reason:
                '${spec.sectionId} body must be a `() => const XSectionBody()` '
                'closure, not a constructor tear-off — tear-offs do not '
                'preserve const, so each call would allocate a new widget',
          );
        }
      },
    );
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

    test('every l10n key read by the specs exists in all three ARB files', () {
      // Discover keys structurally: invoke every l10n-reading accessor
      // (section title/hint/searchable text, row titles/searchable text)
      // against a recording AppLocalizations and collect the getters read.
      final keys = <String>{};
      for (final spec in kSettingsSectionSpecs) {
        final rec = _RecordingLocalizations();
        spec.title(rec);
        spec.hint(rec);
        spec.searchableText?.call(rec);
        spec.resolveSearchableText(rec);
        for (final row in spec.rows) {
          row.title(rec);
          row.searchableText?.call(rec);
        }
        expect(
          rec.accessed.length,
          greaterThanOrEqualTo(2),
          reason:
              '${spec.sectionId} title/hint accessors read fewer than two '
              'l10n getters — spec accessors must resolve through '
              'AppLocalizations, not literals (read: ${rec.accessed})',
        );
        keys.addAll(rec.accessed);
      }
      expect(keys, isNotEmpty);
      for (final path in [
        'lib/l10n/app_en.arb',
        'lib/l10n/app_zh.arb',
        'lib/l10n/app_zh_CN.arb',
      ]) {
        final arb =
            json.decode(File(path).readAsStringSync()) as Map<String, dynamic>;
        final missing = <String>[
          for (final key in keys)
            if (arb[key] is! String || (arb[key] as String).isEmpty) key,
        ];
        expect(
          missing,
          isEmpty,
          reason:
              '$path is missing (or has an empty value for) spec message '
              'keys: $missing',
        );
      }
    });

    test('row search tokens are bilingual and thread into zh search', () {
      // Row searchableText is locale-resolved (a function of l10n): zh
      // users must find rows via tokens their titles never contain.
      final zhLocales = <String, AppLocalizations>{
        'zh': AppLocalizationsZh(),
        'zh_CN': AppLocalizationsZhCn(),
      };
      const zhTokensByRow = <String, List<String>>{
        'micPicker': ['麦克风'],
        'contact': ['邮件', '微信', '反馈'],
        'analyticsCapture': ['数据', '遥测', '分析'],
      };
      final rowSpecs = {
        for (final spec in kSettingsSectionSpecs)
          for (final row in spec.rows) row.rowId: row,
      };
      for (final entry in zhLocales.entries) {
        final l10n = entry.value;
        for (final rowId in zhTokensByRow.keys) {
          final row = rowSpecs[rowId];
          expect(row, isNotNull, reason: 'row "$rowId" missing from specs');
          final tokens = row!.searchableText?.call(l10n);
          expect(
            tokens,
            isNotNull,
            reason:
                '${entry.key} row "$rowId" must define searchableText with '
                'zh tokens',
          );
          expect(
            tokens,
            containsAll(zhTokensByRow[rowId]!),
            reason: '${entry.key} searchableText for row "$rowId"',
          );
        }
        // "邮件" appears in no zh title (the contact title is 联系开发者),
        // so this only passes if row tokens thread through
        // localizedSettingsRegistry into filterSettingsEntries.
        final matched = filterSettingsEntries(
          '邮件',
          localizedSettingsRegistry(l10n),
        );
        expect(
          matched.map((e) => e.rowId),
          contains('contact'),
          reason: 'zh query "邮件" must find the contact row in ${entry.key}',
        );
      }
    });
  });
}
