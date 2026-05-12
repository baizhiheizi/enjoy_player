/// Scaffold bodies for [ExpandedPlayerScreen] (loading, error, main chrome).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/theme/widgets/app_background.dart';
import 'package:enjoy_player/core/theme/widgets/skeleton.dart';
import 'package:enjoy_player/core/window/window_fullscreen_provider.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/features/player/application/player_engine_capabilities_provider.dart';
import 'package:enjoy_player/features/player/application/player_ui_provider.dart';
import 'package:enjoy_player/features/player/application/youtube_auth_provider.dart';
import 'package:enjoy_player/features/player/domain/playback_session.dart';
import 'package:enjoy_player/features/player/presentation/layouts/audio_player_layout.dart';
import 'package:enjoy_player/features/player/presentation/layouts/video_player_layout.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

import 'package:enjoy_player/features/transcript/presentation/transcript_panel.dart';

/// Centered loading indicator while [openMediaActionProvider] resolves.
class ExpandedPlayerLoadingBody extends StatelessWidget {
  const ExpandedPlayerLoadingBody({super.key, required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: const Center(child: SkeletonAppBootstrap()),
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
          child: Text(
            l10n.playerOpenGenericError,
            textAlign: TextAlign.center,
          ),
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
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isVideo = chrome.mediaType == 'video';
    final engine = ref.read(playerControllerProvider.notifier).engine;
    final ytSignedIn = ref.watch(youtubeLoginStateProvider).value ?? false;
    final ytLoginChrome = ref.watch(playerYoutubeLoginChromeSupportedProvider);

    return Scaffold(
      backgroundColor: cs.surface,
      extendBodyBehindAppBar: true,
      appBar: isPlaying
          ? null
          : AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              surfaceTintColor: Colors.transparent,
              flexibleSpace: isVideo
                  ? DecoratedBox(
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
                    )
                  : null,
              leading: IconButton(
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: isVideo ? Colors.white : cs.onSurface,
                  size: 28,
                ),
                onPressed: () async {
                  await ref
                      .read(windowFullscreenProvider.notifier)
                      .setFullscreen(false);
                  ref.read(playerUiProvider.notifier).collapse();
                  if (context.mounted) context.pop();
                },
              ),
              title: Text(
                chrome.mediaTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isVideo ? Colors.white : cs.onSurface,
                ),
              ),
              centerTitle: false,
              actions:
                  isVideo && ytLoginChrome
                      ? [
                          IconButton(
                            tooltip: l10n.youtubeLoginTooltip,
                            icon: Icon(
                              ytSignedIn
                                  ? Icons.person_rounded
                                  : Icons.person_outline_rounded,
                              color: isVideo ? Colors.white : cs.onSurface,
                            ),
                            onPressed: () => context.push('/youtube/login'),
                          ),
                        ]
                      : null,
            ),
      body: PlayerAmbientBackdrop(
        accentColor: accent,
        intensity: 0.08,
        child: isVideo
            ? VideoPlayerLayout(
                engine: engine,
                transcript: TranscriptPanel(mediaId: mediaId),
              )
            : AudioPlayerLayout(
                transcript: TranscriptPanel(mediaId: mediaId),
              ),
      ),
    );
  }
}
