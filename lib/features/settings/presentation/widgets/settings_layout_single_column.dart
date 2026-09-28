/// Single-column Settings hub layout (below the two-pane breakpoint).
///
/// Maps over the section specs from
/// [visibleSettingsSections] — registry order, platform/build gates, and the
/// search filter applied once, shared with the two-pane rail — assembling
/// every section via [SettingsSectionCard] (always expanded) or
/// [SettingsCollapsibleSection] (default-collapsed sections), and
/// auto-expanding a collapsed section that contains a match — see
/// specs/004-settings-redesign/contracts/settings-search.md.
///
/// Each carded section is introduced by a small overline heading (Aurora
/// grouped-list rhythm); the two-pane layout names sections in its rail.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/editorial_header.dart';
import 'package:enjoy_player/features/settings/application/settings_search_query_provider.dart';
import 'package:enjoy_player/features/settings/application/settings_section_collapse_provider.dart';
import 'package:enjoy_player/features/settings/presentation/settings_section_spec.dart';
import 'package:enjoy_player/features/settings/presentation/widgets/settings_collapsible_section.dart';
import 'package:enjoy_player/features/settings/presentation/widgets/settings_no_results.dart';
import 'package:enjoy_player/features/settings/presentation/widgets/settings_section_card.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class SettingsLayoutSingleColumn extends ConsumerWidget {
  const SettingsLayoutSingleColumn({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final query = ref.watch(settingsSearchQueryProvider);
    final collapseState = ref.watch(settingsSectionCollapseProvider);
    final collapseNotifier = ref.read(settingsSectionCollapseProvider.notifier);

    final sections = visibleSettingsSections(l10n, query);
    if (sections.isEmpty) {
      return const SettingsNoResults();
    }

    final searching = query.trim().isNotEmpty;
    bool effectiveCollapsed(String sectionId) =>
        searching ? false : (collapseState[sectionId] ?? false);

    Widget sectionFor(SettingsSectionSpec spec) {
      if (spec.collapsedByDefault) {
        return SettingsCollapsibleSection(
          title: spec.title(l10n),
          hint: spec.hint(l10n),
          icon: spec.icon,
          collapsed: effectiveCollapsed(spec.sectionId),
          onToggle: () => collapseNotifier.toggle(spec.sectionId),
          wrapInCard: spec.wrapInCard,
          child: spec.body(),
        );
      }
      if (!spec.wrapInCard) return spec.body();
      return SettingsSectionCard(
        title: spec.title(l10n),
        hint: spec.hint(l10n),
        icon: spec.icon,
        padding: EdgeInsets.zero,
        child: spec.body(),
      );
    }

    Widget headed(SettingsSectionSpec spec) {
      final section = sectionFor(spec);
      // Self-surfaced sections (About) carry their own heading.
      if (!spec.wrapInCard) return section;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(t.space4, t.space12, 0, t.space8),
            child: EnjoyOverline(spec.title(l10n)),
          ),
          section,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final spec in sections) ...[
          headed(spec),
          // Self-surfaced sections (About) own their outer spacing.
          if (spec.wrapInCard) SizedBox(height: t.space8),
        ],
        SizedBox(height: t.space32),
      ],
    );
  }
}
