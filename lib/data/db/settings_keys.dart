/// Keys for [SettingsDao] key/value rows.
library;

abstract final class SettingsKeys {
  static const String apiBaseUrl = 'api.base_url';

  /// Worker-hosted AI routes (OpenAI-compatible chat, ASR, translation, etc.).
  static const String apiAiBaseUrl = 'api.ai_base_url';
  static const String prefsLocale = 'prefs.locale';
  static const String prefsLearningLanguage = 'prefs.learning_language';
  static const String prefsNativeLanguage = 'prefs.native_language';

  /// Capture device id (`record` package `InputDevice.id`) for shadow-reading
  /// recordings. Empty / missing means "auto-pick the first non-virtual mic".
  static const String prefsRecordingInputDeviceId =
      'prefs.recording_input_device_id';

  /// ISO-8601 cursor for incremental `updatedAfter` downloads.
  static const String syncCursorAudio = 'sync.cursor.audio';
  static const String syncCursorVideo = 'sync.cursor.video';
  static const String syncCursorRecording = 'sync.cursor.recording';

  /// Per-target recording pull (`sync.cursor.recording.{targetType}.{targetId}`).
  static String syncCursorRecordingTarget(String targetType, String targetId) =>
      'sync.cursor.recording.$targetType.$targetId';

  /// ISO-8601 UTC timestamp of the last pull attempt for a given
  /// recording target, used as a cooldown to avoid hammering the
  /// server on every media open
  /// (`sync.last_pull_at.recording.{targetType}.{targetId}`).
  static String syncLastPullAtRecordingTarget(
    String targetType,
    String targetId,
  ) => 'sync.last_pull_at.recording.$targetType.$targetId';

  /// ISO-8601 UTC timestamp of last fully successful full sync (downloads + queue).
  static const String syncLastFullSyncAt = 'sync.last_full_sync_at';

  /// User dismissed the guest-data migration banner (`true` / absent).
  static const String migrationGuestDismissed = 'migration.guest_dismissed';

  /// ISO-8601 UTC timestamp of the last successful update feed check.
  static const String updateLastCheckAt = 'update.last_check_at';

  /// ISO-8601 UTC — do not show optional update prompts until this instant.
  static const String updateSnoozeUntil = 'update.snooze_until';

  /// Version string the user snoozed (optional updates only).
  static const String updateSnoozeVersion = 'update.snooze_version';

  /// When `true`, allowlisted diagnostic loggers write FINE records to the log file.
  static const String diagnosticsVerboseEnabled = 'diagnostics.verbose_enabled';
}

/// Default Enjoy API origin (no trailing slash).
const String kDefaultApiBaseUrl = 'https://enjoy.bot';

/// Default Enjoy Worker origin for AI endpoints (no trailing slash).
const String kDefaultAiApiBaseUrl = 'https://worker.enjoy.bot';
