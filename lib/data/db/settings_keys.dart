/// The typed settings registry for [SettingsDao] key/value rows.
///
/// Every key is a [SettingKey] (or a [SettingKeyFamily] for dynamic
/// per-target keys) declaring its storage [SettingsScope], [SettingCodec],
/// and default, so key placement (device-global vs per-user database) and
/// parsing live in one place instead of in per-feature provider+parser
/// copies. See `settings_schema.dart` for the machinery.
library;

import 'settings_schema.dart';

export 'settings_schema.dart';

abstract final class SettingsKeys {
  // ---------------------------------------------------------------- device --

  static const apiBaseUrl = SettingKey<String>(
    name: 'api.base_url',
    scope: SettingsScope.device,
    codec: StringSettingCodec(),
    defaultValue: kDefaultApiBaseUrl,
  );

  /// Worker-hosted AI routes (OpenAI-compatible chat, ASR, translation, etc.).
  static const apiAiBaseUrl = SettingKey<String>(
    name: 'api.ai_base_url',
    scope: SettingsScope.device,
    codec: StringSettingCodec(),
    defaultValue: kDefaultAiApiBaseUrl,
  );

  /// When `true`, allowlisted diagnostic loggers write FINE records to the
  /// log file. Missing value ≡ off.
  static final diagnosticsVerboseEnabled = SettingKey.flag(
    name: 'diagnostics.verbose_enabled',
    scope: SettingsScope.device,
    whenMissing: false,
  );

  /// When `false`, all product analytics capture stops immediately (spec
  /// 046). Device-global — covers anonymous pre-sign-in events and survives
  /// sign-out. Missing value ≡ `true` (capture on, visible opt-out).
  static final analyticsCaptureEnabled = SettingKey.flag(
    name: 'analytics.capture_enabled',
    scope: SettingsScope.device,
    whenMissing: true,
  );

  /// When `true`, the transcript panel highlights the current word if the cue
  /// already has stored word timings. Missing value ≡ off.
  static final transcriptKaraokeHighlight = SettingKey.flag(
    name: 'transcript.karaokeHighlight',
    scope: SettingsScope.device,
    whenMissing: false,
  );

  /// When `true`, show stored pronunciation spelling with each primary-line
  /// word that has phone pieces. Missing value ≡ off.
  static final transcriptIpaOverlay = SettingKey.flag(
    name: 'transcript.ipaOverlay',
    scope: SettingsScope.device,
    whenMissing: false,
  );

  /// ISO-8601 UTC timestamp of the last successful update feed check.
  static const updateLastCheckAt = SettingKey<DateTime?>(
    name: 'update.last_check_at',
    scope: SettingsScope.device,
    codec: IsoDateTimeSettingCodec(),
    defaultValue: null,
  );

  /// ISO-8601 UTC — do not show optional update prompts until this instant.
  static const updateSnoozeUntil = SettingKey<DateTime?>(
    name: 'update.snooze_until',
    scope: SettingsScope.device,
    codec: IsoDateTimeSettingCodec(),
    defaultValue: null,
  );

  /// Version string the user snoozed (optional updates only).
  static const updateSnoozeVersion = SettingKey<String?>(
    name: 'update.snooze_version',
    scope: SettingsScope.device,
    codec: StringSettingCodec(),
    defaultValue: null,
  );

  // ------------------------------------------------------------------ user --

  /// Display locale tag. Nullable: missing lets [AppPreferencesCtrl]
  /// canonicalize and persist the platform default on first read.
  static const prefsLocale = SettingKey<String?>(
    name: 'prefs.locale',
    scope: SettingsScope.user,
    codec: StringSettingCodec(),
    defaultValue: null,
  );

  static const prefsLearningLanguage = SettingKey<String?>(
    name: 'prefs.learning_language',
    scope: SettingsScope.user,
    codec: StringSettingCodec(),
    defaultValue: null,
  );

  static const prefsNativeLanguage = SettingKey<String?>(
    name: 'prefs.native_language',
    scope: SettingsScope.user,
    codec: StringSettingCodec(),
    defaultValue: null,
  );

  /// Appearance: `system` | `light` | `dark`. Missing ≡ system. Stored as a
  /// string (not an enum codec) because [ThemeMode] is a Flutter type and
  /// this registry stays Flutter-free; [AppPreferencesCtrl] maps it.
  static const prefsThemeMode = SettingKey<String?>(
    name: 'prefs.theme_mode',
    scope: SettingsScope.user,
    codec: StringSettingCodec(),
    defaultValue: null,
  );

