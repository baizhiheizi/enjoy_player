/// Runtime diagnostic logging verbosity (allowlisted loggers only).
library;

import 'package:logging/logging.dart';

import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/data/db/settings_keys.dart';

/// Loggers that may emit FINE records to the diagnostic file when verbose is on.
const Set<String> kDiagnosticVerboseLoggerNames = {
  'YouTubePlayerEngine',
  'YouTubeWebView',
  'WebViewEnvironment',
  'sync',
  'api',
  'auth',
  'update',
};

/// In-memory verbose flag; synced from [SettingsDao] at startup and on toggle.
class DiagnosticLogConfig {
  DiagnosticLogConfig._();

  static bool verboseEnabled = false;

  static Future<void> loadFromDeviceGlobalSettings() async {
    try {
      await withDeviceGlobalAppDatabaseForBootstrap((db) async {
        final raw = await db.settingsDao.getValue(
          SettingsKeys.diagnosticsVerboseEnabled.name,
        );
        verboseEnabled = raw == 'true';
      });
    } on Object {
      // Runs before logging/error reporting is initialized, so any uncaught
      // error here is silently swallowed by main()'s zone guard, leaving a
      // permanently blank window with no mounted widget tree (no crash, no
      // log line). Never let a device-global DB hiccup block startup — fall back to
      // the default and let the real AppDatabase (opened later, once logging
      // is up) surface genuine errors through the normal error UI.
      verboseEnabled = false;
    }
  }

  static void setVerboseEnabled(bool enabled) {
    verboseEnabled = enabled;
  }

  static bool isAllowlistedLogger(String loggerName) {
    if (kDiagnosticVerboseLoggerNames.contains(loggerName)) return true;
    if (loggerName.startsWith('YouTube')) return true;
    return false;
  }

  /// Whether [record] should be written to the on-disk diagnostic log.
  static bool shouldPersistRecord(LogRecord record) {
    if (record.level >= Level.INFO) return true;
    if (record.error != null || record.stackTrace != null) return true;
    if (verboseEnabled && isAllowlistedLogger(record.loggerName)) {
      return record.level >= Level.FINE;
    }
    return false;
  }
}
