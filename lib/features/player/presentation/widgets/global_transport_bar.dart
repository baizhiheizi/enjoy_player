/// Full-width bottom transport: progress, times, play controls, artwork/meta, tools.
library;

import 'dart:async' show Timer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/routing/player_navigation.dart';
import 'package:enjoy_player/core/theme/dynamic_color/dynamic_color_provider.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/glass_surface.dart';
import 'package:enjoy_player/core/utils/local_thumbnail.dart';
import 'package:enjoy_player/core/utils/time_format.dart';
import 'package:enjoy_player/core/window/desktop_window.dart';
import 'package:enjoy_player/core/window/window_fullscreen_provider.dart';
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
import '../../domain/playback_session.dart';

const _kPlaybackRatePresets = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

const _playbackRateEpsilon = 0.01;

bool _playbackRatesEqual(double a, double b) =>
    (a - b).abs() < _playbackRateEpsilon;

String _formatPlaybackRateLabel(double rate) {
  final x = (rate * 100).round() / 100;
  final core = x.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  return '${core}x';
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
    // On narrow screens both the collapsed mini-bar and the expanded player
    // use the same compact spaceBetween controls layout.
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

    if (chrome == null) return const SizedBox.shrink();

    final primaryTransport = <Widget>[
      _PlayRingButton(
        playing: isPlaying,
        buffering: isBuffering,
        tooltip: ttPlayPause,
        accentColor: playAccent,
        onPressed:
            isBuffering
                ? null
                : () =>
                    ref.read(playerControllerProvider.notifier).togglePlay(),
      ),
      IconButton(
        tooltip: ttPrev,
        iconSize: 22,
        onPressed:
            isBuffering
                ? null
                : () =>
                    ref.read(playerInteractionsProvider.notifier).prevLine(),
        icon: const Icon(Icons.skip_previous_rounded),
      ),
      IconButton(
        tooltip: ttNext,
        iconSize: 22,
        onPressed:
            isBuffering
                ? null
                : () =>
                    ref.read(playerInteractionsProvider.notifier).nextLine(),
        icon: const Icon(Icons.skip_next_rounded),
      ),
      IconButton(
        tooltip: ttReplay,
        iconSize: 22,
        onPressed:
            isBuffering
                ? null
                : () =>
                    ref.read(playerInteractionsProvider.notifier).replayLine(),
        icon: const Icon(Icons.replay_rounded),
      ),
    ];

    final secondaryTransport = <Widget>[
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
            () => ref.read(playerInteractionsProvider.notifier).toggleEcho(),
        icon: const Icon(Icons.mic_none_rounded),
      ),
      _CcButton(mediaId: chrome.mediaId),
      PopupMenuButton<double>(
        tooltip: ttSpeed,
        onSelected:
            (rate) => ref
                .read(playerPreferencesCtrlProvider.notifier)
                .setPlaybackRate(rate),
        itemBuilder:
            (ctx) => [
              for (final r in _kPlaybackRatePresets)
                CheckedPopupMenuItem<double>(
                  value: r,
                  checked: _playbackRatesEqual(playbackRate, r),
                  child: Text('${r}x'),
                ),
            ],
        child: Padding(
          padding: EdgeInsets.all(t.space8),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Icon(Icons.speed_rounded, color: cs.onSurfaceVariant),
              if (!_playbackRatesEqual(playbackRate, 1.0))
                Positioned(
                  right: -2,
                  bottom: -4,
                  child: Text(
                    _formatPlaybackRateLabel(playbackRate),
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
      const _TransportVolumeButton(),
      _FullscreenButton(isVideo: chrome.mediaType == 'video'),
      if (!onPlayer)
        IconButton(
          tooltip: hotkeyTooltipLabel(
            ref,
            'player.toggleExpand',
            l10n.transportExpand,
          ),
          icon: const Icon(Icons.open_in_full_rounded),
          onPressed: () => openPlayerRoute(context, chrome.mediaId),
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
            child: _TransportProgressStrip(
              chrome: chrome,
              hovered: _sliderHovered,
              onHoverChanged: (v) => setState(() => _sliderHovered = v),
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
              child:
                  hideBottomMediaInfo
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
                                    _TransportArtwork(chrome: chrome),
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
                                        onTap:
                                            onPlayer
                                                ? null
                                                : () => openPlayerRoute(
                                                  context,
                                                  chrome.mediaId,
                                                ),
                                        borderRadius: BorderRadius.circular(
                                          t.radiusSm,
                                        ),
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: t.space4,
                                            horizontal: t.space4,
                                          ),
                                          child: _TransportMeta(
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
        ],
      ),
    );

    return GlassSurface(
      padding: EdgeInsets.zero,
      child: Material(color: Colors.transparent, child: inner),
    );
  }
}

class _TransportVolumeButton extends ConsumerStatefulWidget {
  const _TransportVolumeButton();

  @override
  ConsumerState<_TransportVolumeButton> createState() =>
      _TransportVolumeButtonState();
}

class _TransportVolumeButtonState
    extends ConsumerState<_TransportVolumeButton> {
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
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
    required this.chrome,
    required this.hovered,
    required this.onHoverChanged,
  });

  final PlaybackChrome chrome;
  final bool hovered;
  final ValueChanged<bool> onHoverChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final durationSec =
        chrome.durationSeconds > 0 ? chrome.durationSeconds : 1.0;

    final posAsync = ref.watch(displayPositionProvider);
    final pos = switch (posAsync) {
      AsyncData(:final value) => value,
      _ => Duration.zero,
    };
    final fraction =
        durationSec > 0 ? pos.inMilliseconds / 1000 / durationSec : 0.0;

    final timeStyle = tt.labelSmall?.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
      color: cs.onSurfaceVariant,
    );

    return MouseRegion(
      onEnter: (_) => onHoverChanged(true),
      onExit: (_) => onHoverChanged(false),
      child: Row(
        children: [
          Text(formatDurationHms(pos), style: timeStyle),
          const SizedBox(width: 8),
          Expanded(
            child: ExcludeSemantics(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  thumbShape: RoundSliderThumbShape(
                    enabledThumbRadius: hovered ? 6 : 1,
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
  const _TransportMeta({required this.chrome});

  final PlaybackChrome chrome;

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
          chrome.mediaTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        Text(
          '${formatDurationHms(pos)} / ${formatDurationHms(Duration(milliseconds: (chrome.durationSeconds * 1000).round()))}',
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
  const _TransportArtwork({required this.chrome});

  final PlaybackChrome chrome;

  @override
  Widget build(BuildContext context, WidgetRef _) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final isVideo = chrome.mediaType == 'video';
    const width = 64.0;
    const height = 40.0;

    // ADR-0003: single media_kit Player/VideoController — do not attach a second
    // [Video] here; the expanded player owns the texture. Mini bar uses art only.
    final thumb = localThumbnailFile(chrome.thumbnailUrl);
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
            onTap: () => openPlayerRoute(context, chrome.mediaId),
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
          colors: [cs.surfaceContainerHighest, cs.surfaceContainer],
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
    this.accentColor,
  });

  final bool playing;
  final bool buffering;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ringColor = accentColor ?? cs.primary;

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
                border: Border.all(color: ringColor, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: ringColor.withValues(alpha: 0.28),
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
                            color: ringColor,
                          ),
                        )
                        : Icon(
                          playing
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
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

class _FullscreenButton extends ConsumerWidget {
  const _FullscreenButton({required this.isVideo});

  final bool isVideo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    // Button is only enabled for video on desktop; hidden otherwise.
    if (!isDesktop || !isVideo) return const SizedBox.shrink();

    final isFullscreen = ref.watch(windowFullscreenProvider);
    final tooltip =
        isFullscreen ? l10n.transportExitFullscreen : l10n.transportFullscreen;
    final icon = isFullscreen
        ? const Icon(Icons.fullscreen_exit_rounded)
        : const Icon(Icons.fullscreen_rounded);

    return IconButton(
      tooltip: tooltip,
      icon: icon,
      onPressed: () =>
          ref.read(windowFullscreenProvider.notifier).toggle(),
    );
  }
}
