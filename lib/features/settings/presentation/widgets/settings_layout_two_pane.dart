/// Two-pane Settings desktop layout (at/above the rail breakpoint).
///
/// Rail of [SettingsSectionRailItem]s + a detail pane rendering the selected
/// section's rows via the same `sections/*.dart` widgets used by
/// [SettingsLayoutSingleColumn]. Reads/writes
/// [settingsSelectedSectionProvider] so the selection survives a breakpoint
/// resize. The rail is exactly [visibleSettingsSections] — registry order
/// with the platform/build gates and search filter applied once, shared with
/// the single-column layout — see
/// specs/004-settings-redesign/contracts/settings-search.md §3.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/settings/application/settings_search_query_provider.dart';
import 'package:enjoy_player/features/settings/application/settings_selected_section_provider.dart';
import 'package:enjoy_player/features/settings/presentation/settings_section_spec.dart';
import 'package:enjoy_player/features/settings/presentation/widgets/settings_no_results.dart';
import 'package:enjoy_player/features/settings/presentation/widgets/settings_section_card.dart';
import 'package:enjoy_player/features/settings/presentation/widgets/settings_section_rail_item.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class SettingsLayoutTwoPane extends ConsumerWidget {
  const SettingsLayoutTwoPane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final query = ref.watch(settingsSearchQueryProvider);
    final selected = ref.watch(settingsSelectedSectionProvider);

    final sections = visibleSettingsSections(l10n, query);
    if (sections.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(top: t.space8),
          child: const SettingsNoResults(),
        ),
      );
    }

    final railSectionIds = [for (final spec in sections) spec.sectionId];
    final effectiveSelected = railSectionIds.contains(selected)
        ? selected
        : railSectionIds.first;
    if (effectiveSelected != selected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(settingsSelectedSectionProvider.notifier)
            .select(effectiveSelected);
      });
    }
    final spec = sections.firstWhere((s) => s.sectionId == effectiveSelected);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: t.sidebarWidth,
          child: SingleChildScrollView(
            padding: EdgeInsets.only(top: t.space8, bottom: t.space24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final railSpec in sections)
                  SettingsSectionRailItem(
                    icon: railSpec.icon,
                    label: railSpec.title(l10n),
                    selected: railSpec.sectionId == effectiveSelected,
                    onTap: () => ref
                        .read(settingsSelectedSectionProvider.notifier)
                        .select(railSpec.sectionId),
                  ),
              ],
            ),
          ),
        ),
        Container(width: 1, color: cs.outlineVariant.withValues(alpha: 0.18)),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              t.pageGutter,
              0,
              t.pageGutter,
              t.space32,
            ),
            // A self-surfaced body (About) supplies its own bordered card,
            // so it skips the shared [SettingsSectionCard] wrapper.
            child: spec.wrapInCard
                ? SettingsSectionCard(
                    title: spec.title(l10n),
                    hint: spec.hint(l10n),
                    icon: spec.icon,
                    padding: EdgeInsets.zero,
                    child: spec.body(),
                  )
                : spec.body(),
          ),
        ),
      ],
    );
  }
}
