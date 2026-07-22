part of 'transcript_repository.dart';

/// Auto-translate track management for [TranscriptRepository]: the durable
/// `source: ai` timing-skeleton track, per-line translated text writes,
/// staleness detection, and re-translate clearing.
///
/// Public extension so importers of `transcript_repository.dart` keep
/// calling these methods unchanged; extension members are non-virtual.
extension TranscriptRepositoryAutoTranslate on TranscriptRepository {
  /// Ensures a durable `source: ai` track exists with a timing skeleton for
  /// auto-translate. Returns the track id, or null when the target is unknown.
  ///
  /// When a non-stale AI track already exists for the same primary, its
  /// translated texts are **preserved** (no rewrite). Stale tracks are rebuilt
  /// as an empty skeleton so mismatched bilingual pairs are never shown.
  Future<String?> ensureAutoTranslateTrack({
    required String mediaId,
    required String primaryTranscriptId,
    required String targetLanguage,
    required List<TranscriptLine> primaryLines,
  }) async {
    final tt = await dexieTargetTypeForId(_db, mediaId);
    if (tt == null || primaryLines.isEmpty) return null;

    final id = autoTranslateAiTrackId(
      targetType: tt,
      mediaId: mediaId,
      targetLanguage: targetLanguage,
    );
    final existing = await _db.transcriptDao.getById(id);
    if (existing != null &&
        !isAutoTranslateTrackStale(
          aiRow: existing,
          primaryId: primaryTranscriptId,
          primaryLines: primaryLines,
        )) {
      return id;
    }

    final skeleton = buildAutoTranslateSkeleton(primaryLines);
    final json = jsonEncode(skeleton.map((e) => e.toJson()).toList());
    final now = DateTime.now();

    await _db.transcriptDao.upsert(
      TranscriptRow(
        id: id,
        targetType: tt,
        targetId: mediaId,
        language: targetLanguage,
        source: 'ai',
        timelineJson: json,
        referenceId: primaryTranscriptId,
        label: existing?.label.isNotEmpty == true
            ? existing!.label
            : 'Auto translate ($targetLanguage)',
        trackIndex: null,
        syncStatus: 'local',
        serverUpdatedAt: null,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      ),
    );
    _linesCache.remove(id);
    return id;
  }

  /// Writes one translated line into the AI track timeline.
  Future<void> updateAutoTranslateLineText({
    required String aiTranscriptId,
    required int lineIndex,
    required String text,
    String? sourceKey,
  }) async {
    final row = await _db.transcriptDao.getById(aiTranscriptId);
    if (row == null) return;
    final lines = List<TranscriptLine>.from(linesForRow(row));
    if (lineIndex < 0 || lineIndex >= lines.length) return;
    lines[lineIndex] = TranscriptLine(
      text: text,
      startMs: lines[lineIndex].startMs,
      durationMs: lines[lineIndex].durationMs,
      sourceKey: text.trim().isEmpty ? null : sourceKey,
    );
    final now = DateTime.now();
    await _db.transcriptDao.upsert(
      row.copyWith(
        timelineJson: jsonEncode(lines.map((e) => e.toJson()).toList()),
        updatedAt: now,
      ),
    );
    _linesCache.remove(aiTranscriptId);
  }

  /// Whether the AI track is out of sync with the current primary transcript.
  bool isAutoTranslateTrackStale({
    required TranscriptRow aiRow,
    required String primaryId,
    required List<TranscriptLine> primaryLines,
  }) {
    final aiLines = linesForRow(aiRow);
    return isAutoTranslateTimelineStale(
      referencePrimaryId: aiRow.referenceId,
      primaryId: primaryId,
      primaryLines: primaryLines,
      aiLines: aiLines,
    );
  }

  /// Clears translated texts while preserving timing skeleton (Re-translate).
  Future<void> clearAutoTranslateTexts({
    required String aiTranscriptId,
    required List<TranscriptLine> primaryLines,
  }) async {
    final row = await _db.transcriptDao.getById(aiTranscriptId);
    if (row == null) return;
    final skeleton = buildAutoTranslateSkeleton(primaryLines);
    final now = DateTime.now();
    await _db.transcriptDao.upsert(
      row.copyWith(
        timelineJson: jsonEncode(skeleton.map((e) => e.toJson()).toList()),
        updatedAt: now,
      ),
    );
    _linesCache.remove(aiTranscriptId);
  }
}
