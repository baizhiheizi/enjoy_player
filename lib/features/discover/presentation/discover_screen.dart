/// Discover: channel-filtered RSS video feed.
library;

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/layout/enjoy_page_kind.dart';
import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/presentation/loading_icon.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/typography.dart';
import 'package:enjoy_player/core/theme/widgets/media_card.dart';
import 'package:enjoy_player/core/theme/widgets/editorial_header.dart';
import 'package:enjoy_player/core/theme/widgets/empty_state.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_page.dart';
import 'package:enjoy_player/core/theme/widgets/skeleton.dart';
import 'package:enjoy_player/core/utils/sliver_key_index.dart';
import 'package:enjoy_player/core/window/desktop_window.dart';
import 'package:enjoy_player/features/discover/application/discover_providers.dart';
import 'package:enjoy_player/features/discover/application/discover_feed_join.dart';
import 'package:enjoy_player/features/discover/presentation/discover_channel_filter_strip.dart';
import 'package:enjoy_player/features/discover/presentation/discover_feed_tile.dart';
import 'package:enjoy_player/features/discover/presentation/discover_manage_channels.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final refreshing = ref.watch(discoverRefreshStateProvider);
    final selectedChannelId = ref.watch(discoverSelectedChannelProvider);
    final subscriptionsAsync = ref.watch(discoverSubscriptionsProvider);

    final feedAsync = selectedChannelId == null
        ? ref.watch(discoverFeedItemsProvider)
        : ref.watch(discoverChannelFeedItemsProvider(selectedChannelId));

    Future<void> onRefresh() async {
      final result = await ref
          .read(discoverRefreshStateProvider.notifier)
          .refresh(force: true);
      if (!context.mounted) return;
      if (result.hasFailures) {
        _showPartialFailure(context, ref, result.failedChannelIds);
      }
    }

    return EnjoyPage(
      kind: EnjoyPageKind.browse,
      body: (context, metrics) => RefreshIndicator(
        onRefresh: onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: EditorialHeader(
                widthMode: EditorialHeaderWidthMode.browse,
                overline: l10n.discoverOverline,
                title: l10n.discoverTitle,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (refreshing)
                      SizedBox(
                        width: 36,
                        height: 36,
                        child: Center(
                          child: LoadingIcon(size: 18, color: cs.primary),
                        ),
                      )
                    else
                      EnjoyIconButton(
                        icon: EnjoyIcons.refresh,
                        tooltip: l10n.lookupRefresh,
                        onPressed: () => unawaited(onRefresh()),
                      ),
                    if (isDesktop) ...[
                      const SizedBox(width: 8),
                      EnjoyButton.secondary(
                        onPressed: () =>
                            unawaited(showDiscoverManageChannels(context, ref)),
                        child: Text(l10n.discoverManageChannels),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (refreshing)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: metrics.gutter),
                  child: const LinearProgressIndicator(minHeight: 2),
                ),
              ),
            const SliverToBoxAdapter(child: DiscoverChannelFilterStrip()),
            subscriptionsAsync.when(
              loading: () => SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: metrics.gutter),
                  child: const SkeletonMediaList(itemCount: 5),
                ),
              ),
              error: (_, _) => SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(metrics.gutter),
                  child: Text(l10n.discoverSubscriptionsLoadFailed),
                ),
              ),
              data: (subs) {
                if (subs.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
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
                  inset: metrics.horizontalInset,
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
  const _DiscoverFeedSliver({
    required this.feedAsync,
    required this.onRefresh,
    required this.inset,
  });

  final AsyncValue<List<DiscoverFeedItem>> feedAsync;
  final Future<void> Function() onRefresh;
  final double inset;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);

    return feedAsync.when(
      loading: () => SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: inset),
          child: const SkeletonMediaList(itemCount: 5),
        ),
      ),
      error: (_, _) => SliverToBoxAdapter(
        child: EmptyState(
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
              title: l10n.discoverFeedEmptyTitle,
              subtitle: l10n.discoverFeedEmptyHint,
              action: () => unawaited(onRefresh()),
              actionLabel: l10n.discoverRetry,
            ),
          );
        }
        final newest = entries
            .map((e) => e.entry.publishedAt)
            .reduce((a, b) => a.isAfter(b) ? a : b);

        return SliverMainAxisGroup(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(inset, 22, inset, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        l10n.discoverRecentUploads,
                        style: enjoyDisplayStyle(
                          context,
                          size: 24,
                          color: Theme.of(context).colorScheme.onSurface,
                          height: 1.2,
                        ),
                      ),
                    ),
                    Text(
                      l10n.discoverUpdatedAgo(_shortAge(newest)),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 12.5,
                        color: t.ink3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(inset, 18, inset, t.space32),
              sliver: SliverLayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.crossAxisExtent < 320) {
                    return SliverList.separated(
                      itemCount: entries.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 28),
                      itemBuilder: (context, index) => KeyedSubtree(
                        key: ValueKey<String>(
                          'discover-feed-${entries[index].entry.videoId}',
                        ),
                        child: DiscoverFeedTile(
                          entry: entries[index].entry,
                          inLibrary: entries[index].inLibrary,
                          channelName: entries[index].channelName,
                          channelAvatarUrl: entries[index].channelAvatarUrl,
                        ),
                      ),
                    );
                  }

                  final crossAxisSpacing = 22.0;
                  final crossAxisCount =
                      ((constraints.crossAxisExtent + crossAxisSpacing) /
                              (250 + crossAxisSpacing))
                          .floor()
                          .clamp(1, 6);
                  final tileWidth =
                      (constraints.crossAxisExtent -
                          crossAxisSpacing * (crossAxisCount - 1)) /
                      crossAxisCount;
                  return SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 28,
                      crossAxisSpacing: crossAxisSpacing,
                      childAspectRatio: mediaCardTileGridAspectRatioForWidth(
                        tileWidth,
                        metaHeight: discoverFeedTileMetaHeight,
                      ),
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Align(
                        key: ValueKey<String>(
                          'discover-feed-${entries[index].entry.videoId}',
                        ),
                        alignment: Alignment.topCenter,
                        child: DiscoverFeedTile(
                          entry: entries[index].entry,
                          inLibrary: entries[index].inLibrary,
                          channelName: entries[index].channelName,
                          channelAvatarUrl: entries[index].channelAvatarUrl,
                        ),
                      ),
                      childCount: entries.length,
                      findChildIndexCallback: (key) =>
                          findSliverIndexByPrefixedId(
                            items: entries,
                            key: key,
                            prefix: 'discover-feed-',
                            idOf: (e) => e.entry.videoId,
                          ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

/// `3h ago` / `2d ago` compact feed age, for the Updated caption.
String _shortAge(DateTime at, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final diff = reference.difference(at.toLocal());
  if (diff.inHours < 1) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  return '${diff.inDays}d';
}
