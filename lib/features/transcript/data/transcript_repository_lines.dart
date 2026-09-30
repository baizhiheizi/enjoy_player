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

  Stream<List<TranscriptLine>> _watchLines(
    String mediaId, {
    required bool primary,
  }) {
    return Stream.fromFuture(dexieTargetTypeForId(_db, mediaId)).asyncExpand((
      tt,
    ) {
      if (tt == null) {
        return Stream.value(<TranscriptLine>[]);
      }
      return Stream.fromFuture(
        _computeActiveLines(tt, mediaId, primary: primary),
      ).asyncExpand((initial) async* {
        yield initial;
        yield* StreamGroup.merge([
          _db.echoSessionDao
              .watchLatestForTarget(tt, mediaId)
              .asyncMap(
                (_) => _computeActiveLines(tt, mediaId, primary: primary),
              ),
          _db.transcriptDao
              .watchSummariesForTarget(tt, mediaId)
              .asyncMap(
                (_) => _computeActiveLines(tt, mediaId, primary: primary),
              ),
        ]).distinctBy(listEquals);
      });
    });
  }

  Future<List<TranscriptLine>> _computeActiveLines(
    String tt,
    String mediaId, {
    required bool primary,
  }) async {
    final echo = await _db.echoSessionDao.getLatestForTarget(tt, mediaId);
    final id = primary ? echo?.transcriptId : echo?.secondaryTranscriptId;
    if (id == null) return <TranscriptLine>[];
    final row = await _db.transcriptDao.getById(id);
    if (row == null) return <TranscriptLine>[];
    await _preloadLinesForRow(row);
    return linesForRow(row);
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
