/// Persists in-flight Enjoy long-form ASR attempts for resume after restart.
///
/// Rows go through the typed [SettingsKeys.asrLongFormAttempts] family
/// (per-user DB, JSON object codec keyed by media id).
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/data/db/settings_keys.dart';
import 'package:enjoy_player/features/asr/domain/asr_long_form_models.dart';

part 'asr_long_form_attempt_store.g.dart';

final _log = logNamed('asr.longForm.attemptStore');

class AsrLongFormAttemptStore {
  AsrLongFormAttemptStore(this._db);

  final AppDatabase _db;

  SettingKey<Map<String, dynamic>?> _key(String mediaId) =>
      SettingsKeys.asrLongFormAttempts.keyFor(mediaId);

  Future<AsrLongFormAttempt?> load(String mediaId) async {
    final Map<String, dynamic>? map;
    try {
      map = await _db.settingsDao.readSetting(_key(mediaId));
    } on Object catch (e, st) {
      _log.warning('Failed to decode long-form attempt for $mediaId', e, st);
      return null;
    }
    if (map == null || map.isEmpty) return null;
    return AsrLongFormAttempt.fromJson(map);
  }

  Future<void> save(AsrLongFormAttempt attempt) async {
    await _db.settingsDao.writeSetting(
      _key(attempt.mediaId),
      attempt.toJson(),
    );
  }

  Future<void> clear(String mediaId) async {
    await _db.settingsDao.deleteSetting(_key(mediaId));
  }
}

@Riverpod(keepAlive: true)
AsrLongFormAttemptStore asrLongFormAttemptStore(Ref ref) {
  return AsrLongFormAttemptStore(ref.watch(appDatabaseProvider));
}
