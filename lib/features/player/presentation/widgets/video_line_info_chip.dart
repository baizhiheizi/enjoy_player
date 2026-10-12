/// On-video chip carrying the `Line n of m · looping` caption, visible only
/// while playback is paused or buffering (the dock counter covers it while
/// playing).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/features/player/domain/playback_session.dart';
import 'package:enjoy_player/features/player/presentation/widgets/video_paused_gate.dart';
import 'package:enjoy_player/features/transcript/application/transcript_lines_provider.dart';
import 'package:enjoy_player/features/transcript/application/transcript_playback_highlight_provider.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class VideoLineInfoChip extends ConsumerWidget {
  const VideoLineInfoChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chrome = ref.watch(playerControllerProvider.select(playbackChromeOf));
    final mediaId = chrome?.mediaId;
    if (mediaId == null) return const SizedBox.shrink();

    final total = ref
        .watch(transcriptLinesForMediaProvider(mediaId))
        .value
        ?.length;
    final cue = ref
        .watch(transcriptPlaybackHighlightProvider(mediaId))
        .cueIndex;
    final caption = total != null && total > 0 && cue >= 0
        ? AppLocalizations.of(context)!.playerLineOfTotal(cue + 1, total)
        : null;
    if (caption == null) return const SizedBox.shrink();

    final looping = ref.watch(echoModeProvider).active
        ? ' ${AppLocalizations.of(context)!.playerDockLooping}'
        : '';

    return VideoPausedGate(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Text(
            '$caption$looping',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(fontSize: 12, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
