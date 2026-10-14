/// The Download transcript… flow shared by the player's ⋯ More menu and the
/// phone Subtitles & display sheet: pick SRT / VTT, then save or share the
/// active primary transcript.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/data/subtitle/subtitle_filename.dart';
import 'package:enjoy_player/data/subtitle/subtitle_serializer.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

import '../application/transcript_export_io.dart';
import '../application/transcript_lines_provider.dart';
import 'download_transcript_format_dialog.dart';

final _log = logNamed('TranscriptDownload');

/// Resolves the lines of the active primary transcript for a media id.
typedef TranscriptLinesLoad = Future<List<TranscriptLine>> Function();

/// Opens the format dialog against a mounted [BuildContext].
typedef TranscriptFormatPick =
    Future<SubtitleExportFormat?> Function(BuildContext context);

/// Writes the serialized bytes via the platform save / share surface.
typedef TranscriptExportSave =
    Future<TranscriptExportIoOutcome> Function({
      required Uint8List bytes,
      required String fileName,
      required String mimeType,
      required String dialogTitle,
    });

/// Downloads the active primary transcript of [mediaId] as an SRT / VTT file.
///
/// Shows the empty notice when no primary transcript is active, then lets the
/// user pick a format, then hands the bytes to the platform save dialog
/// (desktop) or share sheet (mobile).
Future<void> downloadActiveTranscript(
  BuildContext context,
  WidgetRef ref,
  String mediaId, {
  TranscriptLinesLoad? loadLines,
  TranscriptFormatPick? pickFormat,
  TranscriptExportSave? saveFile,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final resolveLines =
      loadLines ??
      () => ref.read(transcriptLinesForMediaProvider(mediaId).future);
  final lines = await resolveLines();
  if (!context.mounted) return;
  if (lines.isEmpty) {
    AppNotice.error(context, l10n.transcriptDownloadEmpty);
    return;
  }

  final pick = pickFormat ?? showTranscriptExportFormatDialog;
  final format = await pick(context);
  if (format == null || !context.mounted) return;

  final title = ref.read(playerControllerProvider)?.mediaTitle ?? '';
  final fileName = '${transcriptExportBaseName(title)}.${format.fileExtension}';
  final bytes = Uint8List.fromList(utf8.encode(format.serialize(lines)));

  final save = saveFile ?? saveOrShareTranscriptFile;
  final outcome = await save(
    bytes: bytes,
    fileName: fileName,
    mimeType: format.mimeType,
    dialogTitle: l10n.transcriptDownloadDialogTitle,
  );
  if (!context.mounted) return;
  switch (outcome) {
    case TranscriptExportIoOutcome.saved:
    case TranscriptExportIoOutcome.shared:
      AppNotice.success(context, l10n.transcriptDownloadSuccess);
    case TranscriptExportIoOutcome.failed:
      _log.warning('Transcript download failed for $fileName');
      AppNotice.error(context, l10n.transcriptDownloadError);
    case TranscriptExportIoOutcome.cancelled:
      break;
  }
}
