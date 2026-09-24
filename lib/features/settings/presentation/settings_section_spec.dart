/// Presentation-layer section specs for the Settings hub — icon, localized
/// title/hint/keywords, visibility predicate, body builder, and card/collapse
/// shape, one entry per top-level section.
///
/// The pure domain descriptors in `domain/settings_search_entry.dart` stay
/// Flutter-free and back the search index and the default-collapse seed; this
/// file resolves them to renderable specs. Both layouts map over
/// [kSettingsSectionSpecs] via [visibleSettingsSections] (domain-registry
/// order, platform/build gates, and search filtering applied once) — there is
/// no per-section `switch`/if-chain over [SettingsSectionIds] anywhere else.
/// See specs/004-settings-redesign/contracts/settings-section-registry.md.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:enjoy_player/core/window/desktop_window.dart';
import 'package:enjoy_player/features/settings/domain/settings_search_entry.dart';
import 'package:enjoy_player/features/settings/presentation/widgets/sections/about_section.dart';
import 'package:enjoy_player/features/settings/presentation/widgets/sections/ai_providers_section.dart';
import 'package:enjoy_player/features/settings/presentation/widgets/sections/appearance_language_section.dart';
import 'package:enjoy_player/features/settings/presentation/widgets/sections/cloud_sync_section.dart';
import 'package:enjoy_player/features/settings/presentation/widgets/sections/developer_section.dart';
import 'package:enjoy_player/features/settings/presentation/widgets/sections/keyboard_shortcuts_section.dart';
import 'package:enjoy_player/features/settings/presentation/widgets/sections/recording_section.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// One searchable row of a section — the `rowId` of a
/// [SettingsEntryDescriptor] plus its localized title and extra keywords.
class SettingsRowSpec {
  const SettingsRowSpec({
    required this.rowId,
    required this.title,
    this.keywords = const [],
  });

  /// Stable per-section row id (matches `kSettingsRegistry`).
  final String rowId;

  /// Resolved display title, used both for rendering and for search matching.
  final String Function(AppLocalizations l10n) title;

  /// Extra localized synonyms matched by search but not displayed
  /// (e.g. "mic" for the microphone picker row).
  final List<String> keywords;
}

/// Presentation shape of one top-level Settings section.
class SettingsSectionSpec {
  const SettingsSectionSpec({
    required this.sectionId,
    required this.icon,
    required this.title,
    required this.hint,
    this.keywords,
    this.rows = const [],
    this.isVisible = _alwaysVisible,
    required this.body,
    this.wrapInCard = true,
    this.collapsedByDefault = false,
  });

  /// Stable section id — the same value as the [SettingsSectionIds] constant
  /// and the matching `kSettingsRegistry` header descriptor.
  final String sectionId;

  /// Header/rail icon for the section.
  final IconData icon;

  /// Resolved section header title.
  final String Function(AppLocalizations l10n) title;

  /// Resolved section header hint (subtitle).
  final String Function(AppLocalizations l10n) hint;

  /// Extra search synonyms for the section header. Defaults to the hint (the
  /// pre-spec localizer indexed every header by its hint text).
  final List<String> Function(AppLocalizations l10n)? keywords;

  /// The section's rows for the search index — one per row descriptor in
  /// `kSettingsRegistry` (drift-checked by the section-registry drift test).
  final List<SettingsRowSpec> rows;

  /// Platform/build gate for the whole section (FR-005/FR-006). Expressing
  /// it here means both layouts and the rail share one predicate — they can
  /// never disagree about which sections are visible on a given build.
  final bool Function() isVisible;

  /// Builds the section's body content (the `widgets/sections/*.dart`
  /// widget). Layouts supply the card/collapse chrome around it.
  final Widget Function() body;

  /// Whether the section body sits inside the shared card surface. `false`
  /// only when the body renders its own bordered/gradient surface (About) —
  /// avoids a card-inside-a-card look and marks the section as owning its
  /// own outer spacing in the single-column stack.
  final bool wrapInCard;

  /// Whether the single-column layout seeds this section collapsed in
  /// `settingsSectionCollapseProvider` and renders it through
  /// `SettingsCollapsibleSection`. Must match the header descriptor's
  /// `collapsedByDefault` (drift-checked).
  final bool collapsedByDefault;

