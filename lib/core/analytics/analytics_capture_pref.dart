/// Persisted product analytics capture preference (specs/046, research D4).
///
/// Device-global on purpose: it must cover anonymous pre-sign-in events and
/// survive sign-out so a shared device's next user neither inherits nor
/// silently loses the previous user's choice (spec FR-007). Mirrors the
/// `DiagnosticsVerbose` recipe. Storage goes through the typed
/// [SettingsKeys.analyticsCaptureEnabled] key — scope and the opt-out
/// polarity (missing ≡ on) live in the key's declaration, not here.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/data/db/settings_keys.dart';

part 'analytics_capture_pref.g.dart';

@Riverpod(keepAlive: true)
class AnalyticsCapturePref extends _$AnalyticsCapturePref {
  @override
  Future<bool> build() async {
    final db = ref.watch(deviceGlobalAppDatabaseProvider);
    return db.settingsDao.readSetting(SettingsKeys.analyticsCaptureEnabled);
  }

  /// Persists the choice, then reports it so callers can apply the vendor
  /// enable/disable immediately. DB first: the toggle reflects stored truth
  /// on restart even if the vendor call fails.
  Future<bool> setEnabled(bool enabled) async {
    final db = ref.read(deviceGlobalAppDatabaseProvider);
    await db.settingsDao.writeSetting(
      SettingsKeys.analyticsCaptureEnabled,
      enabled,
    );
    state = AsyncData(enabled);
    return enabled;
  }
}
