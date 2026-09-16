/// Persisted transcript IPA overlay preference (default off).
///
/// Storage goes through the typed [SettingsKeys.transcriptIpaOverlay] key:
/// scope (device-global DB) and `'true'`/`'false'` polarity live in the key's
/// declaration (`settings_keys.dart`), not here.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/data/db/settings_keys.dart';

part 'ipa_overlay_settings.g.dart';

@Riverpod(keepAlive: true)
class IpaOverlaySettings extends _$IpaOverlaySettings {
  @override
  Future<bool> build() async {
    final db = ref.watch(deviceGlobalAppDatabaseProvider);
    return db.settingsDao.readSetting(SettingsKeys.transcriptIpaOverlay);
  }

  Future<void> setEnabled(bool enabled) async {
    final db = ref.read(deviceGlobalAppDatabaseProvider);
    await db.settingsDao.writeSetting(
      SettingsKeys.transcriptIpaOverlay,
      enabled,
    );
    state = AsyncData(enabled);
  }
}
