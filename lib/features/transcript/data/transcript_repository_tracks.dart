part of 'transcript_repository.dart';

/// Track and session management for [TranscriptRepository]: activating
/// primary / secondary tracks, deleting tracks with fallback-primary
/// selection, in-place timeline replacement, and AI (ASR) generated track
/// upserts.
extension _TranscriptRepositoryTracks on TranscriptRepository {
  /// Writes one transcript track row and drops its decoded-timeline memo.
  ///
  /// The single home for track writes: encodes [lines] through
  /// [encodeTimelineJsonGated], builds the row through [buildTranscriptRow]
  /// and upserts it, so a new track column or a new timeline encoding rule
  /// changes one place instead of every write site.
  ///
  /// The memo entry for [id] is evicted after the write. The timeline memo is
  /// keyed on the row's `(updatedAt, jsonLength)` revision, so the next read
  /// re-decodes the stored timeline anyway; the eviction keeps that guarantee
  /// independent of the revision key.
  Future<void> _upsertTranscriptTrack({
    required String id,
    required String targetType,
    required String targetId,
    required String language,
    required String source,
    required List<TranscriptLine> lines,
    required DateTime createdAt,
    DateTime? updatedAt,
    String label = '',
    String? referenceId,
    int? trackIndex,
    String syncStatus = 'local',
    DateTime? serverUpdatedAt,
  }) async {
    final timelineJson = await encodeTimelineJsonGated(lines);
    await _db.transcriptDao.upsert(
      buildTranscriptRow(
        id: id,
        targetType: targetType,
        targetId: targetId,
        language: language,
        source: source,
        timelineJson: timelineJson,
        referenceId: referenceId,
        label: label,
        trackIndex: trackIndex,
        syncStatus: syncStatus,
        serverUpdatedAt: serverUpdatedAt,
        createdAt: createdAt,
        updatedAt: updatedAt,
      ),
    );
    _linesCache.remove(id);
  }

  Future<String?> _upsertAsrGeneratedTrack({
    required String mediaId,
    required String language,
    required List<TranscriptLine> lines,
    String? label,
    bool activateAsPrimary = true,
  }) async {
    final tt = await dexieTargetTypeForId(_db, mediaId);
    if (tt == null) return null;
    if (lines.isEmpty) return null;

    const source = 'ai';
    final id = enjoyTranscriptId(
      targetType: tt,
      targetId: mediaId,
      language: language,
      source: source,
    );
    final existing = await _db.transcriptDao.getById(id);
    final now = DateTime.now();
    final resolvedLabel = (label != null && label.isNotEmpty)
        ? label
        : (existing?.label.isNotEmpty == true
              ? existing!.label
              : 'Generated ($language)');
    await _upsertTranscriptTrack(
      id: id,
      targetType: tt,
      targetId: mediaId,
      language: language,
      source: source,
      lines: lines,
      label: resolvedLabel,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    if (activateAsPrimary) {
      await setActiveTranscript(mediaId, id);
    }
    return id;
  }

  Future<void> _setActiveTranscript(String mediaId, String transcriptId) async {
    final tt = await dexieTargetTypeForId(_db, mediaId);
    if (tt == null) return;
    await _db.echoSessionDao.updatePrimaryTranscriptForTarget(
      tt,
      mediaId,
      transcriptId,
    );
  }

  Future<void> _setSecondaryTranscript(
    String mediaId,
    String? transcriptId,
  ) async {
    final tt = await dexieTargetTypeForId(_db, mediaId);
    if (tt == null) return;
    await _db.echoSessionDao.updateSecondaryTranscriptForTarget(
      tt,
      mediaId,
      transcriptId,
    );
  }

  Future<void> _deleteTranscript(String transcriptId) async {
    final row = await _db.transcriptDao.getById(transcriptId);
    if (row == null) return;

    final targetType = row.targetType;
    final targetId = row.targetId;
    final session = await _db.echoSessionDao.getLatestForTarget(
      targetType,
      targetId,
    );

    _pendingAutoTranslateLines.remove(transcriptId);
    _linesCache.remove(transcriptId);
    await _db.transcriptDao.deleteId(transcriptId);

    if (session == null) return;

    var newPrimary = session.transcriptId;
    var newSecondary = session.secondaryTranscriptId;

    if (session.transcriptId == transcriptId) {
      newPrimary = await _nextPrimaryAfterDelete(targetType, targetId);
    }
    if (session.secondaryTranscriptId == transcriptId) {
      newSecondary = null;
    }
    if (newPrimary != null && newSecondary == newPrimary) {
      newSecondary = null;
    }

    if (newPrimary != session.transcriptId) {
      await _db.echoSessionDao.updatePrimaryTranscriptForTarget(
        targetType,
        targetId,
        newPrimary,
      );
    }
    if (newSecondary != session.secondaryTranscriptId) {
      await _db.echoSessionDao.updateSecondaryTranscriptForTarget(
        targetType,
        targetId,
        newSecondary,
      );
    }
  }

  Future<TranscriptRow?> _transcriptRowById(String transcriptId) =>
      _db.transcriptDao.getById(transcriptId);

  Future<List<TranscriptRow>> _transcriptRowsForMedia(String mediaId) async {
    final targetType = await dexieTargetTypeForId(_db, mediaId);
    if (targetType == null) return const [];
    final rows = await _db.transcriptDao.listForTarget(targetType, mediaId);
    _sortTranscriptRows(rows);
    return rows;
  }

  Future<bool> _replaceTimeline({
    required String transcriptId,
    required List<TranscriptLine> lines,
  }) async {
    final existing = await _db.transcriptDao.getById(transcriptId);
    if (existing == null) return false;
    final timelineJson = await encodeTimelineJsonGated(lines);
    await _db.transcriptDao.upsert(
      existing.copyWith(
        timelineJson: timelineJson,
        updatedAt: DateTime.now(),
        syncStatus: const Value('local'),
      ),
    );
    _linesCache.remove(transcriptId);
    return true;
  }

  /// Picks the next primary transcript for [targetId] after delete:
  /// [official] > [auto] > [ai] > [user], then earliest [createdAt].
  Future<String?> _nextPrimaryAfterDelete(
    String targetType,
    String targetId,
  ) async {
    final remaining = await _db.transcriptDao.listForTarget(
      targetType,
      targetId,
    );
    if (remaining.isEmpty) return null;
    _sortTranscriptRows(remaining);
    return remaining.first.id;
  }
}
