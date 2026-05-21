/// Reactive subtitle lines for the active primary and secondary transcripts.
library;

import 'package:async/async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/app_database.dart';
import '../../../data/db/app_database_provider.dart';
import '../../../data/db/media_target_resolver.dart';
import '../../../data/subtitle/transcript_line.dart';
import '../data/transcript_repository.dart';
import 'transcript_repository_provider.dart';

List<TranscriptLine> _linesForActiveId(
  TranscriptRepository repo,
  List<TranscriptRow> transcriptRows,
  String? activeId,
) {
  if (activeId == null) return <TranscriptLine>[];
  for (final r in transcriptRows) {
    if (r.id == activeId) {
      return repo.linesForRow(r);
    }
  }
  return <TranscriptLine>[];
}

Future<List<TranscriptLine>> _computeLines(
  AppDatabase db,
  TranscriptRepository repo,
  String tt,
  String mediaId, {
  required bool primary,
}) async {
  final echo = await db.echoSessionDao.getLatestForTarget(tt, mediaId);
  final rows = await db.transcriptDao.listForTarget(tt, mediaId);
  final id = primary ? echo?.transcriptId : echo?.secondaryTranscriptId;
  return _linesForActiveId(repo, rows, id);
}

Stream<List<TranscriptLine>> _linesForMedia(
  AppDatabase db,
  TranscriptRepository repo,
  String mediaId, {
  required bool primary,
}) {
  return Stream.fromFuture(dexieTargetTypeForId(db, mediaId)).asyncExpand((tt) {
    if (tt == null) {
      return Stream.value(<TranscriptLine>[]);
    }
    return Stream.fromFuture(
      _computeLines(db, repo, tt, mediaId, primary: primary),
    ).asyncExpand((initial) async* {
      yield initial;
      yield* StreamGroup.merge([
        db.echoSessionDao
            .watchLatestForTarget(tt, mediaId)
            .asyncMap(
              (_) => _computeLines(db, repo, tt, mediaId, primary: primary),
            ),
        db.transcriptDao
            .watchAllForTarget(tt, mediaId)
            .asyncMap(
              (_) => _computeLines(db, repo, tt, mediaId, primary: primary),
            ),
      ]);
    });
  });
}

/// Lines for the primary (shadow-reading) transcript.
final transcriptLinesForMediaProvider =
    StreamProvider.family<List<TranscriptLine>, String>((ref, mediaId) {
      final db = ref.watch(appDatabaseProvider);
      final repo = ref.watch(transcriptRepositoryProvider);
      return _linesForMedia(db, repo, mediaId, primary: true);
    });

/// Lines for the secondary (translation) transcript.
final secondaryTranscriptLinesForMediaProvider =
    StreamProvider.family<List<TranscriptLine>, String>((ref, mediaId) {
      final db = ref.watch(appDatabaseProvider);
      final repo = ref.watch(transcriptRepositoryProvider);
      return _linesForMedia(db, repo, mediaId, primary: false);
    });

/// Whether the media has any transcript row (cheap; no cue JSON decode).
final transcriptHasLinesForMediaProvider = StreamProvider.family<bool, String>((
  ref,
  mediaId,
) {
  if (mediaId.isEmpty) return Stream.value(false);
  final db = ref.watch(appDatabaseProvider);
  return Stream.fromFuture(dexieTargetTypeForId(db, mediaId)).asyncExpand((tt) {
    if (tt == null) return Stream.value(false);
    return db.transcriptDao.watchExistsForTarget(tt, mediaId);
  });
});
