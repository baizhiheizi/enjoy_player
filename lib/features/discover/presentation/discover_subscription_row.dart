/// Single row in the Discover subscriptions management list.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/interaction/haptics.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/utils/remote_thumbnail_url.dart';
import 'package:enjoy_player/features/discover/application/discover_providers.dart';
import 'package:enjoy_player/features/discover/domain/discover_channel.dart';
import 'package:enjoy_player/features/discover/presentation/discover_channel_avatar.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class DiscoverSubscriptionRow extends ConsumerWidget {
  const DiscoverSubscriptionRow({
    required this.channel,
    required this.onUnsubscribe,
    this.navigateToFeed = true,
    this.embeddedInList = false,
    super.key,
  });

  static const avatarSize = 40.0;

  final DiscoverChannel channel;
  final VoidCallback onUnsubscribe;
  final bool navigateToFeed;
  final bool embeddedInList;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final avatarAsync = ref.watch(
      recommendedChannelAvatarProvider(channel.channelId),
    );
    final avatarUrl = remoteThumbnailForCard(
      avatarAsync.valueOrNull ?? channel.thumbnailUrl,
    );

    final row = Padding(
      padding: EdgeInsets.symmetric(horizontal: t.space16, vertical: t.space12),
      child: Row(
        children: [
          DiscoverChannelAvatar(
            url: avatarUrl,
            displayName: channel.displayName,
            seed: channel.channelId,
            size: DiscoverSubscriptionRow.avatarSize,
          ),
          SizedBox(width: t.space12),
          Expanded(
            child: Text(
              channel.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          SizedBox(width: t.space8),
          TextButton(
            onPressed: () {
              Haptics.selection(context);
              onUnsubscribe();
            },
            style: TextButton.styleFrom(
              foregroundColor: cs.onSurfaceVariant,
              padding: EdgeInsets.symmetric(horizontal: t.space12),
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: tt.labelMedium,
            ),
            child: Text(l10n.discoverUnsubscribeAction),
          ),
        ],
      ),
    );

    if (embeddedInList) {
      return row;
    }

    return Material(
      color: cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(t.radiusLg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: navigateToFeed
            ? () {
                Haptics.selection(context);
                unawaited(context.push('/discover/channel/${channel.channelId}'));
              }
            : null,
        child: row,
      ),
    );
  }
}

/// Stacked subscription rows inside one elevated surface (manage modal).
class DiscoverSubscriptionList extends StatelessWidget {
  const DiscoverSubscriptionList({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(t.radiusLg),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                indent:
                    t.space16 + DiscoverSubscriptionRow.avatarSize + t.space12,
                endIndent: t.space16,
                color: cs.outlineVariant.withValues(alpha: 0.25),
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}
