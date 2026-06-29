/// Horizontal channel filter: All, subscribed avatars, Manage entry.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/interaction/horizontal_drag_scroll_behavior.dart';
import 'package:enjoy_player/core/interaction/haptics.dart';
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

  static const chipSize = 36.0;
  static const rowHeight = 48.0;

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
    final t = EnjoyThemeTokens.of(context);
    final selectedId = ref.watch(discoverSelectedChannelProvider);
    final subsAsync = ref.watch(discoverSubscriptionsProvider);

    return subsAsync.when(
      loading: () => const SizedBox(
        height: DiscoverChannelFilterStrip.rowHeight,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (subs) {
        return SizedBox(
          height: DiscoverChannelFilterStrip.rowHeight,
          child: ScrollConfiguration(
            behavior: const HorizontalDragScrollBehavior(),
            child: Scrollbar(
              controller: _scrollController,
              interactive: true,
              notificationPredicate: (n) => n.metrics.axis == Axis.horizontal,
              child: ListView.separated(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                primary: false,
                padding: EdgeInsets.fromLTRB(
                  t.space24,
                  t.space4,
                  t.space24,
                  t.space8,
                ),
                separatorBuilder: (_, _) => SizedBox(width: t.space8),
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
                      tooltip: l10n.discoverManageChannels,
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
  }
}

/// Shared circular chip shell for filter strip items.
class _FilterChipShell extends StatelessWidget {
  const _FilterChipShell({
    required this.selected,
    required this.onTap,
    required this.child,
    this.tooltip,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final chip = Material(
      color: selected
          ? cs.primaryContainer.withValues(alpha: 0.55)
          : cs.surfaceContainerHighest.withValues(alpha: 0.35),
      shape: CircleBorder(
        side: BorderSide(
          color: selected
              ? cs.primary
              : cs.outlineVariant.withValues(alpha: 0.35),
          width: selected ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: DiscoverChannelFilterStrip.chipSize,
          height: DiscoverChannelFilterStrip.chipSize,
          child: Center(child: child),
        ),
      ),
    );

    if (tooltip == null) return chip;
    return Tooltip(message: tooltip, child: chip);
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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Material(
      color: selected
          ? cs.primaryContainer.withValues(alpha: 0.55)
          : cs.surfaceContainerHighest.withValues(alpha: 0.35),
      shape: StadiumBorder(
        side: BorderSide(
          color: selected
              ? cs.primary
              : cs.outlineVariant.withValues(alpha: 0.35),
          width: selected ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: DiscoverChannelFilterStrip.chipSize,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: t.space12),
            child: Center(
              child: Text(
                label,
                style: tt.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: selected ? cs.onPrimaryContainer : cs.onSurface,
                ),
              ),
            ),
          ),
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
    final avatarAsync = ref.watch(
      recommendedChannelAvatarProvider(channel.channelId),
    );
    final avatarUrl = remoteThumbnailForCard(
      avatarAsync.valueOrNull ?? channel.thumbnailUrl,
    );

    return _FilterChipShell(
      selected: selected,
      onTap: onTap,
      tooltip: channel.displayName,
      child: DiscoverChannelAvatar(
        url: avatarUrl,
        displayName: channel.displayName,
        seed: channel.channelId,
        size: DiscoverChannelFilterStrip.chipSize - 4,
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
    final cs = Theme.of(context).colorScheme;

    return _FilterChipShell(
      selected: false,
      onTap: onTap,
      tooltip: tooltip,
      child: Icon(Icons.add_rounded, size: 20, color: cs.onSurfaceVariant),
    );
  }
}
