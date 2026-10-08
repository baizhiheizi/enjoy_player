/// Sync queue status, last full sync time, and manual sync actions.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:enjoy_player/core/layout/enjoy_page_kind.dart';
import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/presentation/loading_icon.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/typography.dart';
import 'package:enjoy_player/core/theme/widgets/editorial_header.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_card.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_page.dart';
import 'package:enjoy_player/core/theme/widgets/skeleton.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/presentation/widgets/auth_required_callout.dart';
import 'package:enjoy_player/features/sync/application/sync_controller.dart';
import 'package:enjoy_player/features/sync/application/sync_providers.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/features/sync/data/sync_queue_repository.dart';
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

    return EnjoyPage(
      kind: EnjoyPageKind.hub,
      title: l10n.syncScreenTitle,
      showBack: true,
      body: (context, metrics) => auth.when(
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
            metrics: metrics,
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

class _SignedInBody extends ConsumerStatefulWidget {
  const _SignedInBody({
    required this.metrics,
    required this.busySync,
    required this.busyRetry,
    required this.onSyncNow,
    required this.onRetryFailed,
  });

  final EnjoyPageMetrics metrics;
  final bool busySync;
  final bool busyRetry;
  final VoidCallback onSyncNow;
  final VoidCallback onRetryFailed;

  @override
  ConsumerState<_SignedInBody> createState() => _SignedInBodyState();
}

class _SignedInBodyState extends ConsumerState<_SignedInBody> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    final snapshotAsync = ref.watch(syncQueueSnapshotProvider);
    final lastSyncAsync = ref.watch(syncLastFullSyncAtProvider);

    final timeFmt = DateFormat.Hm();

    Widget lastSyncText(AppLocalizations l10n, String? iso) {
      if (iso == null || iso.isEmpty) {
        return Text(
          l10n.syncScreenLastSyncNever,
          style: enjoyDisplayStyle(context, size: 24, color: t.ink),
        );
      }
      final parsed = DateTime.tryParse(iso)?.toLocal();
      if (parsed == null) {
        return Text(
          iso,
          style: enjoyDisplayStyle(context, size: 24, color: t.ink),
        );
      }
      final now = DateTime.now();
      final sameDay =
          parsed.year == now.year &&
          parsed.month == now.month &&
          parsed.day == now.day;
      return Text(
        sameDay
            ? l10n.syncLastSyncToday(timeFmt.format(parsed))
            : DateFormat.yMMMd().add_jm().format(parsed),
        style: enjoyDisplayStyle(context, size: 24, color: t.ink),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: widget.metrics.padding(top: 8, bottom: 64),
          sliver: SliverMainAxisGroup(
            slivers: [
              SliverToBoxAdapter(
                child: EnjoyCard(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            EnjoyOverline(l10n.syncScreenLastSyncLabel),
                            const SizedBox(height: 8),
                            lastSyncAsync.when(
                              data: (iso) => lastSyncText(l10n, iso),
                              loading: () => const SizedBox(
                                height: 28,
                                width: 28,
                                child: LoadingIcon(size: 18),
                              ),
                              error: (e, _) => Text(
                                l10n.error,
                                style: enjoyDisplayStyle(
                                  context,
                                  size: 24,
                                  color: t.danger,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        snapshotAsync.when(
                          data: (snap) =>
                              _syncStatsAndActions(context, l10n, t, tt, snap),
                          loading: () =>
                              const SkeletonSettingsList(rowCount: 2),
                          error: (e, _) => Text(l10n.errorGenericLoadFailed),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 30)),
              SliverToBoxAdapter(child: EnjoyOverline(l10n.syncQueueDetails)),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              snapshotAsync.when(
                data: (snap) => _queueCard(context, l10n, t, tt, snap),
                loading: () => const SliverToBoxAdapter(
                  child: SkeletonSettingsList(rowCount: 4),
                ),
                error: (e, _) =>
                    const SliverToBoxAdapter(child: SizedBox.shrink()),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _syncStatsAndActions(
    BuildContext context,
    AppLocalizations l10n,
    EnjoyThemeTokens t,
    TextTheme tt,
    SyncQueueSnapshot snap,
  ) {
    Widget stat(String figure, String label) => Container(
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: t.ground,
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            figure,
            style: enjoyDisplayStyle(context, size: 30, color: t.ink),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: tt.bodySmall?.copyWith(fontSize: 13, color: t.ink3),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: stat(
                '${snap.retryablePending}',
                l10n.syncScreenStatRetryable,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: stat(
                '${snap.permanentlyFailed}',
                l10n.syncScreenStatFailed,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            EnjoyButton.brand(
              onPressed: widget.busySync ? null : widget.onSyncNow,
              child: widget.busySync
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: LoadingIcon(size: 16),
                    )
                  : Text(l10n.syncScreenSyncNow),
            ),
            EnjoyButton.secondary(
              onPressed: (widget.busyRetry || snap.permanentlyFailed == 0)
                  ? null
                  : widget.onRetryFailed,
              child: widget.busyRetry
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: LoadingIcon(size: 16),
                    )
                  : Text(l10n.syncScreenRetryFailed),
            ),
          ],
        ),
      ],
    );
  }

  Widget _queueCard(
    BuildContext context,
    AppLocalizations l10n,
    EnjoyThemeTokens t,
    TextTheme tt,
    SyncQueueSnapshot snap,
  ) {
    if (snap.detailRows.isEmpty) {
      return SliverToBoxAdapter(
        child: EnjoyCard(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.syncQueueEmpty,
                style: tt.bodyMedium?.copyWith(color: t.ink3),
              ),
            ),
          ),
        ),
      );
    }
    return SliverToBoxAdapter(
      child: EnjoyCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            for (final (i, row) in snap.detailRows.indexed) ...[
              if (i > 0) Divider(height: 1, thickness: 1, color: t.line),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: ShapeDecoration(
                        color: t.sunk,
                        shape: RoundedSuperellipseBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        _kindBadge(row.entityType),
                        style: enjoyMonoStyle(
                          context,
                          size: 10.5,
                          weight: FontWeight.w600,
                          color: t.ink2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _rowTitle(l10n, row),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tt.titleMedium?.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: t.ink,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _rowMeta(l10n, row),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tt.bodySmall?.copyWith(
                              fontSize: 12.5,
                              color: t.ink3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 24,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      alignment: Alignment.center,
                      decoration: ShapeDecoration(
                        color: _failed(row) ? t.ink : t.sunk,
                        shape: const StadiumBorder(),
                      ),
                      child: Text(
                        _failed(row) ? l10n.syncRowFailed : l10n.syncRowWaiting,
                        style: tt.labelSmall?.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _failed(row) ? t.paper : t.ink2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _failed(SyncQueueRow row) => row.retryCount >= 5;

  String _kindBadge(String entityType) => switch (entityType) {
    'recording' => 'REC',
    'vocabulary_item' => 'VOC',
    'video' => 'VID',
    'audio' => 'AUD',
    _ =>
      entityType.length <= 3
          ? entityType.toUpperCase()
          : entityType.substring(0, 3).toUpperCase(),
  };

  String _rowTitle(AppLocalizations l10n, SyncQueueRow row) {
    final kind = switch (row.entityType) {
      'recording' => l10n.syncEntityRecording,
      'vocabulary_item' => l10n.syncEntityVocabulary,
      'video' => l10n.miniPlayerMediaVideo,
      'audio' => l10n.miniPlayerMediaAudio,
      _ => row.entityType,
    };
    return '$kind · ${row.entityId}';
  }

  String _rowMeta(AppLocalizations l10n, SyncQueueRow row) {
    return [
      row.action,
      l10n.syncRowRetries(row.retryCount),
      if (row.error != null && row.error!.isNotEmpty) _truncate(row.error!, 60),
    ].join(' · ');
  }
}

String _truncate(String s, int max) {
  if (s.length <= max) return s;
  return '${s.substring(0, max)}…';
}
