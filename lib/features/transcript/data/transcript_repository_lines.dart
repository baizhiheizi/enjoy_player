part of 'transcript_repository.dart';

/// Decoded-timeline cache and reactive watches for [TranscriptRepository]:
/// memoized `timelineJson` decoding via the timeline codec (with isolate
/// pre-decode for large payloads), Drift watch glue for the active primary /
/// secondary lines, and the sorted track list stream.
extension _TranscriptRepositoryLines on TranscriptRepository {
  List<TranscriptLine> _linesForRow(TranscriptRow row) =>
      _overlayPendingAutoTranslateLines(
        row.id,
        _linesCache.linesFor(
          rowId: row.id,
          revision: _revisionOf(row),
          timelineJson: row.timelineJson,
        ),
      );

  /// Pre-decodes [row.timelineJson] in a background isolate and caches the
  /// result when the payload is large enough
  /// ([kPreloadTimelineJsonBytes]) to justify leaving the UI isolate.
  Future<void> _preloadLinesForRow(TranscriptRow row) async {
    if (_linesCache.isCached(rowId: row.id, revision: _revisionOf(row))) {
      return;
    }
    if (row.timelineJson.length <= kPreloadTimelineJsonBytes) return;
    final decoded = await compute(decodeTimelineJson, row.timelineJson);
    _linesCache.store(
      rowId: row.id,
      revision: _revisionOf(row),
      lines: decoded,
    );
  }

  List<TranscriptLine> _cachedLinesFor({
    required String rowId,
    required TranscriptTimelineRevision revision,
  }) => _overlayPendingAutoTranslateLines(
    rowId,
    _linesCache.linesFor(rowId: rowId, revision: revision),
  );

  /// Metadata plus decoded lines for [transcriptId], reading `timeline_json`
  /// only when the revision-keyed memo misses.
  Future<TranscriptContent?> _contentById(String transcriptId) async {
    final meta = await _db.transcriptDao.metaById(transcriptId);
    if (meta == null) return null;
    final List<TranscriptLine> lines;
    if (_linesCache.isCached(rowId: transcriptId, revision: meta.revision)) {
      lines = _cachedLinesFor(rowId: transcriptId, revision: meta.revision);
    } else {
      final row = await transcriptRowById(transcriptId);
      if (row == null) return null;
      await _preloadLinesForRow(row);
      lines = _linesForRow(row);
    }
    return TranscriptContent(
      id: meta.id,
      language: meta.language,
      source: meta.source,
      referenceId: meta.referenceId,
      updatedAt: meta.revision.updatedAt,
      lines: lines,
    );
  }

  Stream<List<TranscriptLine>> _watchLines(
    String mediaId, {
    required bool primary,
  }) {
    return Stream.fromFuture(dexieTargetTypeForId(_db, mediaId)).asyncExpand((
      tt,
    ) {
      if (tt == null) return Stream.value(const <TranscriptLine>[]);
      final activeIds = _db.echoSessionDao
          .watchActiveTranscriptIds(tt, mediaId)
          .map(
            (row) => primary ? row?.transcriptId : row?.secondaryTranscriptId,
          )
          .distinct();
      return Stream<List<TranscriptLine>>.multi((controller) {
        StreamSubscription<List<TranscriptLine>>? revisionSub;
        var generation = 0;

        Future<void> attach(String? transcriptId) async {
          final current = ++generation;
          final previous = revisionSub;
          revisionSub = null;
          await previous?.cancel();
          if (current != generation || controller.isClosed) return;
          if (transcriptId == null) {
            controller.add(const <TranscriptLine>[]);
            return;
          }
          revisionSub = _watchLinesForId(
            transcriptId,
          ).listen(controller.add, onError: controller.addError);
        }

        final idsSub = activeIds.listen(
          (transcriptId) => unawaited(attach(transcriptId)),
          onError: controller.addError,
        );
        controller.onCancel = () {
          generation++;
          unawaited(idsSub.cancel());
          unawaited(revisionSub?.cancel());
        };
      }, isBroadcast: true);
    });
  }

  Stream<List<TranscriptLine>> _watchLinesForId(String transcriptId) {
    return _db.transcriptDao
        .watchRevisionById(transcriptId)
        .distinctBy((previous, next) => previous == next)
        .asyncMap((revision) async {
          if (revision == null) return const <TranscriptLine>[];
          if (_linesCache.isCached(rowId: transcriptId, revision: revision)) {
            return _cachedLinesFor(rowId: transcriptId, revision: revision);
          }
          final row = await transcriptRowById(transcriptId);
          if (row == null) return const <TranscriptLine>[];
          await _preloadLinesForRow(row);
          return _linesForRow(row);
        })
        .distinctBy(listEquals);
  }

  Future<TranscriptRow?> _primaryTranscriptRowForMedia(String mediaId) async {
    final tt = await dexieTargetTypeForId(_db, mediaId);
    if (tt == null) return null;
    final echo = await _db.echoSessionDao.getLatestForTarget(tt, mediaId);
    final id = echo?.transcriptId;
    if (id == null) return null;
    return _db.transcriptDao.getById(id);
  }

  Stream<List<TranscriptTrack>> _watchTracks(String mediaId) =>
      Stream.fromFuture(dexieTargetTypeForId(_db, mediaId)).asyncExpand((tt) {
        if (tt == null) {
          return Stream.value(<TranscriptTrack>[]);
        }
        return _db.transcriptDao
            .watchSummariesForTarget(tt, mediaId)
            .map((summaries) {
              final sorted = [...summaries];
              _sortTranscriptSummaries(sorted);
              return sorted.map(_trackFromSummary).toList();
            })
            .distinctBy(listEquals);
      });
}
