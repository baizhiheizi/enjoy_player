/// The local-file subtitle import flow shared by the transcript empty state
/// and the subtitle track picker sheet.
library;

import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/analytics/analytics_events.dart';
import 'package:enjoy_player/core/analytics/analytics_failure_reason.dart';
import 'package:enjoy_player/core/analytics/analytics_provider.dart';
import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

import '../application/transcript_repository_provider.dart';
import 'import_subtitle_language_dialog.dart';

/// Subtitle file types offered by the import picker (no leading dot).
const kSubtitleImportExtensions = <String>['srt', 'vtt'];

/// Resolves the chosen subtitle file, or null when the user cancels or the
/// platform reports no readable path.
typedef SubtitleFilePick = Future<({String path, String name})?> Function();

/// Opens the subtitle import picker and returns the chosen file.
Future<({String path, String name})?> pickSubtitleFile() async {
  final pick = await FilePicker.pickFile(
    type: FileType.custom,
    allowedExtensions: kSubtitleImportExtensions,
  );
  if (pick == null) return null;
  final path = pick.path;
  if (path == null) return null;
  return (path: path, name: pick.name);
}

/// Picks a local `.srt` / `.vtt` file, asks for its language, and imports it
/// as a transcript for [mediaId].
///
/// Every import surface reports the transcript-generation funnel
/// (`local_file`), so the empty state and the picker sheet stay attributable
/// to the same source.
Future<void> pickAndImportSubtitleFile(
  BuildContext context,
  WidgetRef ref,
  String mediaId, {
  SubtitleFilePick pickFile = pickSubtitleFile,
}) async {
  final picked = await pickFile();
  if (picked == null) return;
  if (!context.mounted) return;

  final lang = await showImportSubtitleLanguageDialog(
    context,
    initialLanguage: languageHintFromSubtitleFileName(picked.name),
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
          file: XFile(picked.path),
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
