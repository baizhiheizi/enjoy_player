/// Persists in-flight Enjoy long-form ASR attempts for resume after restart.
library;

import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/core/json/json_cast.dart';
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

  Future<AsrLongFormAttempt?> load(String mediaId) async {
    final raw = await _db.settingsDao.getValue(
      SettingsKeys.asrLongFormAttempt(mediaId),
    );
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = castJsonObjectOrNull(jsonDecode(raw));
      if (map == null) return null;
      return AsrLongFormAttempt.fromJson(map);
    } on Object catch (e, st) {
      _log.warning('Failed to decode long-form attempt for $mediaId', e, st);
      return null;
    }
  }

  Future<void> save(AsrLongFormAttempt attempt) async {
    await _db.settingsDao.setValue(
      SettingsKeys.asrLongFormAttempt(attempt.mediaId),
      jsonEncode(attempt.toJson()),
    );
  }

  Future<void> clear(String mediaId) async {
    await _db.settingsDao.deleteValue(SettingsKeys.asrLongFormAttempt(mediaId));
  }
}

@Riverpod(keepAlive: true)
AsrLongFormAttemptStore asrLongFormAttemptStore(Ref ref) {
  return AsrLongFormAttemptStore(ref.watch(appDatabaseProvider));
}
