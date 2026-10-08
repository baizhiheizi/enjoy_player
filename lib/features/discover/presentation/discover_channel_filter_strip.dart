/// Horizontal channel filter: All, subscribed avatars, Manage entry.
library;

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';
import 'package:enjoy_player/core/interaction/horizontal_drag_scroll_behavior.dart';
import 'package:enjoy_player/core/interaction/haptics.dart';
import 'package:enjoy_player/core/layout/enjoy_page_kind.dart';
import 'package:enjoy_player/core/presentation/loading_icon.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/utils/remote_thumbnail_url.dart';
import 'package:enjoy_player/features/discover/application/discover_providers.dart';
import 'package:enjoy_player/features/discover/domain/discover_channel.dart';
import 'package:enjoy_player/features/discover/presentation/discover_channel_avatar.dart';
import 'package:enjoy_player/features/discover/presentation/discover_manage_channels.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class DiscoverChannelFilterStrip extends ConsumerStatefulWidget {
  const DiscoverChannelFilterStrip({super.key});

  static const avatarSize = 60.0;
  static const rowHeight = 96.0;

  @override
  ConsumerState<DiscoverChannelFilterStrip> createState() =>
      _DiscoverChannelFilterStripState();
}

class _DiscoverChannelFilterStripState
    extends ConsumerState<DiscoverChannelFilterStrip> {
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
    final selectedId = ref.watch(discoverSelectedChannelProvider);
    final subsAsync = ref.watch(discoverSubscriptionsProvider);

    return subsAsync.when(
      loading: () => const SizedBox(
        height: DiscoverChannelFilterStrip.rowHeight,
        child: Center(child: LoadingIcon(size: 18)),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (subs) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final gutter = pageGutterOf(context, constraints.maxWidth);
            return SizedBox(
              height: DiscoverChannelFilterStrip.rowHeight,
              child: ScrollConfiguration(
                behavior: const HorizontalDragScrollBehavior(),
                child: Scrollbar(
                  controller: _scrollController,
                  interactive: true,
                  notificationPredicate: (n) =>
                      n.metrics.axis == Axis.horizontal,
                  child: ListView.separated(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    primary: false,
                    padding: EdgeInsets.fromLTRB(gutter, 4, gutter, 6),
                    separatorBuilder: (_, _) => const SizedBox(width: 18),
                    itemCount: 2 + subs.length,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _AllFilterChip(
                          label: l10n.discoverFilterAll,
                          selected: selectedId == null,
                          onTap: () {
                            Haptics.selection(context);
                            ref
                                .read(discoverSelectedChannelProvider.notifier)
                                .select(null);
                          },
                        );
                      }
                      if (index == 1 + subs.length) {
                        return _ManageFilterChip(
                          tooltip: l10n.discoverStripSubscribe,
                          onTap: () {
                            Haptics.selection(context);
                            unawaited(showDiscoverManageChannels(context, ref));
                          },
                        );
                      }
                      final channel = subs[index - 1];
                      return _ChannelFilterChip(
                        channel: channel,
                        selected: selectedId == channel.channelId,
                        onTap: () {
                          Haptics.selection(context);
                          ref
                              .read(discoverSelectedChannelProvider.notifier)
                              .select(channel.channelId);
                        },
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// One avatar column in the strip: a 60px circle over its label.
class _StripColumn extends StatelessWidget {
  const _StripColumn({
    required this.label,
    required this.onTap,
    required this.circle,
    this.labelStyle,
  });

  final String label;
  final VoidCallback onTap;
  final Widget circle;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    return EnjoyPressable(
      onTap: onTap,
      haptic: false,
      pressedScale: 0.95,
      borderRadius: BorderRadius.circular(t.radiusControl),
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: DiscoverChannelFilterStrip.avatarSize,
              child: circle,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  labelStyle ??
                  tt.bodySmall?.copyWith(fontSize: 12.5, color: t.ink2),
            ),
          ],
        ),
      ),
    );
  }
}

class _AllFilterChip extends StatelessWidget {
  const _AllFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    return _StripColumn(
      label: label,
      onTap: onTap,
      labelStyle: selected
          ? tt.bodySmall?.copyWith(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: t.ink,
            )
          : null,
      circle: Container(
        width: DiscoverChannelFilterStrip.avatarSize,
        height: DiscoverChannelFilterStrip.avatarSize,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? t.ink : t.sunk,
          shape: BoxShape.circle,
        ),
        child: Text(
          label.characters.first.toUpperCase(),
          style: tt.titleMedium?.copyWith(color: t.paper),
        ),
      ),
    );
  }
}

class _ChannelFilterChip extends ConsumerWidget {
  const _ChannelFilterChip({
    required this.channel,
    required this.selected,
    required this.onTap,
  });

  final DiscoverChannel channel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = EnjoyThemeTokens.of(context);
    final avatarAsync = ref.watch(
      recommendedChannelAvatarProvider(channel.channelId),
    );
    final avatarUrl = remoteThumbnailForCard(
      avatarAsync.valueOrNull ?? channel.thumbnailUrl,
    );
    return _StripColumn(
      label: channel.displayName,
      onTap: onTap,
      circle: Container(
        width: DiscoverChannelFilterStrip.avatarSize,
        height: DiscoverChannelFilterStrip.avatarSize,
        padding: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? t.brandInk : t.line,
        ),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: t.ground, width: 2.5),
          ),
          child: DiscoverChannelAvatar(
            url: avatarUrl,
            displayName: channel.displayName,
            seed: channel.channelId,
            size: DiscoverChannelFilterStrip.avatarSize - 10,
          ),
        ),
      ),
    );
  }
}

class _ManageFilterChip extends StatelessWidget {
  const _ManageFilterChip({required this.tooltip, required this.onTap});

  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    return _StripColumn(
      label: tooltip,
      onTap: onTap,
      circle: Container(
        width: DiscoverChannelFilterStrip.avatarSize,
        height: DiscoverChannelFilterStrip.avatarSize,
        decoration: BoxDecoration(color: t.sunk, shape: BoxShape.circle),
        child: Icon(EnjoyIcons.add, size: 20, color: t.ink2),
      ),
    );
  }
}
