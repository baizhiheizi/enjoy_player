/// Side-effecting flows owned by the subtitle track picker's action list
/// (refresh, delete).
///
/// Import, extract, and generate have their own modules
/// ([`import_subtitle_file.dart`], `transcript_embedded_extract.dart`,
/// `asr_generation_launcher.dart`) shared with the transcript empty state.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_modal.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import '../application/transcript_fetch_controller.dart';
import '../application/transcript_repository_provider.dart';
import '../domain/transcript_fetch_status.dart';
import '../domain/transcript_track.dart';

/// Re-fetches cloud transcripts for [mediaId], surfacing a success notice
/// unless the fetch controller ended in the error state.
Future<void> refreshCloudTranscripts(
  BuildContext context,
  WidgetRef ref,
  String mediaId,
) async {
  final l10n = AppLocalizations.of(context)!;
  final signedIn = ref.read(authCtrlProvider).valueOrNull is AuthSignedIn;
  await ref
      .read(transcriptFetchCtrlProvider(mediaId).notifier)
      .refreshFromCloud(signedIn: signedIn);
  if (context.mounted) {
    final status = ref.read(transcriptFetchStatusProvider(mediaId));
    if (status.status != TranscriptFetchStatus.error) {
      AppNotice.success(context, l10n.subtitlesRefreshDone);
    }
  }
}

/// Confirms, then deletes [track] from the repository.
Future<void> confirmAndDeleteTranscriptTrack(
  BuildContext context,
  WidgetRef ref,
  TranscriptTrack track,
) async {
  final l10n = AppLocalizations.of(context)!;
  final confirmed = await showEnjoyConfirmDialog(
    context: context,
    title: l10n.subtitlesDeleteTrack,
    message: track.label.isEmpty ? track.id : track.label,
    confirmLabel: MaterialLocalizations.of(context).deleteButtonTooltip,
    destructive: true,
  );
  if (confirmed != true) return;
  await ref.read(transcriptRepositoryProvider).deleteTranscript(track.id);
}
