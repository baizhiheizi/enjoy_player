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

  Future<void> insertRow(DictationRow row) =>
      into(dictations).insert(row, mode: InsertMode.insertOrReplace);

  Future<void> deleteId(String id) =>
      (delete(dictations)..where((t) => t.id.equals(id))).go();
}
