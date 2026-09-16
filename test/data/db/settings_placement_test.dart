/// Placement + typed-access tests for the settings registry
/// (`lib/data/db/settings_keys.dart` + `settings_schema.dart`).
///
/// The device-global vs per-user database rule used to live only in
/// convention (issue #722): reading the right key from the wrong database
/// silently returned `null`. These tests pin placement as data and prove the
/// DAO makes misplaced access loud.
library;

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/data/db/settings_keys.dart';

void main() {
  group('settings key placement (device vs user)', () {
    // Golden table — the encoded two-database rule. Update this table ONLY
    // together with the scope on the key declaration; the test fails on any
    // new key that forgets to decide its scope.
    const expectedScopes = <String, SettingsScope>{
      // Device-global: readable before sign-in, survives account switches.
      'api.base_url': SettingsScope.device,
      'api.ai_base_url': SettingsScope.device,
      'diagnostics.verbose_enabled': SettingsScope.device,
      'analytics.capture_enabled': SettingsScope.device,
      'transcript.karaokeHighlight': SettingsScope.device,
      'transcript.ipaOverlay': SettingsScope.device,
      'update.last_check_at': SettingsScope.device,
      'update.snooze_until': SettingsScope.device,
      'update.snooze_version': SettingsScope.device,
      // Per-user: follows the signed-in account.
      'prefs.locale': SettingsScope.user,
      'prefs.learning_language': SettingsScope.user,
      'prefs.native_language': SettingsScope.user,
      'prefs.theme_mode': SettingsScope.user,
      'prefs.recording_input_device_id': SettingsScope.user,
      'sync.cursor.audio': SettingsScope.user,
      'sync.cursor.video': SettingsScope.user,
      'sync.cursor.recording': SettingsScope.user,
      'sync.cursor.vocabulary_item': SettingsScope.user,
      'sync.cursor.vocabulary_context': SettingsScope.user,
      'sync.last_full_sync_at': SettingsScope.user,
      'player_preferences_v1': SettingsScope.user,
      'craft.preferences_v1': SettingsScope.user,
      'hotkeys_custom_bindings': SettingsScope.user,
      'ai.modality_configs_v1': SettingsScope.user,
      'onboarding.tip_progress_v1': SettingsScope.user,
    };

    test('every declared key has the expected scope', () {
      final declaredNames = SettingsKeys.declaredKeys
          .map((k) => k.name)
          .toSet();
      // No orphan expectations (a rename that forgets this table shows up
      // here, not as a silently-passing row).
      expect(expectedScopes.keys.toSet(), declaredNames);
      for (final key in SettingsKeys.declaredKeys) {
        expect(key.scope, expectedScopes[key.name], reason: key.name);
      }
    });

    test('every declared family has the expected scope', () {
      const expectedFamilyScopes = <String, SettingsScope>{
        'sync.cursor.recording.': SettingsScope.user,
        'sync.last_pull_at.recording.': SettingsScope.user,
        'asr.long_form.attempt.': SettingsScope.user,
        'onboarding.empty_transcript.': SettingsScope.user,
      };
      expect(
        SettingsKeys.declaredFamilies.map((f) => f.prefix).toSet(),
        expectedFamilyScopes.keys.toSet(),
      );
      for (final family in SettingsKeys.declaredFamilies) {
        expect(
          family.scope,
          expectedFamilyScopes[family.prefix],
          reason: family.prefix,
        );
      }
    });
  });

  group('SettingsDao typed access', () {
    late AppDatabase deviceDb;
    late AppDatabase userDb;

    setUp(() {
      deviceDb = AppDatabase(executor: NativeDatabase.memory());
      userDb = AppDatabase(
        executor: NativeDatabase.memory(),
        name: 'enjoy_player_test-user',
      );
    });

    tearDown(() async {
      await deviceDb.close();
      await userDb.close();
    });

    test(
      'reading a device-scoped key through the per-user DB throws',
      () async {
        // Previously this silently returned the default/null — the exact bug
        // class the placement assert exists to surface (issue #722).
        await expectLater(
          deviceDb.settingsDao.readSetting(SettingsKeys.apiBaseUrl),
          completes,
        );
        await expectLater(
          userDb.settingsDao.readSetting(SettingsKeys.apiBaseUrl),
          throwsStateError,
        );
        await expectLater(
          userDb.settingsDao.writeSetting(
            SettingsKeys.transcriptKaraokeHighlight,
            true,
          ),
          throwsStateError,
        );
      },
    );

    test(
      'reading a user-scoped key through a device-global-named DB warns but does not throw',
      () {
        // In-memory test DBs default to the device-global file name while
        // legitimately impersonating both roles, so this direction is
        // deliberately not fatal — documented on SettingsDao._assertPlacement.
        expect(
          deviceDb.settingsDao.readSetting(SettingsKeys.prefsLocale),
          completion(isNull),
        );
      },
    );

    test(
      'bool flag polarity: opt-out (analytics) stays on unless false',
      () async {
        expect(
          await deviceDb.settingsDao.readSetting(
            SettingsKeys.analyticsCaptureEnabled,
          ),
          isTrue,
        );
        await deviceDb.settingsDao.writeSetting(
          SettingsKeys.analyticsCaptureEnabled,
          false,
        );
        expect(
          await deviceDb.settingsDao.readSetting(
            SettingsKeys.analyticsCaptureEnabled,
          ),
          isFalse,
        );
        // Legacy/garbage values cannot silently flip a documented opt-out.
        await deviceDb.settingsDao.setValue(
          SettingsKeys.analyticsCaptureEnabled.name,
          'yes',
        );
        expect(
          await deviceDb.settingsDao.readSetting(
            SettingsKeys.analyticsCaptureEnabled,
          ),
          isTrue,
        );
      },
    );

    test(
      'bool flag polarity: opt-in (karaoke) stays off unless true',
      () async {
        expect(
          await deviceDb.settingsDao.readSetting(
            SettingsKeys.transcriptKaraokeHighlight,
          ),
          isFalse,
        );
        await deviceDb.settingsDao.setValue(
          SettingsKeys.transcriptKaraokeHighlight.name,
          'true',
        );
        expect(
          await deviceDb.settingsDao.readSetting(
            SettingsKeys.transcriptKaraokeHighlight,
          ),
          isTrue,
        );
        await deviceDb.settingsDao.setValue(
          SettingsKeys.transcriptKaraokeHighlight.name,
          'anything-else',
        );
        expect(
          await deviceDb.settingsDao.readSetting(
            SettingsKeys.transcriptKaraokeHighlight,
          ),
          isFalse,
        );
      },
    );

    test('string codec round-trips and applies the declared default', () async {
      expect(
        await deviceDb.settingsDao.readSetting(SettingsKeys.apiBaseUrl),
        kDefaultApiBaseUrl,
      );
      await deviceDb.settingsDao.writeSetting(
        SettingsKeys.apiBaseUrl,
        'https://staging.example.test',
      );
      expect(
        await deviceDb.settingsDao.readSetting(SettingsKeys.apiBaseUrl),
        'https://staging.example.test',
      );
    });

    test('iso date-time codec round-trips and nulls garbage', () async {
      final at = DateTime.utc(2026, 9, 16, 8, 30);
      await deviceDb.settingsDao.writeSetting(
        SettingsKeys.updateSnoozeUntil,
        at,
      );
      final read = await deviceDb.settingsDao.readSetting(
        SettingsKeys.updateSnoozeUntil,
      );
      expect(read, at);
      expect(
        await deviceDb.settingsDao.readSetting(SettingsKeys.updateLastCheckAt),
        isNull,
      );
      await deviceDb.settingsDao.setValue(
        SettingsKeys.updateLastCheckAt.name,
        'not-a-date',
      );
      expect(
        await deviceDb.settingsDao.readSetting(SettingsKeys.updateLastCheckAt),
        isNull,
      );
    });

    test('json codec round-trips and throws on corrupt rows', () async {
      const value = <String, dynamic>{'volume': 0.5, 'rate': 1.2};
      await userDb.settingsDao.writeSetting(
        SettingsKeys.playerPreferencesV1,
        value,
      );
      expect(
        await userDb.settingsDao.readSetting(SettingsKeys.playerPreferencesV1),
        value,
      );
      await userDb.settingsDao.setValue(
        SettingsKeys.playerPreferencesV1.name,
        '{not json',
      );
      // Corrupt blobs throw; consumers (player prefs hydrate) catch this and
      // fall back to defaults — same contract as the inline jsonDecode.
      await expectLater(
        userDb.settingsDao.readSetting(SettingsKeys.playerPreferencesV1),
        throwsFormatException,
      );
    });

    test('typed delete removes the row', () async {
      await deviceDb.settingsDao.writeSetting(
        SettingsKeys.apiAiBaseUrl,
        'https://example.test',
      );
      await deviceDb.settingsDao.deleteSetting(SettingsKeys.apiAiBaseUrl);
      expect(
        await deviceDb.settingsDao.readSetting(SettingsKeys.apiAiBaseUrl),
        kDefaultAiApiBaseUrl,
      );
    });

    test('family keys are typed, known, and placement-checked', () async {
      final cursor = SettingsKeys.syncCursorRecordingTargets.keyFor(
        'Video.m-1',
      );
      await userDb.settingsDao.writeSetting(cursor, '2026-01-01T00:00:00Z');
      expect(
        await userDb.settingsDao.readSetting(cursor),
        '2026-01-01T00:00:00Z',
      );
      expect(SettingsKeys.isKnown(cursor.name), isTrue);
      // The cooldown family decodes as date-time.
      final cooldown = SettingsKeys.syncLastPullAtRecordingTargets.keyFor(
        'Video.m-1',
      );
      await userDb.settingsDao.writeSetting(cooldown, DateTime.utc(2026, 1, 1));
      expect(
        await userDb.settingsDao.readSetting(cooldown),
        DateTime.utc(2026, 1, 1),
      );
    });
  });

  group('settingsDatabaseFor', () {
    test('picks the database from the key scope', () {
      final deviceDb = AppDatabase(executor: NativeDatabase.memory());
      final userDb = AppDatabase(
        executor: NativeDatabase.memory(),
        name: 'enjoy_player_test-user',
      );
      addTearDown(deviceDb.close);
      addTearDown(userDb.close);

      final deviceProbe = Provider<AppDatabase>(
        (ref) => settingsDatabaseFor(ref, SettingsKeys.apiBaseUrl),
      );
      final userProbe = Provider<AppDatabase>(
        (ref) => settingsDatabaseFor(ref, SettingsKeys.prefsLocale),
      );

      final container = ProviderContainer(
        overrides: [
          deviceGlobalAppDatabaseProvider.overrideWithValue(deviceDb),
          appDatabaseProvider.overrideWithValue(userDb),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(deviceProbe), same(deviceDb));
      expect(container.read(userProbe), same(userDb));
    });
  });
}
