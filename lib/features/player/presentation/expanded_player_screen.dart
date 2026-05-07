/// Full-screen player: transparent AppBar over black + video/transcript.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

import '../application/embedded_tracks_notifier.dart';
import '../application/open_media_provider.dart';
import '../application/player_controller.dart';
import '../application/player_ui_provider.dart';
import '../../transcript/presentation/subtitle_track_picker_sheet.dart';
import '../../transcript/presentation/transcript_panel.dart';
import 'layouts/audio_player_layout.dart';
import 'layouts/video_player_layout.dart';

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
    final l10n = AppLocalizations.of(context)!;

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

    if (open.hasError) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              '${l10n.error}: ${open.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      );
    }

    if (session == null || session.mediaId != widget.mediaId) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isVideo = session.mediaType == 'video';
    final videoController =
        isVideo
            ? ref.read(playerControllerProvider.notifier).videoController
            : null;
    final t = EnjoyThemeTokens.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.72),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: const Icon(Icons.expand_more_rounded, color: Colors.white),
          onPressed: () {
            ref.read(playerUiProvider.notifier).collapse();
            context.pop();
          },
        ),
        title: Text(
          session.mediaTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          SizedBox(width: t.space4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
      ),
      body:
          isVideo
              ? VideoPlayerLayout(
                controller: videoController!,
                transcript: TranscriptPanel(mediaId: widget.mediaId),
              )
              : AudioPlayerLayout(
                transcript: TranscriptPanel(mediaId: widget.mediaId),
              ),
    );
  }
}
