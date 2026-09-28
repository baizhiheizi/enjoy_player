/// Compact YouTube-style recommended channel: circular avatar + action.
library;

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/interaction/haptics.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/utils/remote_thumbnail_url.dart';
import 'package:enjoy_player/features/discover/application/discover_providers.dart';
import 'package:enjoy_player/features/discover/domain/recommended_channel.dart';
import 'package:enjoy_player/features/discover/presentation/discover_channel_avatar.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class DiscoverRecommendedChannelCard extends ConsumerWidget {
  const DiscoverRecommendedChannelCard({
    required this.channel,
    required this.subscribed,
    required this.onSubscribe,
    super.key,
  });

  static const avatarSize = 88.0;
  static const labelHeight = 18.0;
  static const buttonHeight = 32.0;

  /// Vertical space for one card plus scrollbar gutter below the row.
  static double rowHeight(EnjoyThemeTokens t) =>
      avatarSize + t.space8 + labelHeight + t.space8 + buttonHeight + t.space16;

  final RecommendedChannel channel;
  final bool subscribed;
  final VoidCallback onSubscribe;

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

    return SizedBox(
      width: 104,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DiscoverChannelAvatar(
            url: avatarUrl,
            displayName: channel.name,
            seed: channel.channelId,
            size: DiscoverRecommendedChannelCard.avatarSize,
          ),
          SizedBox(height: t.space8),
          SizedBox(
            height: labelHeight,
            child: Text(
              channel.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          SizedBox(height: t.space8),
          SizedBox(
            width: double.infinity,
            height: buttonHeight,
            child: subscribed
                ? DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(t.radiusSm),
                      color: cs.surfaceContainerHighest,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          EnjoyIcons.checkCircle,
                          size: 14,
                          color: cs.onSurfaceVariant,
                        ),
                        SizedBox(width: t.space4),
                        Flexible(
                          child: Text(
                            l10n.discoverSubscribedLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tt.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: EdgeInsets.symmetric(horizontal: t.space8),
                      textStyle: tt.labelSmall,
                      backgroundColor: cs.surfaceContainerHighest,
                    ),
                    onPressed: () {
                      Haptics.selection(context);
                      onSubscribe();
                    },
                    child: Text(l10n.discoverSubscribeAction),
                  ),
          ),
        ],
      ),
    );
  }
}
