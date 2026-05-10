/// Keys for [SettingsDao] key/value rows.
library;

abstract final class SettingsKeys {
  static const String apiBaseUrl = 'api.base_url';
  static const String prefsLocale = 'prefs.locale';
  static const String prefsLearningLanguage = 'prefs.learning_language';
  static const String prefsNativeLanguage = 'prefs.native_language';

  /// ISO-8601 cursor for incremental `updatedAfter` downloads.
  static const String syncCursorAudio = 'sync.cursor.audio';
  static const String syncCursorVideo = 'sync.cursor.video';
  static const String syncCursorRecording = 'sync.cursor.recording';

  /// Per-target recording pull (`sync.cursor.recording.{targetType}.{targetId}`).
  static String syncCursorRecordingTarget(String targetType, String targetId) =>
      'sync.cursor.recording.$targetType.$targetId';

  /// ISO-8601 UTC timestamp of last fully successful full sync (downloads + queue).
  static const String syncLastFullSyncAt = 'sync.last_full_sync_at';

  /// User dismissed the guest-data migration banner (`true` / absent).
  static const String migrationGuestDismissed = 'migration.guest_dismissed';
}

/// Default Enjoy API origin (no trailing slash).
const String kDefaultApiBaseUrl = 'https://enjoy.bot';
