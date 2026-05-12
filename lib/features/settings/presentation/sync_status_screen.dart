/// Sync queue status, last full sync time, and manual sync actions.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/sync/application/pending_rekey_provider.dart';
import 'package:enjoy_player/features/sync/application/sync_controller.dart';
import 'package:enjoy_player/features/sync/application/sync_providers.dart';
import 'package:enjoy_player/core/theme/widgets/skeleton.dart';
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
      appBar: AppBar(
        title: Text(l10n.syncScreenTitle),
      ),
      body: auth.when(
        data: (state) {
          if (state is! AuthSignedIn) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.syncScreenSignedOutBody,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => context.push('/sign-in'),
                    child: Text(l10n.syncScreenGoSignIn),
                  ),
                ],
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
        error: (Object e, StackTrace s) => Center(child: Text('$e')),
      ),
    );
  }

  Future<void> _runSyncNow(BuildContext context, AppLocalizations l10n) async {
    setState(() => _busySync = true);
    try {
      final result =
          await ref.read(syncCtrlProvider.notifier).triggerSync();
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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final snapshotAsync = ref.watch(syncQueueSnapshotProvider);
    final lastSyncAsync = ref.watch(syncLastFullSyncAtProvider);
    final pendingRekeyAsync = ref.watch(pendingRekeyRowCountProvider);

    final dateFmt = DateFormat.yMMMd().add_jm();

    String lastSyncLine(AppLocalizations l10n, String? iso) {
      if (iso == null || iso.isEmpty) return l10n.syncScreenLastSyncNever;
      final parsed = DateTime.tryParse(iso);
      if (parsed == null) return iso;
      return dateFmt.format(parsed.toLocal());
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          l10n.syncScreenLastSyncLabel,
          style: tt.titleSmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        lastSyncAsync.when(
          data: (iso) => Text(
            lastSyncLine(l10n, iso),
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          loading: () => const SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          error: (e, _) => Text('$e', style: tt.bodyMedium),
        ),
        const SizedBox(height: 20),
        Text(
          l10n.syncPendingRekeyLabel,
          style: tt.titleSmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        pendingRekeyAsync.when(
          data: (count) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '$count',
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (count > 0) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.syncPendingRekeyHint,
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ],
          ),
          loading: () => const SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          error: (e, _) => Text('$e'),
        ),
        const SizedBox(height: 24),
        snapshotAsync.when(
          data: (snap) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StatRow(
                  label: l10n.syncScreenStatRetryable,
                  value: '${snap.retryablePending}',
                  emphasized: snap.retryablePending > 0,
                ),
                const SizedBox(height: 12),
                _StatRow(
                  label: l10n.syncScreenStatFailed,
                  value: '${snap.permanentlyFailed}',
                  emphasized: snap.permanentlyFailed > 0,
                ),
                const SizedBox(height: 24),
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
                const SizedBox(height: 12),
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
                const SizedBox(height: 24),
                ExpansionTile(
                  title: Text(l10n.syncQueueDetails),
                  initiallyExpanded: false,
                  children: snap.detailRows.isEmpty
                      ? [
                          Padding(
                            padding: const EdgeInsets.all(16),
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
                              isThreeLine: row.error != null &&
                                  row.error!.length > 40,
                            ),
                          )
                          .toList(),
                ),
              ],
            );
          },
          loading: () => const SkeletonSettingsList(rowCount: 5),
          error: (e, _) => Text('$e'),
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    required this.emphasized,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: tt.bodyLarge?.copyWith(
              color: emphasized ? cs.error : cs.onSurface,
              fontWeight: emphasized ? FontWeight.w600 : null,
            ),
          ),
        ),
        Text(
          value,
          style: tt.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: emphasized ? cs.error : cs.onSurface,
          ),
        ),
      ],
    );
  }
}

String _truncate(String s, int max) {
  if (s.length <= max) return s;
  return '${s.substring(0, max)}…';
}
