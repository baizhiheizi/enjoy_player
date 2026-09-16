/// Persisted transcript karaoke / current-word highlight preference (default off).
///
/// Storage goes through the typed [SettingsKeys.transcriptKaraokeHighlight]
/// key: scope (device-global DB) and `'true'`/`'false'` polarity live in the
/// key's declaration (`settings_keys.dart`), not here.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/data/db/settings_keys.dart';

part 'karaoke_highlight_settings.g.dart';

@Riverpod(keepAlive: true)
class KaraokeHighlightSettings extends _$KaraokeHighlightSettings {
  @override
  Future<bool> build() async {
    final db = ref.watch(deviceGlobalAppDatabaseProvider);
    return db.settingsDao.readSetting(SettingsKeys.transcriptKaraokeHighlight);
  }

  Future<void> setEnabled(bool enabled) async {
    final db = ref.read(deviceGlobalAppDatabaseProvider);
    await db.settingsDao.writeSetting(
      SettingsKeys.transcriptKaraokeHighlight,
      enabled,
    );
    state = AsyncData(enabled);
  }
}
