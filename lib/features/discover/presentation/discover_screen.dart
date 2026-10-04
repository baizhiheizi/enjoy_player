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
                title: l10n.discoverTitle,
                trailing: isDesktop
                    ? (refreshing
                          ? SizedBox(
                              width: 36,
                              height: 36,
                              child: Center(
                                child: LoadingIcon(size: 18, color: cs.primary),
                              ),
                            )
                          : EnjoyIconButton(
                              icon: EnjoyIcons.refresh,
                              tooltip: l10n.lookupRefresh,
                              onPressed: () => unawaited(onRefresh()),
                            ))
                    : null,
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
                  gutter: metrics.gutter,
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
    required this.gutter,
  });

  final AsyncValue<List<DiscoverFeedItem>> feedAsync;
  final Future<void> Function() onRefresh;
  final double gutter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);

    return feedAsync.when(
      loading: () => SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: gutter),
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
        return SliverPadding(
          padding: EdgeInsets.fromLTRB(gutter, t.space8, gutter, t.space32),
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
                  separatorBuilder: (_, _) => SizedBox(height: t.space20),
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

              final tileWidth =
                  (constraints.crossAxisExtent -
                      t.space16 * (crossAxisCount - 1)) /
                  crossAxisCount;

              return SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: t.space20,
                  crossAxisSpacing: t.space16,
                  childAspectRatio: discoverFeedTileGridAspectRatioForWidth(
                    tileWidth,
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
                  findChildIndexCallback: (key) => findSliverIndexByPrefixedId(
                    items: entries,
                    key: key,
                    prefix: 'discover-feed-',
                    idOf: (e) => e.entry.videoId,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
