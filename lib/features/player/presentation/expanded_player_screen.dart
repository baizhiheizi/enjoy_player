/// Full-screen player: ambient artwork backdrop + transparent AppBar.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/theme/dynamic_color/dynamic_color_provider.dart';
import 'package:enjoy_player/core/theme/widgets/app_background.dart';
import 'package:enjoy_player/core/window/window_fullscreen_provider.dart';
import 'package:enjoy_player/features/player/domain/media_relocate_exception.dart';
import 'package:enjoy_player/features/player/domain/playback_session.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

import '../application/embedded_tracks_notifier.dart';
import '../application/open_media_provider.dart';
import '../application/player_controller.dart';
import '../application/player_state_providers.dart';
import '../application/player_ui_provider.dart';
import '../../transcript/presentation/subtitle_track_picker_sheet.dart';
import '../../transcript/presentation/transcript_panel.dart';
import 'layouts/audio_player_layout.dart';
import 'layouts/video_player_layout.dart';
import 'locate_media_screen.dart';

class ExpandedPlayerScreen extends ConsumerStatefulWidget {
  const ExpandedPlayerScreen({required this.mediaId, super.key});

  final String mediaId;

  @override
  ConsumerState<ExpandedPlayerScreen> createState() =>
      _ExpandedPlayerScreenState();
}

class _ExpandedPlayerScreenState extends ConsumerState<ExpandedPlayerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(playerUiProvider.notifier).expand();
    });
  }

  @override
  Widget build(BuildContext context) {
    final open = ref.watch(openMediaActionProvider(widget.mediaId));
    final session = ref.watch(playerControllerProvider);
    final isPlaying = ref.watch(playerIsPlayingProvider).value ?? false;
    final paletteAsync = ref.watch(currentArtworkPaletteProvider);
    final accent = paletteAsync.value?.dominant;
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    ref.listen(embeddedTracksProvider, (_, event) {
      if (event == null) return;
      if (event.mediaId != widget.mediaId) return;
      ref.read(embeddedTracksProvider.notifier).consume();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.subtitlesDetected),
          action: SnackBarAction(
            label: l10n.subtitlesChoose,
            onPressed: () => showSubtitleTrackPicker(context, ref, widget.mediaId),
          ),
        ),
      );
    });

    if (session != null && session.mediaId == widget.mediaId) {
      return _playerScaffold(
        context: context,
        ref: ref,
        session: session,
        isPlaying: isPlaying,
        accent: accent,
        l10n: l10n,
        cs: cs,
      );
    }

    if (open.hasError) {
      final err = open.error;
      if (err is MediaNeedsRelocateException) {
        return LocateMediaScreen(info: err);
      }
      return Scaffold(
        backgroundColor: cs.surface,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              '${l10n.error}: $err',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: cs.surface,
      body: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _playerScaffold({
    required BuildContext context,
    required WidgetRef ref,
    required PlaybackSession session,
    required bool isPlaying,
    required Color? accent,
    required AppLocalizations l10n,
    required ColorScheme cs,
  }) {
    final isVideo = session.mediaType == 'video';
    final videoController =
        isVideo ? ref.read(playerControllerProvider.notifier).videoController : null;

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
                  await ref.read(windowFullscreenProvider.notifier).setFullscreen(false);
                  ref.read(playerUiProvider.notifier).collapse();
                  if (context.mounted) context.pop();
                },
              ),
              title: Text(
                session.mediaTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isVideo ? Colors.white : cs.onSurface,
                ),
              ),
              centerTitle: false,
            ),
      body: PlayerAmbientBackdrop(
        accentColor: accent,
        intensity: 0.08,
        child: isVideo
            ? VideoPlayerLayout(
                controller: videoController!,
                transcript: TranscriptPanel(mediaId: widget.mediaId),
              )
            : AudioPlayerLayout(
                transcript: TranscriptPanel(mediaId: widget.mediaId),
              ),
      ),
    );
  }
}
