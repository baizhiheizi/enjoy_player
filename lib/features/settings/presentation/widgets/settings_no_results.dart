/// Empty state shown when a Settings search query matches nothing.
///
/// Shared by [SettingsLayoutSingleColumn] and [SettingsLayoutTwoPane] — see
/// specs/004-settings-redesign/contracts/settings-search.md §2.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/settings/application/settings_search_query_provider.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class SettingsNoResults extends ConsumerWidget {
  const SettingsNoResults({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: t.space24,
        vertical: t.space40,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 40,
            color: cs.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          SizedBox(height: t.space16),
          Text(
            l10n.settingsSearchNoResultsTitle,
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: t.space8),
          Text(
            l10n.settingsSearchNoResultsHint,
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: t.space16),
          TextButton(
            onPressed: () =>
                ref.read(settingsSearchQueryProvider.notifier).clear(),
            child: Text(l10n.settingsSearchClear),
          ),
        ],
      ),
    );
  }
}
