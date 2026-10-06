/// Cloud sync row body — status pill, sign-in prompt, loading/error states.
///
/// Extracted 1:1 from `settings_screen.dart`'s inline Cloud sync `Consumer`;
/// preserves the `_SyncQueueStatusPill` states. Rendered inside a
/// [SettingsSectionCard] by the layout, not wrapped here.
library;

import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/skeleton.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/settings/presentation/widgets/settings_row.dart';
import 'package:enjoy_player/features/sync/application/sync_providers.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class CloudSyncSectionBody extends ConsumerWidget {
  const CloudSyncSectionBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final auth = ref.watch(authCtrlProvider);
    final queueCounts = ref.watch(
      syncQueueSnapshotProvider.select(
        (async) => (
          isLoading: async.isLoading,
          hasError: async.hasError,
          retryablePending: async.valueOrNull?.retryablePending ?? 0,
          permanentlyFailed: async.valueOrNull?.permanentlyFailed ?? 0,
        ),
      ),
    );

    return auth.when(
      data: (state) {
        if (state is AuthSignedIn) {
          if (queueCounts.hasError) {
            return SettingsRow(
              leadingIcon: EnjoyIcons.cloudSync,
              title: l10n.syncSettingsTileTitle,
              subtitle: l10n.error,
              valueBadge: SettingsValuePill(
                icon: EnjoyIcons.error,
                label: l10n.error,
                foregroundColor: cs.error,
              ),
              onTap: () => context.push('/settings/sync'),
            );
          }
          if (queueCounts.isLoading) {
            return SettingsRow(
              leadingIcon: EnjoyIcons.cloudSync,
              title: l10n.syncSettingsTileTitle,
              subtitle: l10n.loading,
              valueBadge: Skeleton.line(
                width: 100,
                height: 26,
                borderRadius: BorderRadius.circular(t.radiusFull),
              ),
              onTap: () => context.push('/settings/sync'),
            );
          }
          return SettingsRow(
            leadingIcon: EnjoyIcons.cloudSync,
            title: l10n.syncSettingsTileTitle,
            subtitle: l10n.settingsSectionSyncHint,
            valueBadge: _SyncQueueStatusPill(
              retryablePending: queueCounts.retryablePending,
              permanentlyFailed: queueCounts.permanentlyFailed,
              l10n: l10n,
            ),
            onTap: () => context.push('/settings/sync'),
          );
        }
        return SettingsRow(
          leadingIcon: EnjoyIcons.cloudOff,
          title: l10n.syncSettingsTileTitle,
          subtitle: l10n.syncSettingsTileSubtitleSignedOut,
          onTap: () => context.push('/settings/sync'),
        );
      },
      loading: () => SettingsRow(
        leading: Skeleton.circle(diameter: 48),
        title: l10n.syncSettingsTileTitle,
        showChevron: false,
      ),
      error: (Object e, StackTrace s) => Padding(
        padding: EdgeInsets.symmetric(horizontal: t.space8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: cs.errorContainer.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(t.radiusLg),
            border: Border.all(color: cs.error.withValues(alpha: 0.25)),
          ),
          child: Padding(
            padding: EdgeInsets.all(t.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.settingsAuthLoadFailed,
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: t.space12),
                EnjoyButton.tonal(
                  onPressed: () => ref.invalidate(authCtrlProvider),
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SyncQueueStatusPill extends StatelessWidget {
  const _SyncQueueStatusPill({
    required this.retryablePending,
    required this.permanentlyFailed,
    required this.l10n,
  });

  final int retryablePending;
  final int permanentlyFailed;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (retryablePending == 0 && permanentlyFailed == 0) {
      return SettingsValuePill(
        icon: EnjoyIcons.checkCircle,
        label: l10n.syncSettingsTileSubtitleUpToDate,
        foregroundColor: cs.primary,
      );
    }
    final hasFailed = permanentlyFailed > 0;
    return SettingsValuePill(
      icon: hasFailed ? EnjoyIcons.warning : EnjoyIcons.hourglass,
      label: l10n.syncSettingsTileSubtitleCounts(
        retryablePending,
        permanentlyFailed,
      ),
      foregroundColor: hasFailed ? cs.error : cs.onSurface,
    );
  }
}
