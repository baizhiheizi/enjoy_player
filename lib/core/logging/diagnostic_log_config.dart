/// Runtime diagnostic logging verbosity (allowlisted loggers only).
library;

import 'package:flutter/foundation.dart' show visibleForTesting;
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

  static Future<void>? _sessionLoad;

  /// Reads the persisted flag from the device-global database once per
  /// session; concurrent or repeated callers share the same future. The
  /// session banner and any flag consumer await this future instead of
  /// blocking startup on the database open.
  static Future<void> loadFromDeviceGlobalSettings() {
    return _sessionLoad ??= _readFromDeviceGlobalSettings();
  }

  static Future<void> _readFromDeviceGlobalSettings() async {
    try {
      await withDeviceGlobalAppDatabaseForBootstrap((db) async {
        verboseEnabled = await db.settingsDao.readSetting(
          SettingsKeys.diagnosticsVerboseEnabled,
        );
      });
    } on Object {
      verboseEnabled = false;
    }
  }

  /// Clears the session-load cache so the next
  /// [loadFromDeviceGlobalSettings] call reads the database again.
  @visibleForTesting
  static void debugResetSessionLoad() {
    _sessionLoad = null;
    verboseEnabled = false;
  }

  /// Marks the session load as already resolved at [verbose] so the banner
  /// path skips the device-global database open entirely. Tests that exercise
  /// banner ordering must use this: the real read acquires a SQLite handle,
  /// whose latency is unbounded on a loaded machine, and the banner future
  /// they await would otherwise fail on timing rather than on behavior.
  @visibleForTesting
  static void debugPrimeSessionLoad({required bool verbose}) {
    verboseEnabled = verbose;
    _sessionLoad = Future<void>.value();
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