  /// Capture device id (`record` package `InputDevice.id`) for shadow-reading
  /// recordings. Empty / missing means "auto-pick the first non-virtual mic".
  static const prefsRecordingInputDeviceId = SettingKey<String?>(
    name: 'prefs.recording_input_device_id',
    scope: SettingsScope.user,
    codec: StringSettingCodec(),
    defaultValue: null,
  );

  /// ISO-8601 cursor for incremental `updatedAfter` downloads.
  static const syncCursorAudio = SettingKey<String?>(
    name: 'sync.cursor.audio',
    scope: SettingsScope.user,
    codec: StringSettingCodec(),
    defaultValue: null,
  );

  /// ISO-8601 cursor for incremental `updatedAfter` downloads.
  static const syncCursorVideo = SettingKey<String?>(
    name: 'sync.cursor.video',
    scope: SettingsScope.user,
    codec: StringSettingCodec(),
    defaultValue: null,
  );

  /// ISO-8601 cursor for incremental recording downloads. Also the root of
  /// the [syncCursorRecordingTargets] family.
  static const syncCursorRecording = SettingKey<String?>(
    name: 'sync.cursor.recording',
    scope: SettingsScope.user,
    codec: StringSettingCodec(),
    defaultValue: null,
  );

  /// ISO-8601 cursors for incremental vocabulary `updatedAfter` downloads.
  static const syncCursorVocabularyItem = SettingKey<String?>(
    name: 'sync.cursor.vocabulary_item',
    scope: SettingsScope.user,
    codec: StringSettingCodec(),
    defaultValue: null,
  );

  /// ISO-8601 cursors for incremental vocabulary `updatedAfter` downloads.
  static const syncCursorVocabularyContext = SettingKey<String?>(
    name: 'sync.cursor.vocabulary_context',
    scope: SettingsScope.user,
    codec: StringSettingCodec(),
    defaultValue: null,
  );

  /// ISO-8601 UTC timestamp of last fully successful full sync (downloads +
  /// queue). Kept a raw string: the sync status UI parses it for display.
  static const syncLastFullSyncAt = SettingKey<String?>(
    name: 'sync.last_full_sync_at',
    scope: SettingsScope.user,
    codec: StringSettingCodec(),
    defaultValue: null,
  );

  /// JSON blob: volume, rate, repeat, split width ([PlayerPreferencesCtrl]
  /// owns the [PlayerPreferences] mapping).
  static const playerPreferencesV1 = SettingKey<Map<String, dynamic>?>(
    name: 'player_preferences_v1',
    scope: SettingsScope.user,
    codec: JsonObjectSettingCodec(),
    defaultValue: null,
  );

  /// JSON blob: remembered Craft options — screen mode, per-mode translation
  /// style, custom prompt, per-language voice map ([CraftPreferencesCtrl]
  /// owns the [CraftPreferences] mapping).
  static const craftPreferencesV1 = SettingKey<Map<String, dynamic>?>(
    name: 'craft.preferences_v1',
    scope: SettingsScope.user,
    codec: JsonObjectSettingCodec(),
    defaultValue: null,
  );

  /// JSON map of custom hotkey action id → binding string ([HotkeysCtrl]
  /// validates entries against the hotkey definitions).
  static const hotkeysCustomBindings = SettingKey<Map<String, dynamic>?>(
    name: 'hotkeys_custom_bindings',
    scope: SettingsScope.user,
    codec: JsonObjectSettingCodec(),
    defaultValue: null,
  );

  /// JSON blob: per-modality AI provider config (BYOK non-secrets only).
  static const aiModalityConfigsV1 = SettingKey<Map<String, dynamic>?>(
    name: 'ai.modality_configs_v1',
    scope: SettingsScope.user,
    codec: JsonObjectSettingCodec(),
    defaultValue: null,
  );

  /// JSON map of global onboarding tip id → completed|skipped.
  static const onboardingTipProgressV1 = SettingKey<String?>(
    name: 'onboarding.tip_progress_v1',
    scope: SettingsScope.user,
    codec: StringSettingCodec(),
    defaultValue: null,
  );

  // ------------------------------------------------------- dynamic families --

  /// Per-target recording pull cursors
  /// (`sync.cursor.recording.{targetType}.{targetId}`).
  static const syncCursorRecordingTargets = SettingKeyFamily<String?>(
    prefix: 'sync.cursor.recording.',
    scope: SettingsScope.user,
    codec: StringSettingCodec(),
    defaultValue: null,
  );

