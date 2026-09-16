import 'package:enjoy_player/data/db/settings_keys.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every declared static key, in one list, so the invariants below cover the
/// whole registry. (The old per-constant `expect(c, 'literal')` tests only
/// restated the declaration; these checks instead pin cross-consistency.)
const _allStaticKeys = <String>[
  SettingsKeys.apiBaseUrl,
  SettingsKeys.apiAiBaseUrl,
  SettingsKeys.prefsLocale,
  SettingsKeys.prefsLearningLanguage,
  SettingsKeys.prefsNativeLanguage,
  SettingsKeys.prefsThemeMode,
  SettingsKeys.prefsRecordingInputDeviceId,
  SettingsKeys.syncCursorAudio,
  SettingsKeys.syncCursorVideo,
  SettingsKeys.syncCursorRecording,
  SettingsKeys.syncCursorVocabularyItem,
  SettingsKeys.syncCursorVocabularyContext,
  SettingsKeys.syncLastFullSyncAt,
  SettingsKeys.updateLastCheckAt,
  SettingsKeys.updateSnoozeUntil,
  SettingsKeys.updateSnoozeVersion,
  SettingsKeys.diagnosticsVerboseEnabled,
  SettingsKeys.analyticsCaptureEnabled,
  SettingsKeys.transcriptKaraokeHighlight,
  SettingsKeys.transcriptIpaOverlay,
  SettingsKeys.playerPreferencesV1,
  SettingsKeys.craftPreferencesV1,
  SettingsKeys.hotkeysCustomBindings,
  SettingsKeys.aiModalityConfigsV1,
  SettingsKeys.onboardingTipProgressV1,
];

/// Key families (dotted prefixes, or the legacy snake_case blobs). Every
/// declared key must belong to one — a key outside all families is usually a
/// typo or a stray declaration nobody owns.
const _knownFamilies = [
  'api.',
  'prefs.',
  'sync.',
  'update.',
  'diagnostics.',
  'analytics.',
  'transcript.',
  'player_',
  'craft.',
  'hotkeys_',
  'ai.',
  'onboarding.',
];

