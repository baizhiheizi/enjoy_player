part of '../app_database.dart';

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
          .watch();

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
          .watch();

  Future<void> insertRow(DictationRow row) =>
      into(dictations).insert(row, mode: InsertMode.insertOrReplace);

  Future<void> deleteId(String id) =>
      (delete(dictations)..where((t) => t.id.equals(id))).go();
}
