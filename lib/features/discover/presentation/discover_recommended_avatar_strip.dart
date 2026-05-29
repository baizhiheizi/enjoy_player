/// Horizontal avatar-only row of recommended channels (tap to subscribe).
library;

import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/interaction/haptics.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/utils/remote_thumbnail_url.dart';
import 'package:enjoy_player/features/discover/application/discover_providers.dart';
import 'package:enjoy_player/features/discover/domain/recommended_channel.dart';
import 'package:enjoy_player/features/discover/presentation/discover_actions.dart';
import 'package:enjoy_player/features/discover/presentation/discover_channel_avatar.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class DiscoverRecommendedAvatarStrip extends ConsumerStatefulWidget {
  const DiscoverRecommendedAvatarStrip({
    required this.recommended,
    required this.subscribedChannelIds,
    super.key,
  });

  static const avatarSize = 56.0;
  static const rowHeight = 72.0;

  final List<RecommendedChannel> recommended;
  final Set<String> subscribedChannelIds;

  @override
  ConsumerState<DiscoverRecommendedAvatarStrip> createState() =>
      _DiscoverRecommendedAvatarStripState();
}

class _DiscoverRecommendedAvatarStripState
    extends ConsumerState<DiscoverRecommendedAvatarStrip> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    final available = widget.recommended
        .where((c) => !widget.subscribedChannelIds.contains(c.channelId))
        .toList(growable: false);

    if (available.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: t.space8),
        child: Text(
          l10n.discoverRecommendedAllSubscribed,
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
      );
    }

    return SizedBox(
      height: DiscoverRecommendedAvatarStrip.rowHeight,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
            PointerDeviceKind.stylus,
          },
        ),
        child: Scrollbar(
          controller: _scrollController,
          interactive: true,
          notificationPredicate: (n) => n.metrics.axis == Axis.horizontal,
          child: ListView.separated(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            primary: false,
            itemCount: available.length,
            separatorBuilder: (_, _) => SizedBox(width: t.space12),
            itemBuilder: (context, index) {
              final channel = available[index];
              return _RecommendedAvatarTile(
                channel: channel,
                onTap: () {
                  Haptics.selection(context);
                  unawaited(subscribeRecommendedChannel(context, ref, channel));
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RecommendedAvatarTile extends ConsumerWidget {
  const _RecommendedAvatarTile({required this.channel, required this.onTap});

  final RecommendedChannel channel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final avatarAsync = ref.watch(
      recommendedChannelAvatarProvider(channel.channelId),
    );
    final avatarUrl = remoteThumbnailForCard(
      avatarAsync.valueOrNull ?? channel.thumbnailUrl,
    );

    return Semantics(
      button: true,
      label: channel.name,
      child: Material(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: DiscoverRecommendedAvatarStrip.avatarSize,
            height: DiscoverRecommendedAvatarStrip.avatarSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                DiscoverChannelAvatar(
                  url: avatarUrl,
                  displayName: channel.name,
                  seed: channel.channelId,
                  size: DiscoverRecommendedAvatarStrip.avatarSize - 4,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: cs.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: cs.surfaceContainerHigh,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      size: 14,
                      color: cs.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
