/// Full-width bottom transport: progress, times, play controls, artwork/meta, tools.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/interaction/haptics.dart';
import 'package:enjoy_player/core/routing/player_navigation.dart';
import 'package:enjoy_player/core/theme/dynamic_color/dynamic_color_provider.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/glass_surface.dart';
import 'package:enjoy_player/features/hotkeys/presentation/hotkey_tooltip_label.dart';
import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/features/player/application/player_interactions.dart';
import 'package:enjoy_player/features/player/application/player_preferences_provider.dart';
import 'package:enjoy_player/features/player/application/player_state_providers.dart';
import 'package:enjoy_player/features/player/domain/playback_session.dart';
import 'package:enjoy_player/features/transcript/application/transcript_lines_provider.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

import 'transport/transport_artwork_tile.dart';
import 'transport/transport_cc_fullscreen.dart';
import 'transport/transport_meta_row.dart';
import 'transport/transport_play_ring_button.dart';
import 'transport/transport_playback_rate.dart';
import 'transport/transport_progress_strip.dart';
import 'transport/transport_volume_button.dart';

String _formatRateCore(double rate) {
  final x = (rate * 100).round() / 100;
  return x.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
}

class GlobalTransportBar extends ConsumerStatefulWidget {
  const GlobalTransportBar({super.key});

  @override
  ConsumerState<GlobalTransportBar> createState() => _GlobalTransportBarState();
}

class _GlobalTransportBarState extends ConsumerState<GlobalTransportBar> {
  bool _sliderHovered = false;

