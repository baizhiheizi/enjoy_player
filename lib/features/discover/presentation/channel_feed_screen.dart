/// Single-channel cached feed from Discover subscriptions.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/layout/enjoy_page_kind.dart';
import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/empty_state.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_page.dart';
import 'package:enjoy_player/core/theme/widgets/skeleton.dart';
import 'package:enjoy_player/core/utils/sliver_key_index.dart';
import 'package:enjoy_player/features/discover/application/discover_providers.dart';
import 'package:enjoy_player/features/discover/presentation/discover_feed_tile.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class ChannelFeedScreen extends ConsumerWidget {
  const ChannelFeedScreen({required this.channelId, super.key});

  final String channelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final feedAsync = ref.watch(discoverChannelFeedProvider(channelId));
    final subscriptionsAsync = ref.watch(discoverSubscriptionsProvider);

    final channelName = subscriptionsAsync.maybeWhen(
      data: (subs) {
        for (final s in subs) {
          if (s.channelId == channelId) return s.displayName;
        }
        return channelId;
      },
      orElse: () => channelId,
    );

    return EnjoyPage(
      kind: EnjoyPageKind.browse,
      title: channelName,
      showBack: true,
      actions: [
        IconButton(
          tooltip: l10n.discoverUnsubscribeAction,
          icon: const Icon(Icons.notifications_off_outlined),
          onPressed: () => unawaited(_unsubscribe(context, ref, l10n)),
        ),
      ],
      body: (context, metrics) => feedAsync.when(
        loading: () => Padding(
          padding: EdgeInsets.all(metrics.gutter),
          child: const SkeletonMediaList(itemCount: 4),
        ),
        error: (_, _) => EmptyState(
          icon: Icons.cloud_off_rounded,
          title: l10n.discoverFeedErrorTitle,
          subtitle: l10n.discoverFeedErrorHint,
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return EmptyState(
              icon: Icons.rss_feed_rounded,
              title: l10n.discoverFeedEmptyTitle,
              subtitle: l10n.discoverFeedEmptyHint,
            );
          }
          final gutter = metrics.gutter;
          const minTileWidth = 320.0;
          final crossAxisCount = (metrics.paneWidth / minTileWidth)
              .floor()
              .clamp(1, 4);

          if (crossAxisCount == 1) {
            return ListView.separated(
              padding: EdgeInsets.all(gutter),
              itemCount: entries.length,
              separatorBuilder: (_, _) => SizedBox(height: t.space20),
              itemBuilder: (context, index) => KeyedSubtree(
                key: ValueKey<String>('channel-feed-${entries[index].videoId}'),
                child: DiscoverFeedTile(entry: entries[index]),
              ),
            );
          }

          return GridView.builder(
            padding: EdgeInsets.all(gutter),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: t.space20,
              crossAxisSpacing: t.space16,
              childAspectRatio: discoverFeedTileGridAspectRatio,
            ),
            itemCount: entries.length,
            itemBuilder: (context, index) => Align(
              key: ValueKey<String>('channel-feed-${entries[index].videoId}'),
              alignment: Alignment.topCenter,
              child: DiscoverFeedTile(entry: entries[index]),
            ),
            findChildIndexCallback: (key) => findSliverIndexByPrefixedId(
              items: entries,
              key: key,
              prefix: 'channel-feed-',
              idOf: (e) => e.videoId,
            ),
          );
        },
      ),
    );
  }

  Future<void> _unsubscribe(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    await ref.read(discoverRepositoryProvider).unsubscribe(channelId);
    if (!context.mounted) return;
    AppNotice.success(context, l10n.discoverUnsubscribed);
    context.pop();
  }
}
