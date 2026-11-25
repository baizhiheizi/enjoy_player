/// Single-channel cached feed from Discover subscriptions.
library;

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/layout/enjoy_page_kind.dart';
import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/empty_state.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_page.dart';
import 'package:enjoy_player/core/theme/widgets/media_card.dart';
import 'package:enjoy_player/core/theme/widgets/skeleton.dart';
import 'package:enjoy_player/features/discover/application/discover_providers.dart';
import 'package:enjoy_player/features/discover/presentation/discover_feed_tile.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

const _channelFeedKeyPrefix = 'channel-feed-';

class ChannelFeedScreen extends ConsumerWidget {
  const ChannelFeedScreen({required this.channelId, super.key});

  final String channelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final feedAsync = ref.watch(discoverChannelFeedItemsProvider(channelId));
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
          icon: const Icon(EnjoyIcons.bellOff),
          onPressed: () => unawaited(_unsubscribe(context, ref, l10n)),
        ),
      ],
      body: (context, metrics) => feedAsync.when(
        loading: () => Padding(
          padding: EdgeInsets.all(metrics.gutter),
          child: const SkeletonMediaList(itemCount: 4),
        ),
        error: (_, _) => EmptyState(
          title: l10n.discoverFeedErrorTitle,
          subtitle: l10n.discoverFeedErrorHint,
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return EmptyState(
              title: l10n.discoverFeedEmptyTitle,
              subtitle: l10n.discoverFeedEmptyHint,
            );
          }
          final gutter = metrics.gutter;
          const minTileWidth = 320.0;
          final gridExtent = metrics.paneWidth - gutter * 2;
          final crossAxisCount = (gridExtent / minTileWidth).floor().clamp(
            1,
            4,
          );

          if (crossAxisCount == 1) {
            return ListView.separated(
              padding: EdgeInsets.all(gutter),
              itemCount: entries.length,
              separatorBuilder: (_, _) => SizedBox(height: t.space20),
              itemBuilder: (context, index) => KeyedSubtree(
                key: ValueKey<String>(
                  '$_channelFeedKeyPrefix${entries[index].entry.videoId}',
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
              (gridExtent - t.space16 * (crossAxisCount - 1)) / crossAxisCount;

          return GridView.custom(
            padding: EdgeInsets.all(gutter),
            semanticChildCount: entries.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: t.space20,
              crossAxisSpacing: t.space16,
              childAspectRatio: discoverFeedTileGridAspectRatioForWidth(
                tileWidth,
              ),
            ),
            childrenDelegate: mediaCardKeyedDelegate(
              items: entries,
              keyPrefix: _channelFeedKeyPrefix,
              idOf: (item) => item.entry.videoId,
              tileBuilder: (context, item) => DiscoverFeedTile(
                entry: item.entry,
                inLibrary: item.inLibrary,
                channelName: item.channelName,
                channelAvatarUrl: item.channelAvatarUrl,
              ),
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
