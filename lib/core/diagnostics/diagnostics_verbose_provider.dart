/// Persisted diagnostic verbose logging preference.
///
/// Storage goes through the typed [SettingsKeys.diagnosticsVerboseEnabled]
/// key: scope (device-global DB) and `'true'`/`'false'` polarity live in the
/// key's declaration (`settings_keys.dart`), not here.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/core/logging/diagnostic_log_config.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/data/db/settings_keys.dart';

part 'diagnostics_verbose_provider.g.dart';

@Riverpod(keepAlive: true)
class DiagnosticsVerbose extends _$DiagnosticsVerbose {
  @override
  Future<bool> build() async {
    final db = ref.watch(deviceGlobalAppDatabaseProvider);
    final enabled = await db.settingsDao.readSetting(
      SettingsKeys.diagnosticsVerboseEnabled,
    );
    DiagnosticLogConfig.setVerboseEnabled(enabled);
    return enabled;
  }

  Future<void> setEnabled(bool enabled) async {
    final db = ref.read(deviceGlobalAppDatabaseProvider);
    await db.settingsDao.writeSetting(
      SettingsKeys.diagnosticsVerboseEnabled,
      enabled,
    );
    DiagnosticLogConfig.setVerboseEnabled(enabled);
    state = AsyncData(enabled);
  }
}