  @override
  Widget build(BuildContext context) {
    final chrome = ref.watch(playerControllerProvider.select(playbackChromeOf));
    final mediaId = ref.watch(
      playerControllerProvider.select((s) => s?.mediaId),
    );
    final hasTranscriptLinesAsync = ref.watch(
      transcriptHasLinesForMediaProvider(mediaId ?? ''),
    );
    final hasTranscriptLines = hasTranscriptLinesAsync.maybeWhen(
      data: (v) => v,
      orElse: () => false,
    );
    final echo = ref.watch(echoModeProvider);
    final playingAsync = ref.watch(playerIsPlayingProvider);
    final bufferingAsync = ref.watch(playerIsBufferingProvider);
    final isPlaying = playingAsync.value ?? false;
    final isBuffering = bufferingAsync.value ?? false;
    final paletteAsync = ref.watch(currentArtworkPaletteProvider);
    final dynamicAccent = paletteAsync.value?.accent;
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final playbackRate = ref.watch(playerPreferencesCtrlProvider).playbackRate;
    final playAccent = dynamicAccent ?? cs.primary;
    final path = GoRouterState.of(context).uri.path;
    final onPlayer = path.startsWith('/player/');
    final narrowLayout =
        MediaQuery.sizeOf(context).width <= t.breakpointTranscriptSideBySide;
    final hideBottomMediaInfo = narrowLayout;

    final ttPrev = hotkeyTooltipLabel(
      ref,
      'player.prevLine',
      l10n.previousLine,
    );
    final ttNext = hotkeyTooltipLabel(ref, 'player.nextLine', l10n.nextLine);
    final ttReplay = hotkeyTooltipLabel(
      ref,
      'player.replayLine',
      l10n.replayLine,
    );
    final ttEcho = hotkeyTooltipLabel(
      ref,
      'player.toggleEchoMode',
      l10n.echoMode,
    );
    final ttSpeed = hotkeyTooltipPair(
      ref,
      'player.slowDown',
      'player.speedUp',
      l10n.speed,
    );
    final ttPlayPause = hotkeyTooltipLabel(
      ref,
      'player.togglePlay',
      isPlaying ? l10n.pause : l10n.play,
    );

    final ttExpand = hotkeyTooltipLabel(
      ref,
      'player.toggleExpand',
      l10n.transportExpand,
    );

    if (chrome == null) return const SizedBox.shrink();

    final primaryTransport = <Widget>[
      TransportPlayRingButton(
        playing: isPlaying,
        buffering: isBuffering,
        tooltip: ttPlayPause,
        accentColor: playAccent,
        onPressed: isBuffering
            ? null
            : Haptics.wrapTap(
                context,
                () => ref.read(playerControllerProvider.notifier).togglePlay(),
              ),
      ),
      IconButton(
        tooltip: ttPrev,
        iconSize: 22,
        onPressed: isBuffering || !hasTranscriptLines
            ? null
            : Haptics.wrapTap(
                context,
                () => ref.read(playerInteractionsProvider.notifier).prevLine(),
              ),
        icon: const Icon(Icons.skip_previous_rounded),
      ),
      IconButton(
        tooltip: ttNext,
        iconSize: 22,
        onPressed: isBuffering || !hasTranscriptLines
            ? null
            : Haptics.wrapTap(
                context,
                () => ref.read(playerInteractionsProvider.notifier).nextLine(),
              ),
        icon: const Icon(Icons.skip_next_rounded),
      ),
      IconButton(
        tooltip: ttReplay,
        iconSize: 22,
        onPressed: isBuffering || !hasTranscriptLines
            ? null
            : Haptics.wrapTap(
                context,
                () =>
                    ref.read(playerInteractionsProvider.notifier).replayLine(),
              ),
        icon: const Icon(Icons.replay_rounded),
      ),
    ];

    final secondaryTransport = <Widget>[
      IconButton(
        tooltip: ttEcho,
        color: echo.active ? t.echoActive : null,
        style: echo.active
            ? IconButton.styleFrom(
                backgroundColor: t.echoActive.withValues(alpha: 0.18),
              )
            : null,
        onPressed: echo.active || hasTranscriptLines
            ? Haptics.wrapTap(
                context,
                () =>
                    ref.read(playerInteractionsProvider.notifier).toggleEcho(),
              )
            : null,
        icon: const Icon(Icons.mic_none_rounded),
      ),
      TransportCcButton(mediaId: chrome.mediaId),
      PopupMenuButton<double>(
        tooltip: ttSpeed,
        onSelected: (rate) => ref
            .read(playerPreferencesCtrlProvider.notifier)
            .setPlaybackRate(rate),
        itemBuilder: (ctx) => [
          for (final r in kPlaybackRatePresets)
            CheckedPopupMenuItem<double>(
              value: r,
              checked: playbackRatesEqual(playbackRate, r),
              child: Text(
                AppLocalizations.of(ctx)!.playbackRateTimes(_formatRateCore(r)),
              ),
            ),
        ],
        child: Padding(
          padding: EdgeInsets.all(t.space8),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Icon(Icons.speed_rounded, color: cs.onSurfaceVariant),
              if (!playbackRatesEqual(playbackRate, 1.0))
                Positioned(
                  right: -2,
                  bottom: -4,
                  child: Text(
                    AppLocalizations.of(
                      context,
                    )!.playbackRateTimes(_formatRateCore(playbackRate)),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 9,
                      height: 1,
                      fontWeight: FontWeight.w600,
                      color: cs.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      const TransportVolumeButton(),
      TransportFullscreenButton(isVideo: chrome.mediaType == 'video'),
      if (!onPlayer)
        IconButton(
          tooltip: ttExpand,
          icon: const Icon(Icons.open_in_full_rounded),
          onPressed: Haptics.wrapTap(
            context,
            () => openPlayerRoute(context, chrome.mediaId),
          ),
        ),
    ];

    final inner = Theme(
      data: Theme.of(context).copyWith(
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(visualDensity: VisualDensity.compact),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(t.space12, t.space8, t.space12, 0),
            child: RepaintBoundary(
              child: TransportProgressStrip(
                chrome: chrome,
                hovered: _sliderHovered,
                onHoverChanged: (v) => setState(() => _sliderHovered = v),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              t.space12,
              t.space4,
              t.space12,
              t.space12,
            ),
            child: SizedBox(
              height: 56,
              child: AnimatedSwitcher(
                duration: MediaQuery.of(context).disableAnimations
                    ? Duration.zero
                    : t.motionMedium,
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeOutCubic,
                transitionBuilder: (child, anim) {
                  return FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position:
                          Tween<Offset>(
                            begin: const Offset(0, 0.03),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: anim,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                      child: child,
                    ),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey<bool>(hideBottomMediaInfo),
                  child: hideBottomMediaInfo
                      ? LayoutBuilder(
                          builder: (context, paddedConstraints) {
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minWidth: paddedConstraints.maxWidth,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: primaryTransport,
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: secondaryTransport,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: primaryTransport,
                            ),
                            SizedBox(width: t.space12),
                            Expanded(
                              flex: 2,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  children: [
                                    if (!onPlayer) ...[
                                      TransportArtworkTile(chrome: chrome),
                                      SizedBox(width: t.space12),
                                    ],
                                    Flexible(
                                      child: Material(
                                        color: Colors.transparent,
                                        clipBehavior: Clip.antiAlias,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            t.radiusSm,
                                          ),
                                        ),
                                        child: InkWell(
                                          onTap: onPlayer
                                              ? null
                                              : Haptics.wrapTap(
                                                  context,
                                                  () => openPlayerRoute(
                                                    context,
                                                    chrome.mediaId,
                                                  ),
                                                ),
                                          borderRadius: BorderRadius.circular(
                                            t.radiusSm,
                                          ),
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                              vertical: t.space4,
                                              horizontal: t.space4,
                                            ),
                                            child: TransportMetaRow(
                                              chrome: chrome,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: secondaryTransport,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return GlassSurface(
      padding: EdgeInsets.zero,
      child: Material(color: Colors.transparent, child: inner),
    );
  }
}
