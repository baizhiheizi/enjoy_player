/// Full-width bottom transport: progress, times, artwork, play ring, tools.
library;

import 'dart:async' show Timer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/glass_surface.dart';
import 'package:enjoy_player/core/utils/local_thumbnail.dart';
import 'package:enjoy_player/core/utils/time_format.dart';
import 'package:enjoy_player/features/hotkeys/presentation/hotkey_tooltip_label.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

import '../../../transcript/application/all_transcripts_provider.dart';
import '../../../transcript/presentation/subtitle_track_picker_sheet.dart';
import '../../application/display_position_provider.dart';
import '../../application/echo_mode_provider.dart';
import '../../application/player_controller.dart';
import '../../application/player_interactions.dart';
import '../../application/player_preferences_provider.dart';
import '../../application/player_state_providers.dart';
import '../../application/player_ui_provider.dart';
import '../../domain/playback_session.dart';
final _log = logNamed('GlobalTransportBar');

class GlobalTransportBar extends ConsumerStatefulWidget {
  const GlobalTransportBar({super.key});

  @override
  ConsumerState<GlobalTransportBar> createState() => _GlobalTransportBarState();
}

class _GlobalTransportBarState extends ConsumerState<GlobalTransportBar> {
  bool _sliderHovered = false;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(playerControllerProvider);
    final echo = ref.watch(echoModeProvider);
    final playingAsync = ref.watch(playerIsPlayingProvider);
    final bufferingAsync = ref.watch(playerIsBufferingProvider);
    final isPlaying = playingAsync.value ?? false;
    final isBuffering = bufferingAsync.value ?? false;
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final path = GoRouterState.of(context).uri.path;
    final onPlayer = path.startsWith('/player/');

    final ttPrev = hotkeyTooltipLabel(ref, 'player.prevLine', l10n.previousLine);
    final ttNext = hotkeyTooltipLabel(ref, 'player.nextLine', l10n.nextLine);
    final ttReplay = hotkeyTooltipLabel(ref, 'player.replayLine', l10n.replayLine);
    final ttEcho = hotkeyTooltipLabel(ref, 'player.toggleEchoMode', l10n.echoMode);
    final ttSpeed =
        hotkeyTooltipPair(ref, 'player.slowDown', 'player.speedUp', l10n.speed);
    final ttExpand = hotkeyTooltipLabel(
      ref,
      'player.toggleExpand',
      onPlayer ? l10n.transportCollapse : l10n.transportExpand,
    );
    final ttPlayPause =
        hotkeyTooltipLabel(
          ref,
          'player.togglePlay',
          isPlaying ? l10n.pause : l10n.play,
        );

    if (session == null) return const SizedBox.shrink();

    final durationSec =
        session.durationSeconds > 0 ? session.durationSeconds : 1.0;

    final posAsync = ref.watch(displayPositionProvider);
    final pos = switch (posAsync) {
      AsyncData(:final value) => value,
      _ => Duration.zero,
    };

    final value =
        durationSec > 0 ? pos.inMilliseconds / 1000 / durationSec : 0.0;

