/// Side-effecting flows behind the subtitle track picker's action list
/// (import, extract, generate, refresh, delete).
library;

import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/analytics/analytics_events.dart';
import 'package:enjoy_player/core/analytics/analytics_failure_reason.dart';
import 'package:enjoy_player/core/analytics/analytics_provider.dart';
import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_modal.dart';
import 'package:enjoy_player/features/asr/presentation/asr_generation_launcher.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'import_subtitle_language_dialog.dart';
import 'transcript_embedded_extract.dart';
import '../application/transcript_fetch_controller.dart';
import '../application/transcript_repository_provider.dart';
import '../domain/transcript_fetch_status.dart';
import '../domain/transcript_track.dart';

/// Picks a local `.srt` / `.vtt` file, asks for its language, and imports it
/// as a transcript for [mediaId].
Future<void> pickAndImportSubtitleFile(
  BuildContext context,
  WidgetRef ref,
  String mediaId,
) async {
  final pick = await FilePicker.pickFile(
    type: FileType.custom,
    allowedExtensions: const ['srt', 'vtt'],
  );
  if (pick == null) return;
  final f = pick;
  if (f.path == null) return;

  if (!context.mounted) return;
  final hint = languageHintFromSubtitleFileName(f.name);
  final lang = await showImportSubtitleLanguageDialog(
    context,
    initialLanguage: hint,
  );
  if (lang == null) return;
  final trimmed = lang.trim();
  if (trimmed.isEmpty) return;

  final analytics = ref.read(analyticsProvider);
  final requestedAt = DateTime.now();
  analytics.capture(
    AnalyticsEvents.transcriptGenerationRequested,
    properties: AnalyticsEvents.transcriptRequested(
      source: AnalyticsEvents.sourceLocalFile,
    ),
  );
  try {
    await ref
        .read(transcriptRepositoryProvider)
        .importSubtitle(
          mediaId: mediaId,
          file: XFile(f.path!),
          language: trimmed,
        );
  } on Object catch (e) {
    analytics.capture(
      AnalyticsEvents.transcriptGenerationFailed,
      properties: AnalyticsEvents.transcriptFailed(
        source: AnalyticsEvents.sourceLocalFile,
        reason: analyticsFailureReasonFromObject(e),
      ),
    );
    rethrow;
  }
  analytics.capture(
    AnalyticsEvents.transcriptGenerationCompleted,
    properties: AnalyticsEvents.transcriptCompleted(
      source: AnalyticsEvents.sourceLocalFile,
      durationSeconds: DateTime.now().difference(requestedAt).inSeconds,
    ),
  );
  if (context.mounted) {
    AppNotice.success(
      context,
      AppLocalizations.of(context)!.importSubtitleSuccess,
    );
  }
}

/// Extracts embedded subtitle streams for [mediaId] (see
/// `transcript_embedded_extract.dart`).
Future<void> runExtractEmbeddedSubtitles(
  BuildContext context,
  WidgetRef ref,
  String mediaId,
) {
  return runEmbeddedSubtitleExtract(
    context: context,
    ref: ref,
    mediaId: mediaId,
  );
}

/// Launches ASR transcript generation for [mediaId] (see
/// `asr_generation_launcher.dart`).
Future<void> runGenerateTranscript(
  BuildContext context,
  WidgetRef ref,
  String mediaId,
) {
  return launchAsrGeneration(context, ref, mediaId: mediaId);
}

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
