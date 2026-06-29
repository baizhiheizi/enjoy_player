/// Scaffold bodies for [ExpandedPlayerScreen] (loading, error, main chrome).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/theme/widgets/app_background.dart';
import 'package:enjoy_player/core/theme/widgets/skeleton.dart';
import 'package:enjoy_player/features/player/application/player_collapse.dart';
import 'package:enjoy_player/features/player/application/player_engine_provider.dart';
import 'package:enjoy_player/features/player/application/player_preferences_provider.dart';
import 'package:enjoy_player/features/player/application/player_state_providers.dart';
import 'package:enjoy_player/features/player/domain/playback_session.dart';
import 'package:enjoy_player/features/player/presentation/layouts/audio_player_layout.dart';
import 'package:enjoy_player/features/player/presentation/layouts/video_player_layout.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

import 'package:enjoy_player/features/player/application/youtube_open_preview_provider.dart';
import 'package:enjoy_player/features/player/presentation/widgets/youtube_loading_video_stage.dart';

import 'package:enjoy_player/features/share_poster/presentation/share_practice_poster_button.dart';
import 'package:enjoy_player/features/transcript/presentation/transcript_panel.dart';

/// Centered loading indicator while [openMediaActionProvider] resolves.
class ExpandedPlayerLoadingBody extends ConsumerWidget {
  const ExpandedPlayerLoadingBody({
    super.key,
    required this.colorScheme,
    required this.mediaId,
  });

  final ColorScheme colorScheme;
  final String mediaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preview = ref.watch(youtubeOpenPreviewProvider(mediaId));
    final isYoutube = preview.maybeWhen(
      data: (p) => p != null,
      orElse: () => false,
    );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (isYoutube)
            Align(
              alignment: Alignment.topCenter,
              child: YoutubeLoadingVideoStage(mediaId: mediaId),
            )
          else
            const Center(child: SkeletonAppBootstrap()),
          const Align(
            alignment: Alignment.topCenter,
            child: _VideoCollapseOnlyOverlay(),
          ),
        ],
      ),
    );
  }
}

/// Non-relocate open failure (generic message; no raw exception text).
class ExpandedPlayerGenericErrorBody extends StatelessWidget {
  const ExpandedPlayerGenericErrorBody({super.key, required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(l10n.playerOpenGenericError, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

/// Main expanded player: AppBar + ambient backdrop + video/audio layout.
class ExpandedPlayerChromeBody extends ConsumerWidget {
  const ExpandedPlayerChromeBody({
    super.key,
    required this.mediaId,
    required this.chrome,
    required this.isPlaying,
    required this.accent,
  });

  final String mediaId;
  final PlaybackChrome chrome;
  final bool isPlaying;
  final Color? accent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isVideo = chrome.mediaType == 'video';
    final isBuffering = ref.watch(playerIsBufferingProvider).value ?? false;
    final showVideoTitleChrome = isVideo && (!isPlaying || isBuffering);
    final engine = ref.read(playerEngineProvider);
    final splitPx = ref.watch(
      playerPreferencesCtrlProvider.select(
        (p) => p.videoTranscriptSplitWidthPx,
      ),
    );

    final mediaBody = isVideo
        ? VideoPlayerLayout(
            engine: engine,
            transcript: TranscriptPanel(mediaId: mediaId),
            initialTranscriptSplitWidthPx: splitPx,
            onTranscriptSplitWidthCommitted: (w) => ref
                .read(playerPreferencesCtrlProvider.notifier)
                .setVideoTranscriptSplitWidthPx(w),
          )
        : AudioPlayerLayout(transcript: TranscriptPanel(mediaId: mediaId));

    return Scaffold(
      backgroundColor: cs.surface,
      extendBodyBehindAppBar: true,
      // Video: never reserve an [AppBar] slot — paused title chrome overlays the
      // body so the video stage geometry does not jump on play/pause.
      appBar: isVideo
          ? null
          : (isPlaying
                ? null
                : AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    scrolledUnderElevation: 0,
                    surfaceTintColor: Colors.transparent,
                    leading: IconButton(
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).backButtonTooltip,
                      icon: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: cs.onSurface,
                        size: 28,
                      ),
                      onPressed: () =>
                          unawaited(collapseExpandedPlayer(ref, context)),
                    ),
                    title: Text(
                      chrome.mediaTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    centerTitle: false,
                  )),
      body: PlayerAmbientBackdrop(
        accentColor: accent,
        intensity: 0.08,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (isVideo)
              Stack(
                fit: StackFit.expand,
                children: [
                  mediaBody,
                  if (showVideoTitleChrome)
                    _VideoTitleChromeOverlay(mediaTitle: chrome.mediaTitle),
                ],
              )
            else
              mediaBody,
            Positioned(
              top: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                left: false,
                child: SharePracticePosterButton(
                  mediaId: mediaId,
                  iconColor: isVideo ? Colors.white : cs.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Collapse control only (loading / minimal chrome).
class _VideoCollapseOnlyOverlay extends ConsumerWidget {
  const _VideoCollapseOnlyOverlay();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      bottom: false,
      left: false,
      right: false,
      child: SizedBox(
        height: kToolbarHeight,
        child: Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Theme.of(context).colorScheme.onSurface,
              size: 28,
            ),
            onPressed: () => unawaited(collapseExpandedPlayer(ref, context)),
          ),
        ),
      ),
    );
  }
}

/// Floating title row over video when paused or buffering (does not affect layout).
class _VideoTitleChromeOverlay extends ConsumerWidget {
  const _VideoTitleChromeOverlay({required this.mediaTitle});

  final String mediaTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.topCenter,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.55),
              Colors.black.withValues(alpha: 0.0),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          left: false,
          right: false,
          child: SizedBox(
            height: kToolbarHeight,
            child: Row(
              children: [
                IconButton(
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () =>
                      unawaited(collapseExpandedPlayer(ref, context)),
                ),
                Expanded(
                  child: Text(
                    mediaTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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