  /// Search keywords for the section header — the hint by default.
  List<String> resolveKeywords(AppLocalizations l10n) =>
      keywords?.call(l10n) ?? <String>[hint(l10n)];
}

bool _alwaysVisible() => true;

/// Every top-level Settings section, in any order — **ordering derives from
/// the domain registry**: [visibleSettingsSections] walks `kSettingsRegistry`
/// section headers and resolves each through this list, so the rail, the
/// single-column stack, the search index, and the collapse seed always agree
/// on membership and order. Ids are what matter here; the drift test asserts
/// this list covers exactly the registry's section headers.
final List<SettingsSectionSpec> kSettingsSectionSpecs = [
  SettingsSectionSpec(
    sectionId: SettingsSectionIds.cloudSync,
    icon: Icons.cloud_sync_outlined,
    title: (l10n) => l10n.settingsSectionSync,
    hint: (l10n) => l10n.settingsSectionSyncHint,
    rows: [
      SettingsRowSpec(
        rowId: 'syncStatus',
        title: (l10n) => l10n.syncSettingsTileTitle,
      ),
    ],
    body: CloudSyncSectionBody.new,
  ),
  SettingsSectionSpec(
    sectionId: SettingsSectionIds.appearanceLanguage,
    icon: Icons.palette_outlined,
    title: (l10n) => l10n.settingsSectionAppearanceLanguage,
    hint: (l10n) => l10n.settingsSectionAppearanceLanguageHint,
    rows: [
      SettingsRowSpec(
        rowId: 'displayLanguage',
        title: (l10n) => l10n.settingsAppearanceDisplayLanguage,
      ),
      SettingsRowSpec(
        rowId: 'learningLanguage',
        title: (l10n) => l10n.settingsAppearanceLearningLanguage,
      ),
      SettingsRowSpec(
        rowId: 'nativeLanguage',
        title: (l10n) => l10n.settingsAppearanceNativeLanguage,
      ),
    ],
    body: AppearanceLanguageSectionBody.new,
  ),
  SettingsSectionSpec(
    sectionId: SettingsSectionIds.aiProviders,
    icon: Icons.auto_awesome_outlined,
    title: (l10n) => l10n.settingsSectionAi,
    hint: (l10n) => l10n.settingsSectionAiHint,
    rows: [
      SettingsRowSpec(
        rowId: 'aiProviders',
        title: (l10n) => l10n.settingsAiProvidersTileTitle,
      ),
    ],
    body: AiProvidersSectionBody.new,
  ),
  SettingsSectionSpec(
    sectionId: SettingsSectionIds.recording,
    icon: Icons.mic_none_rounded,
    title: (l10n) => l10n.settingsSectionRecording,
    hint: (l10n) => l10n.settingsSectionRecordingHint,
    rows: [
      SettingsRowSpec(
        rowId: 'micPicker',
        title: (l10n) => l10n.settingsRecordingMicTitle,
        keywords: ['mic'],
      ),
    ],
    body: RecordingSectionBody.new,
  ),
  SettingsSectionSpec(
    sectionId: SettingsSectionIds.keyboardShortcuts,
    icon: Icons.keyboard_outlined,
    title: (l10n) => l10n.hotkeysSectionKeyboard,
    hint: (l10n) => l10n.hotkeysSectionKeyboardHint,
    isVisible: () => isDesktop,
    rows: [
      SettingsRowSpec(
        rowId: 'openCheatsheet',
        title: (l10n) => l10n.settingsKeyboardOpenCheatsheet,
      ),
      SettingsRowSpec(
        rowId: 'customize',
        title: (l10n) => l10n.settingsKeyboardCustomizeTitle,
      ),
    ],
    body: KeyboardShortcutsSectionBody.new,
  ),
  SettingsSectionSpec(
    sectionId: SettingsSectionIds.developer,
    icon: Icons.developer_mode_outlined,
    title: (l10n) => l10n.settingsSectionDeveloper,
    hint: (l10n) => l10n.settingsSectionDeveloperHint,
    isVisible: () => !kReleaseMode,
    rows: [
      SettingsRowSpec(
        rowId: 'apiBaseUrl',
        title: (l10n) => l10n.settingsApiBaseUrl,
      ),
      SettingsRowSpec(
        rowId: 'aiApiBaseUrl',
        title: (l10n) => l10n.settingsAiApiBaseUrl,
      ),
      SettingsRowSpec(
        rowId: 'aiPlayground',
        title: (l10n) => l10n.settingsAiPlaygroundTileTitle,
      ),
    ],
    body: DeveloperSectionBody.new,
    collapsedByDefault: true,
  ),
  SettingsSectionSpec(
    sectionId: SettingsSectionIds.about,
    icon: Icons.info_outline_rounded,
    title: (l10n) => l10n.settingsSectionAbout,
    hint: (l10n) => l10n.settingsSectionAboutHint,
    rows: [
      SettingsRowSpec(
        rowId: 'contact',
        title: (l10n) => l10n.settingsAboutContactTitle,
        keywords: ['email', 'wechat', 'mixin', 'feedback', 'bug report'],
      ),
      SettingsRowSpec(
        rowId: 'analyticsCapture',
        title: (l10n) => l10n.settingsAnalyticsCaptureTitle,
        keywords: [
          'analytics',
          'usage',
          'privacy',
          'telemetry',
          'posthog',
          '数据',
        ],
      ),
    ],
    body: AboutSectionBody.new,
    wrapInCard: false,
    collapsedByDefault: true,
  ),
];

