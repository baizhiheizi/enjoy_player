/// Full-screen player: Duet top bar + video/audio chrome.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/features/player/application/open_media_provider.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/features/player/domain/media_relocate_exception.dart';
import 'package:enjoy_player/features/player/domain/playback_session.dart';
import 'package:enjoy_player/features/player/domain/player_launch_request.dart';
import 'package:enjoy_player/features/player/domain/youtube_playback_unavailable_exception.dart';

import 'expanded_player_widgets.dart';
import 'locate_media_screen.dart';

class ExpandedPlayerScreen extends ConsumerStatefulWidget {
  const ExpandedPlayerScreen({required this.launch, super.key});

  final PlayerLaunchRequest launch;

  String get mediaId => launch.mediaId;

  @override
  ConsumerState<ExpandedPlayerScreen> createState() =>
      _ExpandedPlayerScreenState();
}

class _ExpandedPlayerScreenState extends ConsumerState<ExpandedPlayerScreen> {
  @override
  Widget build(BuildContext context) {
    final open = ref.watch(openMediaLaunchProvider(widget.launch));
    final chrome = ref.watch(playerControllerProvider.select(playbackChromeOf));
    final cs = Theme.of(context).colorScheme;
    final mediaId = widget.mediaId;

    if (chrome != null && chrome.mediaId == mediaId) {
      return ExpandedPlayerChromeBody(mediaId: mediaId, chrome: chrome);
    }

    if (open.hasError) {
      final err = open.error;
      if (err is MediaNeedsRelocateException) {
        return LocateMediaScreen(info: err);
      }
      if (err is YouTubePlaybackUnavailableException) {
        return ExpandedPlayerYoutubeUnavailableBody(
          colorScheme: cs,
          youtubeUrl: err.youtubeUrl,
          reason: err.reason,
        );
      }
      return ExpandedPlayerGenericErrorBody(colorScheme: cs);
    }

    return ExpandedPlayerLoadingBody(colorScheme: cs, mediaId: mediaId);
  }
}
