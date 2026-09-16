/// Persisted diagnostic verbose logging preference.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/core/logging/diagnostic_log_config.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/data/db/settings_keys.dart';

part 'diagnostics_verbose_provider.g.dart';

Future<bool> readDiagnosticsVerboseEnabledFromDb(AppDatabase db) async {
  final raw = await db.settingsDao.getValue(
    SettingsKeys.diagnosticsVerboseEnabled.name,
  );
  return raw == 'true';
}

Future<void> writeDiagnosticsVerboseEnabledToDb(
  AppDatabase db, {
  required bool enabled,
}) async {
  await db.settingsDao.setValue(
    SettingsKeys.diagnosticsVerboseEnabled.name,
    enabled ? 'true' : 'false',
  );
}

@Riverpod(keepAlive: true)
class DiagnosticsVerbose extends _$DiagnosticsVerbose {
  @override
  Future<bool> build() async {
    final db = ref.watch(deviceGlobalAppDatabaseProvider);
    final enabled = await readDiagnosticsVerboseEnabledFromDb(db);
    DiagnosticLogConfig.setVerboseEnabled(enabled);
    return enabled;
  }

  Future<void> setEnabled(bool enabled) async {
    final db = ref.read(deviceGlobalAppDatabaseProvider);
    await writeDiagnosticsVerboseEnabledToDb(db, enabled: enabled);
    DiagnosticLogConfig.setVerboseEnabled(enabled);
    state = AsyncData(enabled);
  }
}