  /// ISO-8601 UTC timestamp of the last pull attempt for a given recording
  /// target, used as a cooldown to avoid hammering the server on every media
  /// open (`sync.last_pull_at.recording.{targetType}.{targetId}`).
  static const syncLastPullAtRecordingTargets = SettingKeyFamily<DateTime?>(
    prefix: 'sync.last_pull_at.recording.',
    scope: SettingsScope.user,
    codec: IsoDateTimeSettingCodec(),
    defaultValue: null,
  );

  /// In-flight Enjoy long-form ASR attempt JSON per [mediaId]
  /// (`asr.long_form.attempt.{mediaId}`).
  static const asrLongFormAttempts = SettingKeyFamily<Map<String, dynamic>?>(
    prefix: 'asr.long_form.attempt.',
    scope: SettingsScope.user,
    codec: JsonObjectSettingCodec(),
    defaultValue: null,
  );

  /// Per-media empty-transcript tip resolution (`completed`|`skipped`) —
  /// `onboarding.empty_transcript.{mediaId}`. The only family whose rows may
  /// be bulk-deleted (onboarding reset).
  static const onboardingEmptyTranscripts = SettingKeyFamily<String?>(
    prefix: 'onboarding.empty_transcript.',
    scope: SettingsScope.user,
    codec: StringSettingCodec(),
    defaultValue: null,
    allowPrefixDelete: true,
  );

  // ------------------------------------------------------------ dynamic keys --

  /// Per-target recording pull cursor (`sync.cursor.recording.{type}.{id}`).
  static String syncCursorRecordingTarget(String targetType, String targetId) =>
      syncCursorRecordingTargets.keyFor('$targetType.$targetId').name;

  /// Per-target recording pull cooldown timestamp
  /// (`sync.last_pull_at.recording.{type}.{id}`).
  static String syncLastPullAtRecordingTarget(
    String targetType,
    String targetId,
  ) => syncLastPullAtRecordingTargets.keyFor('$targetType.$targetId').name;

  /// In-flight long-form ASR attempt JSON for [mediaId].
  static String asrLongFormAttempt(String mediaId) =>
      asrLongFormAttempts.keyFor(mediaId).name;

  /// Per-media empty-transcript tip resolution for [mediaId].
  static String onboardingEmptyTranscript(String mediaId) =>
      onboardingEmptyTranscripts.keyFor(mediaId).name;

  /// Prefix for [onboardingEmptyTranscript] keys.
  static String get onboardingEmptyTranscriptPrefix =>
      onboardingEmptyTranscripts.prefix;

  // -------------------------------------------------------------- registry --

  /// Every declared static key — the single source for [isKnown] and for the
  /// placement table test.
  static final List<SettingKey<dynamic>> declaredKeys = [
    apiBaseUrl,
    apiAiBaseUrl,
    diagnosticsVerboseEnabled,
    analyticsCaptureEnabled,
    transcriptKaraokeHighlight,
    transcriptIpaOverlay,
    updateLastCheckAt,
    updateSnoozeUntil,
    updateSnoozeVersion,
    prefsLocale,
    prefsLearningLanguage,
    prefsNativeLanguage,
    prefsThemeMode,
    prefsRecordingInputDeviceId,
    syncCursorAudio,
    syncCursorVideo,
    syncCursorRecording,
    syncCursorVocabularyItem,
    syncCursorVocabularyContext,
    syncLastFullSyncAt,
    playerPreferencesV1,
    craftPreferencesV1,
    hotkeysCustomBindings,
    aiModalityConfigsV1,
    onboardingTipProgressV1,
  ];

  /// Every declared dynamic key family.
  static const List<SettingKeyFamily<dynamic>> declaredFamilies = [
    syncCursorRecordingTargets,
    syncLastPullAtRecordingTargets,
    asrLongFormAttempts,
    onboardingEmptyTranscripts,
  ];

  static final Set<String> _declaredKeyNames = {
    for (final key in declaredKeys) key.name,
  };

  /// Whether [key] is a known static or dynamic settings key.
  static bool isKnown(String key) =>
      _declaredKeyNames.contains(key) ||
      declaredFamilies.any((family) => family.matches(key));
}

/// Default Enjoy API origin (no trailing slash).
const String kDefaultApiBaseUrl = 'https://enjoy.bot';

/// Default Enjoy Worker origin for AI endpoints (no trailing slash).
const String kDefaultAiApiBaseUrl = 'https://worker.enjoy.bot';
