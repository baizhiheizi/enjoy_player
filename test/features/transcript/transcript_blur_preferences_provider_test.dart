import 'dart:async';

import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/data/db/settings_keys.dart';
import 'package:enjoy_player/features/transcript/application/transcript_blur_preferences_provider.dart';
import 'package:enjoy_player/features/transcript/domain/transcript_blur.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TranscriptBlurPreferencesCtrl', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() {
      db = AppDatabase(executor: NativeDatabase.memory());
      container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    Future<TranscriptBlurPreferences> read() {
      return container.read(transcriptBlurPreferencesCtrlProvider.future);
    }

    test('hydrates with defaults when settings row is missing', () async {
      final prefs = await read();
      expect(prefs.enabled, isFalse);
      expect(
        prefs.tapRevealSeconds,
        TranscriptBlurPreferences.tapRevealSecondsDefault,
      );
    });

    test('hydrates with stored enabled=true', () async {
      await db.settingsDao.setValue(
        SettingsKeys.prefsTranscriptBlurPracticeEnabled,
        'true',
      );
      final prefs = await read();
      expect(prefs.enabled, isTrue);
    });

    test('hydrates with stored seconds, validating the range', () async {
      await db.settingsDao.setValue(
        SettingsKeys.prefsTranscriptBlurTapRevealSeconds,
        '7',
      );
      final prefs = await read();
      expect(prefs.tapRevealSeconds, 7);
    });

    test('clamps a stored seconds value above the max', () async {
      await db.settingsDao.setValue(
        SettingsKeys.prefsTranscriptBlurTapRevealSeconds,
        '99',
      );
      final prefs = await read();
      expect(
        prefs.tapRevealSeconds,
        TranscriptBlurPreferences.tapRevealSecondsMax,
      );
    });

    test('falls back to defaults when stored seconds is unparseable', () async {
      await db.settingsDao.setValue(
        SettingsKeys.prefsTranscriptBlurTapRevealSeconds,
        'abc',
      );
      final prefs = await read();
      expect(
        prefs.tapRevealSeconds,
        TranscriptBlurPreferences.tapRevealSecondsDefault,
      );
    });

    test('falls back to disabled when stored enabled is unparseable', () async {
      await db.settingsDao.setValue(
        SettingsKeys.prefsTranscriptBlurPracticeEnabled,
        'maybe',
      );
      final prefs = await read();
      expect(prefs.enabled, isFalse);
    });

    test('setEnabled persists and updates state', () async {
      await read(); // ensure build() has completed before mutating
      await container
          .read(transcriptBlurPreferencesCtrlProvider.notifier)
          .setEnabled(true);
      final stored = await db.settingsDao.getValue(
        SettingsKeys.prefsTranscriptBlurPracticeEnabled,
      );
      expect(stored, 'true');
      final prefs = await read();
      expect(prefs.enabled, isTrue);
    });

    test('setEnabled is idempotent', () async {
      await read(); // ensure build() has completed before mutating
      final ctrl = container.read(
        transcriptBlurPreferencesCtrlProvider.notifier,
      );
      await ctrl.setEnabled(true);
      await ctrl.setEnabled(true);
      final prefs = await read();
      expect(prefs.enabled, isTrue);
    });

    test('setTapRevealSeconds persists and clamps', () async {
      await read(); // ensure build() has completed before mutating
      final ctrl = container.read(
        transcriptBlurPreferencesCtrlProvider.notifier,
      );
      await ctrl.setTapRevealSeconds(5);
      var stored = await db.settingsDao.getValue(
        SettingsKeys.prefsTranscriptBlurTapRevealSeconds,
      );
      expect(stored, '5');

      await ctrl.setTapRevealSeconds(99);
      stored = await db.settingsDao.getValue(
        SettingsKeys.prefsTranscriptBlurTapRevealSeconds,
      );
      expect(stored, TranscriptBlurPreferences.tapRevealSecondsMax.toString());
    });

    test('read-only projection defaults when the ctrl is still loading', () {
      final c = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          transcriptBlurPreferencesCtrlProvider.overrideWith(
            _NeverCompletingCtrl.new,
          ),
        ],
      );
      addTearDown(c.dispose);
      final projected = c.read(transcriptBlurPreferencesProvider);
      expect(projected, TranscriptBlurPreferences.defaults);
    });
  });
}

class _NeverCompletingCtrl extends TranscriptBlurPreferencesCtrl {
  @override
  Future<TranscriptBlurPreferences> build() {
    return Completer<TranscriptBlurPreferences>().future;
  }
}
