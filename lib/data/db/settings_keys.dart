/// Keys for [SettingsDao] key/value rows.
library;

abstract final class SettingsKeys {
  static const String apiBaseUrl = 'api.base_url';
  static const String authLastProfile = 'auth.last_profile';
  static const String prefsThemeMode = 'prefs.theme_mode';
  static const String prefsLocale = 'prefs.locale';
  static const String prefsLearningLanguage = 'prefs.learning_language';
  static const String prefsNativeLanguage = 'prefs.native_language';

  /// ISO-8601 cursor for incremental `updatedAfter` downloads.
  static const String syncCursorAudio = 'sync.cursor.audio';
  static const String syncCursorVideo = 'sync.cursor.video';
  static const String syncCursorRecording = 'sync.cursor.recording';
}

/// Default Enjoy API origin (no trailing slash).
const String kDefaultApiBaseUrl = 'https://enjoy.bot';
