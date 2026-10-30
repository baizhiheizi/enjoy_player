/// User-initiated "Export the loop as a clip…" flow: resolves the active
/// Echo loop range and the open media, encodes the clip with FFmpeg, then
/// hands it over — save dialog on desktop, share sheet on iOS / Android —
/// the same split as the diagnostic report export.
library;

import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/platform/file_share_export.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/data/db/media_registry_provider.dart';
import 'package:enjoy_player/data/db/media_target_resolver.dart';
import 'package:enjoy_player/data/files/ffmpeg_media_probe.dart';
import 'package:enjoy_player/features/library/domain/media.dart';
import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';
import 'package:enjoy_player/features/player/application/loop_clip_export_plan.dart';
import 'package:enjoy_player/features/player/application/loop_clip_export_runner.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/features/transcript/application/transcript_lines_provider.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

final _log = logNamed('LoopClipExportFlow');

/// Runs the export for [mediaId]'s active Echo loop and reports through
/// [AppNotice]. Never throws — every failure is surfaced as a notice.
Future<void> exportLoopAsClip(
  BuildContext context,
  WidgetRef ref,
  String mediaId,
) async {
  final l10n = AppLocalizations.of(context)!;
  try {
    final db = ref.read(appDatabaseProvider);
    final registry = ref.read(mediaRegistryProvider);
    final echo = ref.read(echoModeProvider);
    final lines = ref
        .read(transcriptLinesForMediaProvider(mediaId))
        .valueOrNull;
    final durationSeconds = ref.read(playerControllerProvider)?.durationSeconds;

    final media = await registry.getById(mediaId);
    final sourceUri = await resolvePlayableSourceUri(db, mediaId);
    if (!context.mounted) return;
    if (media == null || sourceUri == null) {
      AppNotice.error(context, l10n.playerMoreExportLoopClipFailed);
      return;
    }

    final window = resolveLoopClipRange(
      echo,
      lines: lines,
      durationSeconds: durationSeconds,
    );
    if (!context.mounted) return;
    if (window == null) {
      AppNotice.error(context, l10n.playerMoreExportLoopClipFailed);
      return;
    }

    final video = media.kind == MediaKind.video;
    final fileName = loopClipFileName(
      title: media.title,
      video: video,
      window: window,
    );

    final tempDir = await getTemporaryDirectory();
    final written = await const LoopClipExportRunner().export(
      LoopClipExportRequest(
        inputPath: FfmpegMediaProbe.mediaInputForFfmpeg(sourceUri),
        outputPath: p.join(tempDir.path, fileName),
        startSeconds: window.start,
        durationSeconds: window.end - window.start,
        video: video,
      ),
    );
    if (!context.mounted) return;

    try {
      final outcome = await saveOrShareFile(
        sourcePath: written,
        fileName: fileName,
        mimeType: video ? 'video/mp4' : 'audio/mp4',
        dialogTitle: l10n.playerMoreExportLoopClip,
      );
      if (!context.mounted) return;
      switch (outcome) {
        case FileShareOutcome.shared:
        case FileShareOutcome.saved:
          AppNotice.success(context, l10n.playerMoreExportLoopClipSuccess);
        case FileShareOutcome.cancelled:
          break;
        case FileShareOutcome.failed:
          AppNotice.error(context, l10n.playerMoreExportLoopClipFailed);
      }
    } finally {
      try {
        await File(written).delete();
      } on Object catch (e) {
        _log.fine('loop clip temp cleanup failed: $e');
      }
    }
  } on LoopClipExportException catch (e, st) {
    _log.warning('loop clip export failed: $e', e, st);
    if (!context.mounted) return;
    AppNotice.error(
      context,
      e.reason == LoopClipExportFailureReason.ffmpegMissing
          ? l10n.playerMoreExportLoopClipFfmpegMissing
          : l10n.playerMoreExportLoopClipFailed,
    );
  } on Object catch (e, st) {
    _log.warning('loop clip export failed', e, st);
    if (!context.mounted) return;
    AppNotice.error(context, l10n.playerMoreExportLoopClipFailed);
  }
}