    final inner = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(t.space12, t.space8, t.space12, 0),
          child: _TransportProgressStrip(
            session: session,
            position: pos,
            fraction: value.clamp(0, 1),
            hovered: _sliderHovered,
            onHoverChanged: (v) => setState(() => _sliderHovered = v),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(t.space12, t.space4, t.space12, t.space12),
          child: SizedBox(
            height: 56,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!onPlayer) ...[
                          _TransportArtwork(session: session),
                          SizedBox(width: t.space12),
                        ],
                        Flexible(
                          child: Material(
                            color: Colors.transparent,
                            clipBehavior: Clip.antiAlias,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(t.radiusSm),
                            ),
                            child: InkWell(
                              onTap: onPlayer
                                  ? null
                                  : () => context.push('/player/${session.mediaId}'),
                              borderRadius: BorderRadius.circular(t.radiusSm),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: t.space4,
                                  horizontal: t.space4,
                                ),
                                child: _TransportMeta(session: session),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: ttPrev,
                      iconSize: 22,
                      onPressed:
                          isBuffering
                              ? null
                              : () => ref
                                  .read(playerInteractionsProvider.notifier)
                                  .prevLine(),
                      icon: const Icon(Icons.skip_previous_rounded),
                    ),
                    _PlayRingButton(
                      playing: isPlaying,
                      buffering: isBuffering,
                      tooltip: ttPlayPause,
                      onPressed:
                          isBuffering
                              ? null
                              : () => ref
                                  .read(playerControllerProvider.notifier)
                                  .togglePlay(),
                    ),
                    IconButton(
                      tooltip: ttNext,
                      iconSize: 22,
                      onPressed:
                          isBuffering
                              ? null
                              : () => ref
                                  .read(playerInteractionsProvider.notifier)
                                  .nextLine(),
                      icon: const Icon(Icons.skip_next_rounded),
                    ),
                    IconButton(
                      tooltip: ttReplay,
                      iconSize: 22,
                      onPressed:
                          isBuffering
                              ? null
                              : () => ref
                                  .read(playerInteractionsProvider.notifier)
                                  .replayLine(),
                      icon: const Icon(Icons.replay_rounded),
                    ),
                  ],
                ),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: ttEcho,
                            color: echo.active ? t.echoActive : null,
                            style:
                                echo.active
                                    ? IconButton.styleFrom(
                                      backgroundColor: t.echoActive.withValues(alpha: 0.18),
                                    )
                                    : null,
                            onPressed:
                                () => ref
                                    .read(playerInteractionsProvider.notifier)
                                    .toggleEcho(),
                            icon: const Icon(Icons.mic_none_rounded),
                          ),
                          _CcButton(mediaId: session.mediaId),
                          PopupMenuButton<double>(
                            tooltip: ttSpeed,
                            onSelected: (rate) => ref
                                .read(playerPreferencesCtrlProvider.notifier)
                                .setPlaybackRate(rate),
                            itemBuilder:
                                (ctx) => [
                                  for (final r in [0.5, 0.75, 1.0, 1.25, 1.5, 2.0])
                                    PopupMenuItem(value: r, child: Text('${r}x')),
                                ],
                            child: Padding(
                              padding: EdgeInsets.all(t.space8),
                              child: Icon(Icons.speed_rounded, color: cs.onSurfaceVariant),
                            ),
                          ),
                          const _TransportVolumeButton(),
                          IconButton(
                            tooltip: l10n.transportFullscreen,
                            icon: const Icon(Icons.fullscreen_rounded),
                            onPressed: () => _log.fine('fullscreen toggled (stub)'),
                          ),
                          IconButton(
                            tooltip: ttExpand,
                            icon: Icon(
                              onPlayer ? Icons.expand_more_rounded : Icons.open_in_full_rounded,
                            ),
                            onPressed: () {
                              if (onPlayer) {
                                ref.read(playerUiProvider.notifier).collapse();
                                context.pop();
                              } else {
                                context.push('/player/${session.mediaId}');
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    return GlassSurface(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: inner,
      ),
    );
  }
}

class _TransportVolumeButton extends ConsumerStatefulWidget {
  const _TransportVolumeButton();

  @override
  ConsumerState<_TransportVolumeButton> createState() =>
      _TransportVolumeButtonState();
}

class _TransportVolumeButtonState extends ConsumerState<_TransportVolumeButton> {
  static const double _popupW = 44;
  static const double _popupH = 152;
  static const double _gap = 4;

  final OverlayPortalController _portal = OverlayPortalController();
  Timer? _hideTimer;

