/// Runtime diagnostic logging verbosity (allowlisted loggers only).
library;

import 'package:logging/logging.dart';

import 'package:enjoy_player/data/db/app_database.dart';
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

  static Future<void> loadFromGuestSettings() async {
    final db = AppDatabase(name: AppDatabase.guestDatabaseName);
    try {
      final raw = await db.settingsDao.getValue(
        SettingsKeys.diagnosticsVerboseEnabled,
      );
      verboseEnabled = raw == 'true';
    } finally {
      await db.close();
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
