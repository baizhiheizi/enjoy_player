import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/settings_keys.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AppDatabase can insert and read audio', () async {
    final db = AppDatabase(executor: NativeDatabase.memory());
    addTearDown(db.close);

    final now = DateTime.now();
    const id = 'test-id';
    await db.audioDao.insertRow(
      AudioRow(
        id: id,
        aid: 'abc',
        provider: 'user',
        title: 'Test',
        description: null,
        thumbnailUrl: null,
        durationSeconds: 0,
        language: 'en',
        translationKey: null,
        sourceText: null,
        voice: null,
        source: null,
        localUri: 'file:///tmp/x.mp3',
        md5: 'abc',
        size: 1,
        mediaUrl: null,
        syncStatus: null,
        serverUpdatedAt: null,
        createdAt: now,
        updatedAt: now,
      ),
    );

    final row = await db.audioDao.getById(id);
    expect(row, isNotNull);
    expect(row!.title, 'Test');
  });

  test('SettingsDao rejects unknown keys in debug mode', () async {
    final db = AppDatabase(executor: NativeDatabase.memory());
    addTearDown(db.close);

    expect(
      () => db.settingsDao.setValue('loacle', 'en'),
      throwsA(isA<StateError>()),
    );
  });

  test('SettingsKeys recognizes dynamic recording cursor keys', () {
    expect(
      SettingsKeys.isKnown(
        SettingsKeys.syncCursorRecordingTarget('Video', 'abc'),
      ),
      isTrue,
    );
    expect(
      SettingsKeys.isKnown(
        SettingsKeys.syncLastPullAtRecordingTarget('Audio', 'xyz'),
      ),
      isTrue,
    );
    expect(SettingsKeys.isKnown('totally.unknown.key'), isFalse);
  });
}
