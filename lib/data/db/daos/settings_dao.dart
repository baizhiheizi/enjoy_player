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

  /// Rejects access to a key that does not belong to this database.
  ///
  /// Device-scoped keys read through a per-user file are a hard error in
  /// debug builds: the production per-user database name is always
  /// distinguishable (`enjoy_player_<userId>`), so this is an unambiguous
  /// placement bug — previously it silently returned `null`.
  ///
  /// User-scoped keys through a device-global-named file only log: in-memory
  /// test databases default to the device-global name while legitimately
  /// impersonating both roles. In production, pick the database from the
  /// key's scope (`settingsDatabaseFor`) and this path never fires.
  void _assertPlacement(SettingKey<dynamic> key) {
    final deviceDb = attachedDatabase.isDeviceGlobalDatabase;
    if (key.scope == SettingsScope.device && !deviceDb) {
      final message =
          'Settings key ${key.name} is device-scoped but was accessed '
          'through the per-user database '
          '"${attachedDatabase.databaseFileBaseName}"; '
          'use deviceGlobalAppDatabaseProvider for it.';
      assert(() {
        throw StateError(message);
      }());
      _log.warning(message);
      return;
    }
    if (key.scope == SettingsScope.user && deviceDb) {
      _log.warning(
        'Settings key ${key.name} is user-scoped but was accessed through '
        'the device-global database; expected the per-user database.',
      );
    }
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

  /// Reads [key]'s typed value: the key's declared default when the row is
  /// missing, else the codec-decoded stored string.
  Future<T> readSetting<T>(SettingKey<T> key) async {
    _assertPlacement(key);
    final raw = await getValue(key.name);
    if (raw == null) {
      assert(
        key.defaultValue != null || null is T,
        'SettingKey ${key.name} declares a null default for non-nullable '
        '$T — every non-nullable key must declare a value.',
      );
      return key.defaultValue as T;
    }
    return key.codec.decode(raw);
  }

  /// Writes [key]'s typed value, encoded by the key's codec.
  ///
  /// Placement errors surface as a failed future (not a synchronous throw)
  /// so un-awaited writes cannot escape a caller's try/catch.
  Future<void> writeSetting<T>(SettingKey<T> key, T value) async {
    _assertPlacement(key);
    await setValue(key.name, key.codec.encode(value));
  }

  /// Deletes [key]'s row.
  Future<void> deleteSetting<T>(SettingKey<T> key) async {
    _assertPlacement(key);
    await deleteValue(key.name);
  }

  /// Deletes all rows whose key starts with [prefix].
  ///
  /// Only prefixes of families that declare [SettingKeyFamily.allowPrefixDelete]
  /// are accepted (currently the onboarding empty-transcript keys).
  Future<int> deleteKeysWithPrefix(String prefix) async {
    final allowed = SettingsKeys.declaredFamilies.any(
      (family) => family.allowPrefixDelete && family.prefix == prefix,
    );
    if (!allowed) {
      final message = 'Refusing deleteKeysWithPrefix for: $prefix';
      assert(() {
        throw StateError(message);
      }());
      _log.warning(message);
      return 0;
    }
    return (delete(settingsKv)..where((t) => t.key.like('$prefix%'))).go();
  }
}
