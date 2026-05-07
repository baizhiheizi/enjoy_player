/// Compact player bar when expanded mode is collapsed.
library;

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

import '../application/player_controller.dart';
import '../application/player_ui_provider.dart';

class MiniPlayerBar extends ConsumerWidget {
  const MiniPlayerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(playerControllerProvider);
    final ui = ref.watch(playerUiProvider);
    if (session == null) return const SizedBox.shrink();

    final player = ref.read(playerControllerProvider.notifier).player;
    final l10n = AppLocalizations.of(context)!;

    if (ui.mode == PlayerChromeMode.expanded) {
      return const SizedBox.shrink();
    }

    final cs = Theme.of(context).colorScheme;
    final t = EnjoyThemeTokens.of(context);

    final inner = InkWell(
      onTap: () => context.push('/player/${session.mediaId}'),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: t.space12, vertical: t.space8),
        child: Row(
          children: [
            Icon(
              session.mediaType == 'video' ? Icons.movie_outlined : Icons.audiotrack,
              size: 28,
              semanticLabel:
                  session.mediaType == 'video'
                      ? l10n.miniPlayerMediaVideo
                      : l10n.miniPlayerMediaAudio,
            ),
            SizedBox(width: t.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    session.mediaTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    l10n.miniPlayerOpen,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            StreamBuilder<bool>(
              stream: player.stream.playing,
              builder: (context, snap) {
                final playing = snap.data ?? false;
                return IconButton(
                  tooltip: playing ? l10n.pause : l10n.play,
                  iconSize: 28,
                  icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                  onPressed: () =>
                      ref.read(playerControllerProvider.notifier).togglePlay(),
                );
              },
            ),
          ],
        ),
      ),
    );

    final surfaceColor = cs.surfaceContainerHigh.withValues(
      alpha: Theme.of(context).brightness == Brightness.dark ? 0.58 : 0.86,
    );

    if (t.miniBarBlurSigma <= 0) {
      return Material(
        elevation: t.elevationBar,
        color: cs.surfaceContainerHigh,
        child: inner,
      );
    }

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: t.miniBarBlurSigma,
          sigmaY: t.miniBarBlurSigma,
        ),
        child: Material(
          elevation: t.elevationBar,
          color: surfaceColor,
          surfaceTintColor: cs.surfaceTint.withValues(alpha: 0.12),
          shadowColor: Colors.black26,
          child: inner,
        ),
      ),
    );
  }
}
