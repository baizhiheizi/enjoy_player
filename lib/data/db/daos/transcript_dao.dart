part of '../app_database.dart';

/// Light read-model for [TranscriptDao.watchSummariesForTarget]: track
/// metadata plus the change-tick columns, never `timeline_json` (issue
/// #810 D2 — watching full rows re-copied every timeline blob to the UI
/// isolate on each write).
final class TranscriptTrackSummary {
  const TranscriptTrackSummary({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.language,
    required this.source,
    required this.label,
    required this.trackIndex,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String targetType;
  final String targetId;
  final String language;
  final String source;
  final String label;
  final int? trackIndex;
  final DateTime createdAt;
  final DateTime updatedAt;
}

/// Projected transcript metadata for callers that need identity, language and
/// change detection but never `timeline_json`.
final class TranscriptMeta {
  const TranscriptMeta({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.language,
    required this.source,
    required this.referenceId,
    required this.revision,
  });

  final String id;
  final String targetType;
  final String targetId;
  final String language;
  final String source;
  final String? referenceId;
  final ({DateTime updatedAt, int jsonLength}) revision;
}

@DriftAccessor(tables: [Transcripts])
class TranscriptDao extends DatabaseAccessor<AppDatabase>
    with _$TranscriptDaoMixin {
  TranscriptDao(super.db);

  Stream<List<TranscriptTrackSummary>> watchSummariesForTarget(
    String targetType,
    String targetId,
  ) {
    final query = selectOnly(transcripts)
      ..addColumns([
        transcripts.id,
        transcripts.targetType,
        transcripts.targetId,
        transcripts.language,
        transcripts.source,
        transcripts.label,
        transcripts.trackIndex,
        transcripts.createdAt,
        transcripts.updatedAt,
      ])
      ..where(
        transcripts.targetType.equals(targetType) &
            transcripts.targetId.equals(targetId),
      )
      ..orderBy([
        OrderingTerm.asc(transcripts.source),
        OrderingTerm.asc(transcripts.language),
        OrderingTerm.asc(transcripts.createdAt),
      ]);
    return query.watch().map(
      (rows) => [
        for (final row in rows)
          TranscriptTrackSummary(
            id: row.read<String>(transcripts.id)!,
            targetType: row.read<String>(transcripts.targetType)!,
            targetId: row.read<String>(transcripts.targetId)!,
            language: row.read<String>(transcripts.language)!,
            source: row.read<String>(transcripts.source)!,
            label: row.read<String>(transcripts.label)!,
            trackIndex: row.read<int>(transcripts.trackIndex),
            createdAt: row.read<DateTime>(transcripts.createdAt)!,
            updatedAt: row.read<DateTime>(transcripts.updatedAt)!,
          ),
      ],
    );
  }

  Stream<bool> watchExistsForTarget(String targetType, String targetId) {
    return customSelect(
      'SELECT EXISTS (SELECT 1 FROM transcripts WHERE target_type = ? AND target_id = ?) AS e',
      variables: [
        Variable.withString(targetType),
        Variable.withString(targetId),
      ],
      readsFrom: {transcripts},
    ).watch().map((rows) => rows.first.read<int>('e') != 0);
  }

  /// Change tick for one row: `(updated_at, length(timeline_json))` without
  /// materializing the blob. `TranscriptDao.upsert` guarantees consecutive
  /// stored writes never share an `updated_at` second, so a changed record is
  /// a changed revision.
  ///
  /// SQLite `length()` counts characters, not UTF-16 code units; the Dart
  /// side of the memo key must use `timelineJsonCharacterCount` to match.
  Stream<({DateTime updatedAt, int jsonLength})?> watchRevisionById(String id) {
    final jsonLength = transcripts.timelineJson.length;
    final query = selectOnly(transcripts)
      ..addColumns([transcripts.updatedAt, jsonLength])
      ..where(transcripts.id.equals(id));
    return query.watchSingleOrNull().map((row) {
      if (row == null) return null;
      final updatedAt = row.read(transcripts.updatedAt);
      final length = row.read(jsonLength);
      if (updatedAt == null || length == null) return null;
      return (updatedAt: updatedAt, jsonLength: length);
    });
  }

  Future<TranscriptMeta?> metaById(String id) async {
    final jsonLength = transcripts.timelineJson.length;
    final query = selectOnly(transcripts)
      ..addColumns([
        transcripts.id,
        transcripts.targetType,
        transcripts.targetId,
        transcripts.language,
        transcripts.source,
        transcripts.referenceId,
        transcripts.updatedAt,
        jsonLength,
      ])
      ..where(transcripts.id.equals(id));
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return TranscriptMeta(
      id: row.read(transcripts.id)!,
      targetType: row.read(transcripts.targetType)!,
      targetId: row.read(transcripts.targetId)!,
      language: row.read(transcripts.language)!,
      source: row.read(transcripts.source)!,
      referenceId: row.read(transcripts.referenceId),
      revision: (
        updatedAt: row.read(transcripts.updatedAt)!,
        jsonLength: row.read(jsonLength)!,
      ),
    );
  }

  Future<TranscriptRow?> getById(String id) =>
      (select(transcripts)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<TranscriptRow>> listForTarget(
    String targetType,
    String targetId,
  ) =>
      (select(transcripts)..where(
            (t) =>
                t.targetType.equals(targetType) & t.targetId.equals(targetId),
          ))
          .get();

  /// Inserts or replaces [row], keeping the stored `updated_at` a per-row
  /// content revision: drift stores `DateTime` at whole-second granularity,
  /// so a second write landing in the same stored second is nudged one
  /// second forward. Together with the JSON length this guarantees the
  /// `(updated_at, length)` pair changes on every content change — the key
  /// the timeline decode memo relies on (issue #810 D5).
  Future<void> upsert(TranscriptRow row) async {
    final existingUpdatedAt = await _readUpdatedAt(row.id);
    await into(transcripts).insert(
      _withDistinctStoredSecond(row, existingUpdatedAt),
      mode: InsertMode.insertOrReplace,
    );
  }

  /// Bulk variant of [upsert] with the same revision guarantee.
  Future<void> upsertAll(List<TranscriptRow> rows) async {
    if (rows.isEmpty) return;
    final existingUpdatedAts = await _readUpdatedAts(
      rows.map((r) => r.id).toSet(),
    );
    await batch((b) {
      for (final row in rows) {
        b.insert(
          transcripts,
          _withDistinctStoredSecond(row, existingUpdatedAts[row.id]),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> deleteId(String id) =>
      (delete(transcripts)..where((t) => t.id.equals(id))).go();

  Future<DateTime?> _readUpdatedAt(String id) async {
    final query = selectOnly(transcripts)
      ..addColumns([transcripts.updatedAt])
      ..where(transcripts.id.equals(id));
    final row = await query.getSingleOrNull();
    return row?.read<DateTime>(transcripts.updatedAt);
  }

  Future<Map<String, DateTime>> _readUpdatedAts(Set<String> ids) async {
    if (ids.isEmpty) return {};
    final query = selectOnly(transcripts)
      ..addColumns([transcripts.id, transcripts.updatedAt])
      ..where(transcripts.id.isIn(ids));
    return {
      for (final row in await query.get())
        row.read<String>(transcripts.id)!: row.read<DateTime>(
          transcripts.updatedAt,
        )!,
    };
  }

  TranscriptRow _withDistinctStoredSecond(
    TranscriptRow row,
    DateTime? existingUpdatedAt,
  ) {
    if (existingUpdatedAt == null) return row;
    final existingSecond = existingUpdatedAt.millisecondsSinceEpoch ~/ 1000;
    if (row.updatedAt.millisecondsSinceEpoch ~/ 1000 != existingSecond) {
      return row;
    }
    return row.copyWith(
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        (existingSecond + 1) * 1000,
      ),
    );
  }
}
