/// Per-line shadow-reading recording counts for transcript UI.
library;

import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/data/db/dexie_target_type_provider.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/sync/application/recordings_for_target_provider.dart';
import 'package:enjoy_player/features/transcript/application/transcript_lines_provider.dart';
import 'package:enjoy_player/features/transcript/domain/transcript_recording_counts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'transcript_line_recording_counts_provider.g.dart';

final _log = logNamed('TranscriptLineRecordingCounts');

/// Combines async transcript/recording inputs into per-line counts.
///
/// Returns `null` while any dependency is still loading.
/// Returns `{}` when loaded but nothing overlaps or when a dependency fails.
Map<int, int>? resolveTranscriptLineRecordingCounts({
  required AsyncValue<List<TranscriptLine>> linesAsync,
  required AsyncValue<String?> targetTypeAsync,
  required AsyncValue<List<RecordingRow>> recordingsAsync,
  required String mediaId,
  List<DictationRow> dictations = const [],
  Logger? log,
}) {
  final logger = log ?? _log;

  if (linesAsync.isLoading) return null;
  if (linesAsync.hasError) {
    logger.warning(
      'Transcript lines unavailable for recording counts ($mediaId)',
      linesAsync.error,
      linesAsync.stackTrace,
    );
    return const {};
  }

  final lines = linesAsync.requireValue;
  if (lines.isEmpty) return const {};

  if (targetTypeAsync.isLoading) return null;
  if (targetTypeAsync.hasError) {
    logger.warning(
      'Target type unavailable for recording counts ($mediaId)',
      targetTypeAsync.error,
      targetTypeAsync.stackTrace,
    );
    return const {};
  }

  final tt = targetTypeAsync.requireValue;
  if (tt == null) return const {};

  if (recordingsAsync.isLoading) return null;
  if (recordingsAsync.hasError) {
    logger.warning(
      'Recordings unavailable for transcript line counts ($mediaId)',
      recordingsAsync.error,
      recordingsAsync.stackTrace,
    );
    return const {};
  }

  return countRecordingsPerLineIndex(
    lines,
    recordingsAsync.requireValue,
    dictations: dictations,
  );
}

/// Map of transcript line index → overlapping recording count for [mediaId].
@riverpod
Map<int, int>? transcriptLineRecordingCounts(Ref ref, String mediaId) {
  if (mediaId.isEmpty) return const {};

  final linesAsync = ref.watch(transcriptLinesForMediaProvider(mediaId));
  final targetTypeAsync = ref.watch(dexieTargetTypeForMediaProvider(mediaId));

  final AsyncValue<List<RecordingRow>> recordingsAsync;
  final List<DictationRow> dictations;
  final tt = targetTypeAsync.value;
  if (tt != null) {
    recordingsAsync = ref.watch(
      recordingsForTargetProvider((targetType: tt, targetId: mediaId)),
    );
    final dictationsAsync = ref.watch(
      _dictationsForTargetProvider((targetType: tt, targetId: mediaId)),
    );
    dictations = dictationsAsync.value ?? const [];
  } else if (targetTypeAsync.isLoading) {
    recordingsAsync = const AsyncLoading();
    dictations = const [];
  } else {
    recordingsAsync = const AsyncData([]);
    dictations = const [];
  }

  return resolveTranscriptLineRecordingCounts(
    linesAsync: linesAsync,
    targetTypeAsync: targetTypeAsync,
    recordingsAsync: recordingsAsync,
    mediaId: mediaId,
    dictations: dictations,
  );
}

final _dictationsForTargetProvider = StreamProvider.autoDispose
    .family<List<DictationRow>, ({String targetType, String targetId})>((
      ref,
      target,
    ) {
      final db = ref.watch(appDatabaseProvider);
      return db.dictationDao.watchByTarget(target.targetType, target.targetId);
    });