void main() {
  group('SettingsKeys static constants (behavioral invariants)', () {
    test('every declared key is unique', () {
      expect(_allStaticKeys.toSet().length, _allStaticKeys.length);
    });

    test('every declared key belongs to a known family', () {
      for (final key in _allStaticKeys) {
        expect(
          _knownFamilies.any((f) => key.startsWith(f)),
          isTrue,
          reason:
              '$key does not start with any known settings family '
              '($_knownFamilies)',
        );
      }
    });

    test('every declared constant is recognized by isKnown', () {
      // Catches adding a constant to [SettingsKeys] without registering it
      // in the known-key set.
      for (final key in _allStaticKeys) {
        expect(SettingsKeys.isKnown(key), isTrue, reason: 'key: $key');
      }
    });

    test('near-miss mutations of declared keys are unknown', () {
      // Exact-match knowledge: a declared name plus any suffix must not be
      // accepted — except [SettingsKeys.syncCursorRecording], which is the
      // declared root of the dynamic sync.cursor.recording.* family.
      const familyRoots = {SettingsKeys.syncCursorRecording};
      for (final key in _allStaticKeys.where((k) => !familyRoots.contains(k))) {
        expect(SettingsKeys.isKnown('$key.x'), isFalse, reason: 'key: $key');
      }
    });
  });

  group('SettingsKeys dynamic helpers', () {
    test('recording-target cursors are distinct per target and known', () {
      final a = SettingsKeys.syncCursorRecordingTarget('Video', 'm-1');
      final b = SettingsKeys.syncCursorRecordingTarget('Video', 'm-2');
      final c = SettingsKeys.syncCursorRecordingTarget('Audio', 'm-1');
      expect(a, isNot(b));
      expect(a, isNot(c));
      expect(SettingsKeys.isKnown(a), isTrue);
      expect(SettingsKeys.isKnown(b), isTrue);
      expect(SettingsKeys.isKnown(c), isTrue);
    });

    test('last-pull cooldown keys are distinct per target and known', () {
      final a = SettingsKeys.syncLastPullAtRecordingTarget('Video', 'm-1');
      final b = SettingsKeys.syncLastPullAtRecordingTarget('Audio', 'm-1');
      expect(a, isNot(b));
      expect(SettingsKeys.isKnown(a), isTrue);
      expect(SettingsKeys.isKnown(b), isTrue);
      // Cursor and cooldown families never collide for the same target.
      expect(a, isNot(SettingsKeys.syncCursorRecordingTarget('Video', 'm-1')));
    });

    test('asr long-form attempt keys are distinct per media and known', () {
      final a = SettingsKeys.asrLongFormAttempt('m-1');
      final b = SettingsKeys.asrLongFormAttempt('m-2');
      expect(a, isNot(b));
      expect(SettingsKeys.isKnown(a), isTrue);
      expect(SettingsKeys.isKnown(b), isTrue);
    });
  });

  group('SettingsKeys.isKnown', () {
    test('recognizes every static key as known', () {
      const staticKeys = <String>[
        SettingsKeys.apiBaseUrl,
        SettingsKeys.apiAiBaseUrl,
        SettingsKeys.prefsLocale,
        SettingsKeys.prefsLearningLanguage,
        SettingsKeys.prefsNativeLanguage,
        SettingsKeys.prefsRecordingInputDeviceId,
        SettingsKeys.syncCursorAudio,
        SettingsKeys.syncCursorVideo,
        SettingsKeys.syncCursorRecording,
        SettingsKeys.syncCursorVocabularyItem,
        SettingsKeys.syncCursorVocabularyContext,
        SettingsKeys.syncLastFullSyncAt,
        SettingsKeys.updateLastCheckAt,
        SettingsKeys.updateSnoozeUntil,
        SettingsKeys.updateSnoozeVersion,
        SettingsKeys.diagnosticsVerboseEnabled,
        SettingsKeys.transcriptKaraokeHighlight,
        SettingsKeys.transcriptIpaOverlay,
        SettingsKeys.playerPreferencesV1,
        SettingsKeys.craftPreferencesV1,
        SettingsKeys.hotkeysCustomBindings,
        SettingsKeys.aiModalityConfigsV1,
        SettingsKeys.onboardingTipProgressV1,
      ];
      for (final k in staticKeys) {
        expect(SettingsKeys.isKnown(k), isTrue, reason: 'key: $k');
      }
    });

    test('recognizes sync.cursor.recording.*', () {
      expect(
        SettingsKeys.isKnown(
          SettingsKeys.syncCursorRecordingTarget('Video', 'x'),
        ),
        isTrue,
      );
      expect(
        SettingsKeys.isKnown(
          SettingsKeys.syncCursorRecordingTarget('Audio', 'y'),
        ),
        isTrue,
      );
    });

    test('recognizes sync.last_pull_at.recording.*', () {
      expect(
        SettingsKeys.isKnown(
          SettingsKeys.syncLastPullAtRecordingTarget('Video', 'x'),
        ),
        isTrue,
      );
    });

    test('recognizes asr.long_form.attempt.*', () {
      expect(
        SettingsKeys.isKnown(SettingsKeys.asrLongFormAttempt('m-1')),
        isTrue,
      );
    });

    test('returns false for unknown keys', () {
      expect(SettingsKeys.isKnown('not.a.key'), isFalse);
      expect(SettingsKeys.isKnown('sync.cursor.video.extra'), isFalse);
      expect(SettingsKeys.isKnown('asr.short.attempt.x'), isFalse);
      expect(SettingsKeys.isKnown(''), isFalse);
    });

    test('does NOT match sync.cursor.video with extra suffix', () {
      // Only the recording prefix family is dynamic; video / audio cursors
      // are static and don't open a sub-tree.
      expect(SettingsKeys.isKnown('sync.cursor.video.foo'), isFalse);
      expect(SettingsKeys.isKnown('sync.cursor.audio.foo'), isFalse);
    });
  });

  group('default api origins', () {
    test('kDefaultApiBaseUrl / kDefaultAiApiBaseUrl are stable URLs', () {
      expect(kDefaultApiBaseUrl, 'https://enjoy.bot');
      expect(kDefaultAiApiBaseUrl, 'https://worker.enjoy.bot');
      expect(kDefaultApiBaseUrl.endsWith('/'), isFalse);
      expect(kDefaultAiApiBaseUrl.endsWith('/'), isFalse);
    });
  });
}
