/// Full-screen player with transcript + controls.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/l10n/app_localizations.dart';
import '../application/embedded_tracks_notifier.dart';
import '../application/player_controller.dart';
import '../application/player_ui_provider.dart';
import '../../transcript/presentation/subtitle_track_picker_sheet.dart';
import '../../transcript/presentation/transcript_panel.dart';
import 'layouts/audio_player_layout.dart';
import 'layouts/video_player_layout.dart';
import 'widgets/player_controls_bar.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref
          .read(playerControllerProvider.notifier)
          .openMedia(widget.mediaId);
      ref.read(playerUiProvider.notifier).expand();
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(playerControllerProvider);
    final l10n = AppLocalizations.of(context)!;

    // Show a one-shot snackbar when embedded tracks are newly found.
    ref.listen(embeddedTracksProvider, (_, event) {
      if (event == null) return;
      if (event.mediaId != widget.mediaId) return;
      ref.read(embeddedTracksProvider.notifier).consume();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.subtitlesDetected),
          action: SnackBarAction(
            label: l10n.subtitlesChoose,
            onPressed:
                () => showSubtitleTrackPicker(context, ref, widget.mediaId),
          ),
        ),
      );
    });

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.loading)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isVideo = session.mediaType == 'video';
    final videoController =
        ref.read(playerControllerProvider.notifier).videoController;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_downward_rounded),
          onPressed: () {
            ref.read(playerUiProvider.notifier).collapse();
            context.pop();
          },
        ),
        title: Text(
          session.mediaTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child:
                isVideo
                    ? VideoPlayerLayout(
                      controller: videoController,
                      transcript: TranscriptPanel(mediaId: widget.mediaId),
                    )
                    : AudioPlayerLayout(
                      transcript: TranscriptPanel(mediaId: widget.mediaId),
                    ),
          ),
          const PlayerControlsBar(),
        ],
      ),
    );
  }
}
