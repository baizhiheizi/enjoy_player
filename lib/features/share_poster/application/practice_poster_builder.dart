/// Loads local Drift + library data into [PracticePosterData].
library;

import 'package:drift/drift.dart';
import 'package:enjoy_player/core/utils/remote_thumbnail_url.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/media_target_resolver.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/library/data/library_repository.dart';
import 'package:enjoy_player/features/library/domain/media.dart';
import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';
import 'package:enjoy_player/features/share_poster/domain/practice_poster_data.dart';
import 'package:enjoy_player/features/transcript/application/echo_region_bounds.dart';
import 'package:enjoy_player/features/transcript/data/transcript_repository.dart';

Future<List<RecordingRow>> listRecordingsForTarget(
  AppDatabase db, {
  required String targetType,
  required String targetId,
}) {
  return (db.select(db.recordings)
        ..where(
          (t) => t.targetType.equals(targetType) & t.targetId.equals(targetId),
        )
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .get();
}

Future<List<TranscriptLine>> primaryTranscriptLinesForMedia({
  required AppDatabase db,
  required TranscriptRepository transcriptRepo,
  required String targetType,
  required String mediaId,
}) async {
  final echo = await db.echoSessionDao.getLatestForTarget(targetType, mediaId);
  final rows = await db.transcriptDao.listForTarget(targetType, mediaId);
  final activeId = echo?.transcriptId;
  if (activeId == null) return const [];
  for (final r in rows) {
    if (r.id == activeId) {
      return transcriptRepo.linesForRow(r);
    }
  }
  return const [];
}

/// Builds poster data for [mediaId], or `null` when media is missing.
Future<PracticePosterData?> buildPracticePosterData({
  required AppDatabase db,
  required MediaLibraryRepository library,
  required TranscriptRepository transcriptRepo,
  required String mediaId,
  EchoState? echo,
  Uint8List? echoCoverBytes,
}) async {
  final media = await library.getById(mediaId);
  if (media == null) return null;

  final targetType = media.dexieTargetType;
  final recordings = await listRecordingsForTarget(
    db,
    targetType: targetType,
    targetId: mediaId,
  );
  if (recordings.isEmpty) return null;

  final lines = await primaryTranscriptLinesForMedia(
    db: db,
    transcriptRepo: transcriptRepo,
    targetType: targetType,
    mediaId: mediaId,
  );

  final stats = computePracticePosterStats(
    recordings: recordings,
    lines: lines,
  );
  final activeEcho = echo != null
      ? activeEchoForTranscript(echo, lines.length)
      : null;
  final quote = resolvePracticePosterQuote(
    lines: lines,
    recordings: recordings,
    echoStartLineIndex: activeEcho?.startLineIndex,
    echoEndLineIndex: activeEcho?.endLineIndex,
  );

  final netThumb = networkThumbnailForMedia(media);
  final localFile = localThumbnailFileForMedia(media);

  return PracticePosterData(
    title: media.title,
    coverSeed: media.coverSeed,
    isVideo: media.kind == MediaKind.video,
    echoCoverBytes: echoCoverBytes,
    localThumbnailPath: localFile?.path,
    networkThumbnailUrl: netThumb,
    quote: quote,
    takes: stats.takes,
    sentencesPracticed: stats.sentencesPracticed,
    spokenDurationMs: stats.spokenDurationMs,
  );
}

/// Whether [mediaId] resolves and has at least one recording.
Future<bool> mediaHasPracticeRecordings({
  required AppDatabase db,
  required String mediaId,
}) async {
  final tt = await dexieTargetTypeForId(db, mediaId);
  if (tt == null) return false;
  final rows = await listRecordingsForTarget(
    db,
    targetType: tt,
    targetId: mediaId,
  );
  return rows.isNotEmpty;
}
