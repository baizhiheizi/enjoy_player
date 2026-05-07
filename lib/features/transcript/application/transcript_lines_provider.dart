/// Reactive subtitle lines for the active primary and secondary transcripts.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/app_database.dart';
import '../../../data/db/app_database_provider.dart';
import '../../../data/subtitle/transcript_line.dart';
import '../data/transcript_repository.dart';
import 'transcript_repository_provider.dart';

Stream<List<TranscriptLine>> _primaryLinesForMedia(
  AppDatabase db,
  TranscriptRepository repo,
  String mediaId,
) {
  return Stream<List<TranscriptLine>>.multi((controller) {
    PlaybackSessionRow? session;
    var transcriptRows = <TranscriptRow>[];

    void emit() {
      final activeId = session?.primaryTranscriptId;
      if (activeId == null) {
        controller.add(<TranscriptLine>[]);
        return;
      }
      TranscriptRow? row;
      for (final r in transcriptRows) {
        if (r.id == activeId) {
          row = r;
          break;
        }
      }
      if (row == null) {
        controller.add(<TranscriptLine>[]);
      } else {
        controller.add(repo.linesForRow(row));
      }
    }

    late final StreamSubscription<PlaybackSessionRow?> subSession;
    late final StreamSubscription<List<TranscriptRow>> subTranscripts;
    subSession = db.sessionDao.watchForMedia(mediaId).listen(
      (s) {
        session = s;
        emit();
      },
      onError: controller.addError,
    );
    subTranscripts = db.transcriptDao.watchForMedia(mediaId).listen(
      (rows) {
        transcriptRows = rows;
        emit();
      },
      onError: controller.addError,
    );

    controller.onCancel = () async {
      await subSession.cancel();
      await subTranscripts.cancel();
    };
  });
}

Stream<List<TranscriptLine>> _secondaryLinesForMedia(
  AppDatabase db,
  TranscriptRepository repo,
  String mediaId,
) {
  return Stream<List<TranscriptLine>>.multi((controller) {
    PlaybackSessionRow? session;
    var transcriptRows = <TranscriptRow>[];

    void emit() {
      final secondaryId = session?.secondaryTranscriptId;
      if (secondaryId == null) {
        controller.add(<TranscriptLine>[]);
        return;
      }
      TranscriptRow? row;
      for (final r in transcriptRows) {
        if (r.id == secondaryId) {
          row = r;
          break;
        }
      }
      if (row == null) {
        controller.add(<TranscriptLine>[]);
      } else {
        controller.add(repo.linesForRow(row));
      }
    }

    late final StreamSubscription<PlaybackSessionRow?> subSession;
    late final StreamSubscription<List<TranscriptRow>> subTranscripts;
    subSession = db.sessionDao.watchForMedia(mediaId).listen(
      (s) {
        session = s;
        emit();
      },
      onError: controller.addError,
    );
    subTranscripts = db.transcriptDao.watchForMedia(mediaId).listen(
      (rows) {
        transcriptRows = rows;
        emit();
      },
      onError: controller.addError,
    );

    controller.onCancel = () async {
      await subSession.cancel();
      await subTranscripts.cancel();
    };
  });
}

/// Lines for the primary (shadow-reading) transcript.
final transcriptLinesForMediaProvider =
    StreamProvider.family<List<TranscriptLine>, String>((ref, mediaId) {
      final db = ref.watch(appDatabaseProvider);
      final repo = ref.watch(transcriptRepositoryProvider);
      return _primaryLinesForMedia(db, repo, mediaId);
    });

/// Lines for the secondary (translation) transcript.
final secondaryTranscriptLinesForMediaProvider =
    StreamProvider.family<List<TranscriptLine>, String>((ref, mediaId) {
      final db = ref.watch(appDatabaseProvider);
      final repo = ref.watch(transcriptRepositoryProvider);
      return _secondaryLinesForMedia(db, repo, mediaId);
    });
