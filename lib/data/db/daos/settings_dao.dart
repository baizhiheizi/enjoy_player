part of '../app_database.dart';

@DriftAccessor(tables: [SettingsKv])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.db);

  static final _log = logNamed('SettingsDao');

  void _assertKnownKey(String key) {
    if (SettingsKeys.isKnown(key)) return;
    final message = 'Unknown settings key: $key';
    assert(() {
      throw StateError(message);
    }());
    _log.warning(message);
  }

  Future<String?> getValue(String key) async {
    _assertKnownKey(key);
    final row = await (select(
      settingsKv,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> setValue(String key, String value) {
    _assertKnownKey(key);
    return into(settingsKv).insert(
      SettingRow(key: key, value: value),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> deleteValue(String key) {
    _assertKnownKey(key);
    return (delete(settingsKv)..where((t) => t.key.equals(key))).go();
  }
}
