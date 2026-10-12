/// Drill-in page for one Settings section (phone hub rows, deep links) —
/// the section body under the shared subpage chrome, mirroring the two-pane
/// detail pane's Literata title + hint above the card.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/layout/enjoy_page_kind.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_page.dart';
import 'package:enjoy_player/features/settings/presentation/settings_section_spec.dart';
import 'package:enjoy_player/features/settings/presentation/widgets/settings_section_card.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class SettingsSectionPageScreen extends ConsumerWidget {
  const SettingsSectionPageScreen({super.key, required this.sectionId});

  final String sectionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final spec = settingsSectionSpecById(sectionId);

    return EnjoyPage(
      kind: EnjoyPageKind.hub,
      title: spec?.title(l10n) ?? l10n.settingsSectionAbout,
      showBack: true,
      body: (context, metrics) {
        if (spec == null) {
          return ListView(
            padding: metrics.padding(bottom: t.space32),
            children: [
              Text(
                l10n.settingsSearchNoResultsTitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          );
        }
        final body = spec.body();
        return ListView(
          padding: metrics.padding(bottom: t.space32),
          children: [
            Text(
              spec.hint(l10n),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            SizedBox(height: t.space16),
            spec.wrapInCard
                ? SettingsSectionCard(
                    title: spec.title(l10n),
                    hint: spec.hint(l10n),
                    icon: spec.icon,
                    padding: EdgeInsets.zero,
                    child: body,
                  )
                : body,
          ],
        );
      },
    );
  }
}
