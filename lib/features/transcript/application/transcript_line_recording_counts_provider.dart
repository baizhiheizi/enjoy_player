/// Per-line shadow-reading recording counts for transcript UI.
library;

import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/data/db/dexie_target_type_provider.dart';
import 'package:enjoy_player/features/sync/application/recordings_for_target_provider.dart';
import 'package:enjoy_player/features/transcript/application/transcript_lines_provider.dart';
import 'package:enjoy_player/features/transcript/domain/transcript_recording_counts.dart';

part 'transcript_line_recording_counts_provider.g.dart';

final _log = Logger('TranscriptLineRecordingCounts');

/// Map of transcript line index → overlapping recording count for [mediaId].
///
/// Returns `null` while transcript lines, target type, or recordings are still
/// loading so the UI can hide badges instead of implying zero takes.
/// Returns an empty map when loaded but nothing overlaps, or when recordings
/// fail to load (logged at warning level).
@riverpod
Map<int, int>? transcriptLineRecordingCounts(Ref ref, String mediaId) {
  if (mediaId.isEmpty) return const {};

  final linesAsync = ref.watch(transcriptLinesForMediaProvider(mediaId));
  if (linesAsync.isLoading) return null;
  if (linesAsync.hasError) {
    _log.warning(
      'Transcript lines unavailable for recording counts ($mediaId)',
      linesAsync.error,
      linesAsync.stackTrace,
    );
    return const {};
  }

  final lines = linesAsync.requireValue;
  if (lines.isEmpty) return const {};

  final ttAsync = ref.watch(dexieTargetTypeForMediaProvider(mediaId));
  if (ttAsync.isLoading) return null;
  if (ttAsync.hasError) {
    _log.warning(
      'Target type unavailable for recording counts ($mediaId)',
      ttAsync.error,
      ttAsync.stackTrace,
    );
    return const {};
  }

  final tt = ttAsync.requireValue;
  if (tt == null) return const {};

  final recordingsAsync = ref.watch(
    recordingsForTargetProvider((targetType: tt, targetId: mediaId)),
  );
  if (recordingsAsync.isLoading) return null;
  if (recordingsAsync.hasError) {
    _log.warning(
      'Recordings unavailable for transcript line counts ($mediaId)',
      recordingsAsync.error,
      recordingsAsync.stackTrace,
    );
    return const {};
  }

  return countRecordingsPerLineIndex(lines, recordingsAsync.requireValue);
}
