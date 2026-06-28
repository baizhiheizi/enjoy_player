/// Discover: channel-filtered RSS video feed.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/window/desktop_window.dart';
import 'package:enjoy_player/core/theme/widgets/editorial_header.dart';
import 'package:enjoy_player/core/theme/widgets/empty_state.dart';
import 'package:enjoy_player/core/theme/widgets/skeleton.dart';
import 'package:enjoy_player/features/discover/application/discover_providers.dart';
import 'package:enjoy_player/features/discover/domain/feed_entry.dart';
import 'package:enjoy_player/features/discover/presentation/discover_channel_filter_strip.dart';
import 'package:enjoy_player/features/discover/presentation/discover_feed_tile.dart';
import 'package:enjoy_player/features/discover/presentation/discover_manage_channels.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final refreshing = ref.watch(discoverRefreshStateProvider);
    final selectedChannelId = ref.watch(discoverSelectedChannelProvider);
    final subscriptionsAsync = ref.watch(discoverSubscriptionsProvider);

    final feedAsync = selectedChannelId == null
        ? ref.watch(discoverTimelineProvider)
        : ref.watch(discoverChannelFeedProvider(selectedChannelId));

    Future<void> onRefresh() async {
      final result = await ref
          .read(discoverRefreshStateProvider.notifier)
          .refresh(force: true);
      if (!context.mounted) return;
      if (result.hasFailures) {
        _showPartialFailure(context, ref, result.failedChannelIds);
      }
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: EditorialHeader(
                title: l10n.discoverTitle,
                trailing: isDesktop
                    ? IconButton(
                        tooltip: l10n.lookupRefresh,
                        onPressed: refreshing
                            ? null
                            : () => unawaited(onRefresh()),
                        icon: refreshing
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: cs.primary,
                                ),
                              )
                            : const Icon(Icons.refresh_rounded),
                      )
                    : null,
              ),
            ),
            if (refreshing)
              const SliverToBoxAdapter(
                child: LinearProgressIndicator(minHeight: 2),
              ),
            const SliverToBoxAdapter(child: DiscoverChannelFilterStrip()),
            subscriptionsAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: SkeletonMediaList(itemCount: 5),
                ),
              ),
              error: (_, _) => SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(t.space24),
                  child: Text(l10n.discoverSubscriptionsLoadFailed),
                ),
              ),
              data: (subs) {
                if (subs.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.rss_feed_rounded,
                      title: l10n.discoverFeedEmptyTitle,
                      subtitle: l10n.discoverNoSubscriptionsHint,
                      action: () =>
                          unawaited(showDiscoverManageChannels(context, ref)),
                      actionLabel: l10n.discoverManageChannels,
                    ),
                  );
                }
                return _DiscoverFeedSliver(
                  feedAsync: feedAsync,
                  onRefresh: onRefresh,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

void _showPartialFailure(
  BuildContext context,
  WidgetRef ref,
  List<String> failedChannelIds,
) {
  final l10n = AppLocalizations.of(context)!;
  final subs = ref.read(discoverSubscriptionsProvider).valueOrNull ?? const [];
  String label(String id) {
    for (final s in subs) {
      if (s.channelId == id) return s.displayName;
    }
    return id;
  }

  final names = failedChannelIds.map(label).toList(growable: false);
  if (names.length == 1) {
    AppNotice.error(context, l10n.discoverRefreshSingleFailed(names.first));
    return;
  }
  AppNotice.error(
    context,
    l10n.discoverRefreshPartialFailedDetail(names.length, names.join(', ')),
  );
}

class _DiscoverFeedSliver extends StatelessWidget {
  const _DiscoverFeedSliver({required this.feedAsync, required this.onRefresh});

  final AsyncValue<List<FeedEntry>> feedAsync;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);

    return feedAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: SkeletonMediaList(itemCount: 5),
        ),
      ),
      error: (_, _) => SliverToBoxAdapter(
        child: EmptyState(
          icon: Icons.cloud_off_rounded,
          title: l10n.discoverFeedErrorTitle,
          subtitle: l10n.discoverFeedErrorHint,
          action: () => unawaited(onRefresh()),
          actionLabel: l10n.discoverRetry,
        ),
      ),
      data: (entries) {
        if (entries.isEmpty) {
          return SliverToBoxAdapter(
            child: EmptyState(
              icon: Icons.rss_feed_rounded,
              title: l10n.discoverFeedEmptyTitle,
              subtitle: l10n.discoverFeedEmptyHint,
              action: () => unawaited(onRefresh()),
              actionLabel: l10n.discoverRetry,
            ),
          );
        }
        return SliverPadding(
          padding: EdgeInsets.fromLTRB(
            t.space24,
            t.space8,
            t.space24,
            t.space32,
          ),
          sliver: SliverLayoutBuilder(
            builder: (context, constraints) {
              const minTileWidth = 320.0;
              final crossAxisCount =
                  (constraints.crossAxisExtent / minTileWidth).floor().clamp(
                    1,
                    4,
                  );

              if (crossAxisCount == 1) {
                return SliverList.separated(
                  itemCount: entries.length,
                  separatorBuilder: (_, _) => SizedBox(height: t.space24),
                  itemBuilder: (context, index) =>
                      DiscoverFeedTile(entry: entries[index]),
                );
              }

              return SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: t.space24,
                  crossAxisSpacing: t.space16,
                  childAspectRatio: discoverFeedTileGridAspectRatio,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Align(
                    alignment: Alignment.topCenter,
                    child: DiscoverFeedTile(entry: entries[index]),
                  ),
                  childCount: entries.length,
                ),
              );
            },
          ),
        );
      },
    );
  }
}