  void _cancelHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = null;
  }

  void _showPopup() {
    _cancelHideTimer();
    _portal.show();
  }

  void _scheduleHidePopup() {
    _cancelHideTimer();
    _hideTimer = Timer(const Duration(milliseconds: 200), () {
      if (mounted) _portal.hide();
    });
  }

  void _onPointerInside(bool inside) {
    if (inside) {
      _showPopup();
    } else {
      _scheduleHidePopup();
    }
  }

  void _toggleMute() {
    _cancelHideTimer();
    ref.read(playerPreferencesCtrlProvider.notifier).toggleMute();
  }

  /// Returns (left, top) in global coordinates for the popup card.
  (double, double) _popupOffset() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return (0, 0);
    final pos = box.localToGlobal(Offset.zero);
    final btnW = box.size.width;
    return (pos.dx + (btnW - _popupW) / 2, pos.dy - _popupH - _gap);
  }

  @override
  void dispose() {
    _cancelHideTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(playerPreferencesCtrlProvider);
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;

    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: (overlayCtx) {
        final (left, top) = _popupOffset();
        return Positioned(
          left: left,
          top: top,
          width: _popupW,
          height: _popupH,
          child: MouseRegion(
            onEnter: (_) => _onPointerInside(true),
            onExit: (_) => _onPointerInside(false),
            child: Material(
              elevation: 6,
              shadowColor: Colors.black54,
              borderRadius: BorderRadius.circular(t.radiusSm),
              color: cs.surfaceContainerHigh,
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: RotatedBox(
                  quarterTurns: 3,
                  child: SliderTheme(
                    data: SliderTheme.of(overlayCtx).copyWith(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 12,
                      ),
                    ),
                    child: Consumer(
                      builder: (_, ref, _) {
                        final vol = ref
                            .watch(playerPreferencesCtrlProvider)
                            .volume
                            .clamp(0.0, 1.0);
                        return Slider(
                          value: vol,
                          onChanged:
                              (v) => ref
                                  .read(playerPreferencesCtrlProvider.notifier)
                                  .setVolume(v),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      child: MouseRegion(
        onEnter: (_) => _onPointerInside(true),
        onExit: (_) => _onPointerInside(false),
        child: IconButton(
          tooltip:
              prefs.volume <= 0.01 ? l10n.transportUnmute : l10n.transportMute,
          icon: Icon(
            prefs.volume <= 0.01
                ? Icons.volume_off_rounded
                : Icons.volume_up_rounded,
          ),
          onPressed: _toggleMute,
        ),
      ),
    );
  }
}

class _TransportProgressStrip extends ConsumerWidget {
  const _TransportProgressStrip({
    required this.session,
    required this.position,
    required this.fraction,
    required this.hovered,
    required this.onHoverChanged,
  });

  final PlaybackSession session;
  final Duration position;
  final double fraction;
  final bool hovered;
  final ValueChanged<bool> onHoverChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final durationSec =
        session.durationSeconds > 0 ? session.durationSeconds : 1.0;

    final timeStyle = tt.labelSmall?.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
      color: cs.onSurfaceVariant,
    );

    return MouseRegion(
      onEnter: (_) => onHoverChanged(true),
      onExit: (_) => onHoverChanged(false),
      child: Row(
        children: [
          Text(formatDurationHms(position), style: timeStyle),
          const SizedBox(width: 8),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: RoundSliderThumbShape(
                  enabledThumbRadius: hovered ? 6 : 0,
                ),
                overlayShape: SliderComponentShape.noOverlay,
                activeTrackColor: cs.primary,
                inactiveTrackColor: cs.onSurface.withValues(alpha: 0.12),
                thumbColor: cs.primary,
              ),
              child: Slider(
                value: fraction.clamp(0, 1),
                onChanged:
                    (v) => ref
                        .read(playerInteractionsProvider.notifier)
                        .seekToProgressFraction(v),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formatDurationHms(
              Duration(milliseconds: (durationSec * 1000).round()),
            ),
            style: timeStyle,
          ),
        ],
      ),
    );
  }
}

class _TransportMeta extends ConsumerWidget {
  const _TransportMeta({required this.session});

  final PlaybackSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final posAsync = ref.watch(displayPositionProvider);
    final pos = switch (posAsync) {
      AsyncData(:final value) => value,
      _ => Duration.zero,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          session.mediaTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        Text(
          '${formatDurationHms(pos)} / ${formatDurationHms(Duration(milliseconds: (session.durationSeconds * 1000).round()))}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: tt.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _TransportArtwork extends ConsumerWidget {
  const _TransportArtwork({required this.session});

  final PlaybackSession session;

  @override
  Widget build(BuildContext context, WidgetRef _) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final isVideo = session.mediaType == 'video';
    const width = 64.0;
    const height = 40.0;

    // ADR-0003: single media_kit Player/VideoController — do not attach a second
    // [Video] here; the expanded player owns the texture. Mini bar uses art only.
    final thumb = localThumbnailFile(session.thumbnailUrl);
    final Widget content =
        thumb != null
            ? Image.file(
              thumb,
              width: width,
              height: height,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _fallbackArt(cs, isVideo: isVideo),
            )
            : _fallbackArt(cs, isVideo: isVideo);

    return Semantics(
      label: isVideo ? l10n.miniPlayerMediaVideo : l10n.miniPlayerMediaAudio,
      child: SizedBox(
        width: width,
        height: height,
        child: Material(
          color: Colors.transparent,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
          ),
          child: InkWell(
            onTap: () => context.push('/player/${session.mediaId}'),
            child: content,
          ),
        ),
      ),
    );
  }

  Widget _fallbackArt(ColorScheme cs, {required bool isVideo}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.surfaceContainerHighest,
            cs.surfaceContainer,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          isVideo ? Icons.movie_outlined : Icons.audiotrack_rounded,
          size: 22,
          color: cs.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _PlayRingButton extends StatelessWidget {
  const _PlayRingButton({
    required this.playing,
    required this.buffering,
    required this.tooltip,
    required this.onPressed,
  });

  final bool playing;
  final bool buffering;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          clipBehavior: Clip.antiAlias,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: Ink(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: cs.primary, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.28),
                    blurRadius: 14,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Center(
                child:
                    buffering
                        ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.primary,
                          ),
                        )
                        : Icon(
                          playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: cs.onSurface,
                          size: 26,
                        ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


class _CcButton extends ConsumerWidget {
  const _CcButton({required this.mediaId});

  final String mediaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracksAsync = ref.watch(allTranscriptsForMediaProvider(mediaId));
    final hasTrack = (tracksAsync.value ?? []).isNotEmpty;
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: l10n.subtitles,
          icon: const Icon(Icons.closed_caption_outlined),
          onPressed: () => showSubtitleTrackPicker(context, ref, mediaId),
        ),
        if (hasTrack)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: t.ccBadge,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}
