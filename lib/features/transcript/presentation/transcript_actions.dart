/// The transcript actions (import, embedded subtitles, AI transcript, word
/// timings, cloud refresh) shared by the player's ⋯ More menu on desktop and
/// the phone Subtitles & display sheet.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/core/routing/route_paths.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/features/asr/presentation/asr_generation_launcher.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import '../application/all_transcripts_provider.dart';
import '../application/transcript_display_readiness_provider.dart';
import '../application/transcript_enrichment_controller.dart';
import '../application/video_row_for_media_provider.dart';
import 'import_subtitle_file.dart';
import 'subtitle_track_picker_sheet_action_handlers.dart';
import 'transcript_embedded_extract.dart';

enum TranscriptActionKind {
  edit,
  importFile,
  embeddedSubtitles,
  aiTranscript,
  wordTimings,
  refreshCloud,
}

class TranscriptAction {
  const TranscriptAction({
    required this.kind,
    required this.icon,
    required this.label,
    required this.run,
  });

  final TranscriptActionKind kind;
  final IconData icon;
  final String label;

  /// Runs the action against a mounted [BuildContext] (dialogs and notices
  /// open from it).
  final Future<void> Function(BuildContext context) run;

  Key get key => ValueKey('transcript-action-${kind.name}');
}

/// The transcript actions available for [mediaId] right now, in menu order.
List<TranscriptAction> watchTranscriptActions(
  WidgetRef ref,
  AppLocalizations l10n,
  String mediaId,
) {
  final isYoutube = ref
      .watch(videoRowForMediaProvider(mediaId))
      .maybeWhen(
        data: (row) => row?.provider == 'youtube',
        orElse: () => false,
      );
  final isVideo =
      ref.watch(playerControllerProvider.select((s) => s?.dexieTargetType)) ==
      'Video';
  final tracks =
      ref.watch(allTranscriptsForMediaProvider(mediaId)).valueOrNull ??
      const [];
  final readiness = ref.watch(
    transcriptDisplayReadinessForMediaProvider(mediaId),
  );
  final enrich = ref.watch(transcriptEnrichmentControllerProvider(mediaId));
  final hasAiTrack = tracks.any((track) => track.source == 'ai');

  return [
    if (tracks.isNotEmpty)
      TranscriptAction(
        kind: TranscriptActionKind.edit,
        icon: EnjoyIcons.edit,
        label: l10n.playerMoreEditTranscript,
        run: (context) => context.push(playerEditTranscriptRoutePath(mediaId)),
      ),
    if (!isYoutube)
      TranscriptAction(
        kind: TranscriptActionKind.importFile,
        icon: EnjoyIcons.fileUpload,
        label: l10n.playerMoreAddSubtitleFile,
        run: (context) => pickAndImportSubtitleFile(context, ref, mediaId),
      ),
    if (isVideo && !isYoutube)
      TranscriptAction(
        kind: TranscriptActionKind.embeddedSubtitles,
        icon: EnjoyIcons.subtitles,
        label: l10n.playerMoreUseEmbeddedSubtitles,
        run: (context) => runEmbeddedSubtitleExtract(
          context: context,
          ref: ref,
          mediaId: mediaId,
        ),
      ),
    if (!isYoutube)
      TranscriptAction(
        kind: TranscriptActionKind.aiTranscript,
        icon: EnjoyIcons.waveform,
        label: hasAiTrack
            ? l10n.playerMoreTranscribeAgain
            : l10n.playerMoreCreateAiTranscript,
        run: (context) => launchAsrGeneration(context, ref, mediaId: mediaId),
      ),
    if (readiness.showEnrich && !enrich.isRunning)
      TranscriptAction(
        kind: TranscriptActionKind.wordTimings,
        icon: EnjoyIcons.magic,
        label: readiness.canTrustWordTimes
            ? l10n.playerMoreAddWordTimings
            : l10n.playerMoreAddIpa,
        run: (_) => ref
            .read(transcriptEnrichmentControllerProvider(mediaId).notifier)
            .run(),
      ),
    TranscriptAction(
      kind: TranscriptActionKind.refreshCloud,
      icon: EnjoyIcons.cloudDownload,
      label: l10n.playerMoreRefreshFromCloud,
      run: (context) => refreshCloudTranscripts(context, ref, mediaId),
    ),
  ];
}
