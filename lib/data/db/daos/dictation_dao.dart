part of '../app_database.dart';

typedef DictationTiming = ({
  int referenceStartMs,
  int referenceDurationMs,
  DateTime createdAt,
});

@DriftAccessor(tables: [Dictations])
class DictationDao extends DatabaseAccessor<AppDatabase>
    with _$DictationDaoMixin {
  DictationDao(super.db);

  Stream<List<DictationRow>> watchByTarget(
    String targetType,
    String targetId,
  ) =>
      (select(dictations)
            ..where(
              (t) =>
                  t.targetType.equals(targetType) & t.targetId.equals(targetId),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch()
          .distinctBy(listEquals);

  Stream<List<DictationTiming>> watchTimingsByTarget(
    String targetType,
    String targetId,
  ) {
    final query = selectOnly(dictations)
      ..addColumns([
        dictations.referenceStartMs,
        dictations.referenceDurationMs,
        dictations.createdAt,
      ])
      ..where(
        dictations.targetType.equals(targetType) &
            dictations.targetId.equals(targetId),
      )
      ..orderBy([OrderingTerm.desc(dictations.createdAt)]);
    return query
        .watch()
        .map(
          (rows) => [
            for (final row in rows)
              (
                referenceStartMs: row.read(dictations.referenceStartMs)!,
                referenceDurationMs: row.read(dictations.referenceDurationMs)!,
                createdAt: row.read(dictations.createdAt)!,
              ),
          ],
        )
        .distinctBy(listEquals);
  }

  Stream<List<DictationRow>> watchByEchoRegion(
    String targetType,
    String targetId,
    int referenceStartMs,
    int referenceDurationMs,
  ) =>
      (select(dictations)
            ..where(
              (t) =>
                  t.targetType.equals(targetType) &
                  t.targetId.equals(targetId) &
                  t.referenceStartMs.equals(referenceStartMs) &
                  t.referenceDurationMs.equals(referenceDurationMs),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch()
          .distinctBy(listEquals);

  Future<void> insertRow(DictationRow row) =>
      into(dictations).insert(row, mode: InsertMode.insertOrReplace);

  Future<void> deleteId(String id) =>
      (delete(dictations)..where((t) => t.id.equals(id))).go();
}
