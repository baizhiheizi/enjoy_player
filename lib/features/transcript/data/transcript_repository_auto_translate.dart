part of 'transcript_repository.dart';

/// Auto-translate AI-track management for [TranscriptRepository]: durable
/// skeleton creation keyed to the primary transcript, debounced per-line
/// translated text writes (issue #810 D1 — one row rewrite per flush window
/// instead of one per line), and staleness detection against the current
/// primary.
typedef _PendingAutoTranslateLine = ({String text, String? sourceKey});

extension _TranscriptRepositoryAutoTranslate on TranscriptRepository {
  Future<String?> _ensureAutoTranslateTrack({
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

    _pendingAutoTranslateLines.remove(id);
    final skeleton = buildAutoTranslateSkeleton(primaryLines);
    final json = await encodeTimelineJsonGated(skeleton);
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

  Future<void> _updateAutoTranslateLineText({
    required String aiTranscriptId,
    required int lineIndex,
    required String text,
    String? sourceKey,
  }) async {
    if (lineIndex < 0) return;
    _pendingAutoTranslateLines.putIfAbsent(
      aiTranscriptId,
      () => {},
    )[lineIndex] = (
      text: text,
      sourceKey: sourceKey,
    );
    _scheduleAutoTranslateFlush();
  }

  Future<void> _flushAutoTranslateWrites() => _enqueueAutoTranslateFlush();

  void _scheduleAutoTranslateFlush() {
    _autoTranslateFlushTimer ??= Timer(kAutoTranslateFlushInterval, () {
      _autoTranslateFlushTimer = null;
      unawaited(
        _enqueueAutoTranslateFlush().catchError((Object e, StackTrace st) {
          _log.warning('auto-translate flush failed', e, st);
        }),
      );
    });
  }

  Future<void> _enqueueAutoTranslateFlush() {
    final previous = _autoTranslateFlushChain ?? Future<void>.value();
    final run = previous.then((_) => _drainAutoTranslateWrites());
    _autoTranslateFlushChain = run.then<void>(
      (_) {},
      onError: (Object e, StackTrace st) {},
    );
    return run;
  }

  Future<void> _drainAutoTranslateWrites() async {
    _autoTranslateFlushTimer?.cancel();
    _autoTranslateFlushTimer = null;
    while (_pendingAutoTranslateLines.isNotEmpty) {
      final pending = _pendingAutoTranslateLines;
      _pendingAutoTranslateLines = {};
      for (final entry in pending.entries) {
        await _applyAutoTranslateLines(entry.key, entry.value);
      }
    }
  }

  Future<void> _applyAutoTranslateLines(
    String aiTranscriptId,
    Map<int, _PendingAutoTranslateLine> updates,
  ) async {
    if (updates.isEmpty) return;
    final row = await _db.transcriptDao.getById(aiTranscriptId);
    if (row == null) return;
    await _preloadLinesForRow(row);
    final lines = [
      ..._linesCache.linesFor(
        rowId: row.id,
        revision: _revisionOf(row),
        timelineJson: row.timelineJson,
      ),
    ];
    var changed = false;
    for (final update in updates.entries) {
      final index = update.key;
      if (index < 0 || index >= lines.length) continue;
      lines[index] = _autoTranslateLineWith(lines[index], update.value);
      changed = true;
    }
    if (!changed) return;
    final timelineJson = await encodeTimelineJsonGated(lines);
    await _db.transcriptDao.upsert(
      row.copyWith(timelineJson: timelineJson, updatedAt: DateTime.now()),
    );
    _linesCache.remove(aiTranscriptId);
  }

  List<TranscriptLine> _overlayPendingAutoTranslateLines(
    String rowId,
    List<TranscriptLine> base,
  ) {
    final pending = _pendingAutoTranslateLines[rowId];
    if (pending == null || pending.isEmpty) return base;
    return [
      for (var i = 0; i < base.length; i++)
        pending.containsKey(i)
            ? _autoTranslateLineWith(base[i], pending[i]!)
            : base[i],
    ];
  }

  TranscriptLine _autoTranslateLineWith(
    TranscriptLine line,
    _PendingAutoTranslateLine update,
  ) => TranscriptLine(
    text: update.text,
    startMs: line.startMs,
    durationMs: line.durationMs,
    sourceKey: update.text.trim().isEmpty ? null : update.sourceKey,
  );

  bool _isAutoTranslateTrackStale({
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
}