final Map<String, SettingsSectionSpec> _specsById = {
  for (final spec in kSettingsSectionSpecs) spec.sectionId: spec,
};

/// Resolves `kSettingsRegistry` descriptors into localized, searchable
/// [SettingsSearchEntry] values (section headers and rows alike) by looking
/// each descriptor up in its section's [SettingsSectionSpec] — this replaces
/// the old application-layer `_localize()` switch. An id with no spec/row
/// resolves to an empty title (the drift test fails on that; the old
/// localizer's fallback behaved the same way).
List<SettingsSearchEntry> localizedSettingsRegistry(AppLocalizations l10n) {
  final entries = <SettingsSearchEntry>[];
  for (final d in kSettingsRegistry) {
    final spec = _specsById[d.sectionId];
    if (spec == null) {
      entries.add(SettingsSearchEntry(descriptor: d, title: ''));
      continue;
    }
    if (d.isSectionHeader) {
      entries.add(
        SettingsSearchEntry(
          descriptor: d,
          title: spec.title(l10n),
          keywords: spec.resolveKeywords(l10n),
        ),
      );
      continue;
    }
    var title = '';
    var keywords = const <String>[];
    for (final row in spec.rows) {
      if (row.rowId == d.rowId) {
        title = row.title(l10n);
        keywords = row.keywords;
        break;
      }
    }
    entries.add(
      SettingsSearchEntry(descriptor: d, title: title, keywords: keywords),
    );
  }
  return entries;
}

/// The sections to render for the current platform/build and search [query],
/// in Settings hub display order (the order of `kSettingsRegistry`'s section
/// headers). This is the single source of visibility: per-spec
/// [SettingsSectionSpec.isVisible] platform/build gates plus the shared
/// domain search filter — both layouts and the two-pane rail read it, so
/// their visible-section sets are identical by construction (FR-005/FR-006;
/// contracts/settings-search.md §6).
List<SettingsSectionSpec> visibleSettingsSections(
  AppLocalizations l10n,
  String query,
) {
  final searching = query.trim().isNotEmpty;
  final matchedSectionIds = searching
      ? filterSettingsEntries(
          query,
          localizedSettingsRegistry(l10n),
        ).map((e) => e.sectionId).toSet()
      : const <String>{};
  final visible = <SettingsSectionSpec>[];
  for (final d in kSettingsRegistry) {
    if (!d.isSectionHeader) continue;
    final spec = _specsById[d.sectionId];
    if (spec == null) continue; // registry/spec drift — caught by the test
    if (!spec.isVisible()) continue;
    if (searching && !matchedSectionIds.contains(spec.sectionId)) continue;
    visible.add(spec);
  }
  return visible;
}
