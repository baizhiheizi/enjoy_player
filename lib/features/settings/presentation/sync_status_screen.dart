/// Sync queue status, last full sync time, and manual sync actions.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_card.dart';
import 'package:enjoy_player/core/theme/widgets/skeleton.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/presentation/widgets/auth_required_callout.dart';
import 'package:enjoy_player/features/settings/presentation/widgets/settings_row.dart';
import 'package:enjoy_player/features/sync/application/sync_controller.dart';
import 'package:enjoy_player/features/sync/application/sync_providers.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class SyncStatusScreen extends ConsumerStatefulWidget {
  const SyncStatusScreen({super.key});

  @override
  ConsumerState<SyncStatusScreen> createState() => _SyncStatusScreenState();
}

class _SyncStatusScreenState extends ConsumerState<SyncStatusScreen> {
  bool _busySync = false;
  bool _busyRetry = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = ref.watch(authCtrlProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.syncScreenTitle)),
      body: auth.when(
        data: (state) {
          if (state is! AuthSignedIn) {
            return const Center(
              child: AuthRequiredCallout(
                surface: AuthRequiredSurface.sync,
                compact: false,
              ),
            );
          }
          return _SignedInBody(
            busyRetry: _busyRetry,
            busySync: _busySync,
            onRetryFailed: () => _runRetryFailed(context, l10n),
            onSyncNow: () => _runSyncNow(context, l10n),
          );
        },
        loading: () => const SkeletonSettingsList(rowCount: 6),
        error: (Object e, StackTrace s) =>
            Center(child: Text(l10n.errorGenericLoadFailed)),
      ),
    );
  }

  Future<void> _runSyncNow(BuildContext context, AppLocalizations l10n) async {
    setState(() => _busySync = true);
    try {
      final result = await ref.read(syncCtrlProvider.notifier).triggerSync();
      if (!context.mounted) return;
      if (result.success) {
        AppNotice.success(context, l10n.syncSnackSuccess);
      } else {
        AppNotice.warning(
          context,
          l10n.syncSnackIssues(result.synced, result.failed),
        );
      }
    } finally {
      if (mounted) setState(() => _busySync = false);
    }
  }

  Future<void> _runRetryFailed(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    setState(() => _busyRetry = true);
    try {
      final result = await ref
          .read(syncCtrlProvider.notifier)
          .triggerSync(resetFailed: true);
      if (!context.mounted) return;
      if (result.success) {
        AppNotice.success(context, l10n.syncSnackSuccess);
      } else {
        AppNotice.warning(
          context,
          l10n.syncSnackIssues(result.synced, result.failed),
        );
      }
    } finally {
      if (mounted) setState(() => _busyRetry = false);
    }
  }
}

class _SignedInBody extends ConsumerWidget {
  const _SignedInBody({
    required this.busySync,
    required this.busyRetry,
    required this.onSyncNow,
    required this.onRetryFailed,
  });

  final bool busySync;
  final bool busyRetry;
  final VoidCallback onSyncNow;
  final VoidCallback onRetryFailed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final snapshotAsync = ref.watch(syncQueueSnapshotProvider);
    final lastSyncAsync = ref.watch(syncLastFullSyncAtProvider);

    final dateFmt = DateFormat.yMMMd().add_jm();

    String lastSyncLine(AppLocalizations l10n, String? iso) {
      if (iso == null || iso.isEmpty) return l10n.syncScreenLastSyncNever;
      final parsed = DateTime.tryParse(iso);
      if (parsed == null) return iso;
      return dateFmt.format(parsed.toLocal());
    }

    return ListView(
      padding: EdgeInsets.all(t.space16),
      children: [
        EnjoyCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SettingsRow(
                leadingIcon: Icons.history_rounded,
                title: l10n.syncScreenLastSyncLabel,
                showChevron: false,
                valueBadge: lastSyncAsync.when(
                  data: (iso) =>
                      SettingsValuePill(label: lastSyncLine(l10n, iso)),
                  loading: () => const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (e, _) => SettingsValuePill(
                    icon: Icons.error_outline_rounded,
                    label: l10n.error,
                    foregroundColor: cs.error,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: t.space16),
        snapshotAsync.when(
          data: (snap) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                EnjoyCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SettingsRow(
                        leadingIcon: Icons.hourglass_empty_rounded,
                        leadingIconTint: snap.retryablePending > 0
                            ? cs.primary
                            : null,
                        title: l10n.syncScreenStatRetryable,
                        showChevron: false,
                        valueBadge: SettingsValuePill(
                          label: '${snap.retryablePending}',
                          foregroundColor: snap.retryablePending > 0
                              ? cs.primary
                              : null,
                        ),
                      ),
                      const SettingsRowDivider(insetForLeading: false),
                      SettingsRow(
                        leadingIcon: Icons.error_outline_rounded,
                        leadingIconTint: snap.permanentlyFailed > 0
                            ? cs.error
                            : null,
                        title: l10n.syncScreenStatFailed,
                        showChevron: false,
                        valueBadge: SettingsValuePill(
                          label: '${snap.permanentlyFailed}',
                          foregroundColor: snap.permanentlyFailed > 0
                              ? cs.error
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: t.space16),
                FilledButton.icon(
                  onPressed: busySync ? null : onSyncNow,
                  icon: busySync
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync_rounded),
                  label: Text(l10n.syncScreenSyncNow),
                ),
                SizedBox(height: t.space12),
                OutlinedButton.icon(
                  onPressed: (busyRetry || snap.permanentlyFailed == 0)
                      ? null
                      : onRetryFailed,
                  icon: busyRetry
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded),
                  label: Text(l10n.syncScreenRetryFailed),
                ),
                SizedBox(height: t.space16),
                EnjoyCard(
                  padding: EdgeInsets.zero,
                  child: Theme(
                    data: Theme.of(
                      context,
                    ).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      title: Text(l10n.syncQueueDetails),
                      initiallyExpanded: false,
                      children: snap.detailRows.isEmpty
                          ? [
                              Padding(
                                padding: EdgeInsets.all(t.space16),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    l10n.syncQueueEmpty,
                                    style: tt.bodyMedium?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ),
                            ]
                          : snap.detailRows
                                .map(
                                  (row) => ListTile(
                                    dense: true,
                                    title: Text(
                                      '${row.entityType} · ${row.entityId}',
                                      style: tt.bodyMedium,
                                    ),
                                    subtitle: Text(
                                      [
                                        row.action,
                                        'retries ${row.retryCount}',
                                        if (row.error != null &&
                                            row.error!.isNotEmpty)
                                          _truncate(row.error!, 120),
                                      ].join('\n'),
                                      style: tt.bodySmall?.copyWith(
                                        color: cs.onSurfaceVariant,
                                      ),
                                    ),
                                    isThreeLine:
                                        row.error != null &&
                                        row.error!.length > 40,
                                  ),
                                )
                                .toList(),
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const SkeletonSettingsList(rowCount: 5),
          error: (e, _) => Text(l10n.errorGenericLoadFailed),
        ),
      ],
    );
  }
}

String _truncate(String s, int max) {
  if (s.length <= max) return s;
  return '${s.substring(0, max)}…';
}
