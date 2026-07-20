import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/settings_keys.dart';
import 'package:enjoy_player/features/asr/data/asr_long_form_attempt_store.dart';
import 'package:enjoy_player/features/asr/domain/asr_long_form_models.dart';

void main() {
  late AppDatabase db;
  late AsrLongFormAttemptStore store;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    store = AsrLongFormAttemptStore(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('save/load/clear round-trip', () async {
    final started = DateTime.utc(2026, 7, 19, 10);
    final attempt = AsrLongFormAttempt(
      mediaId: 'audio-long',
      idempotencyKey: 'idem-1',
      declaredDurationSeconds: 900,
      startedAt: started,
      jobId: 'job-1',
      language: 'en',
      mediaReference: 'ref-abc',
    );

    await store.save(attempt);
    final loaded = await store.load('audio-long');
    expect(loaded, isNotNull);
    expect(loaded!.mediaId, 'audio-long');
    expect(loaded.idempotencyKey, 'idem-1');
    expect(loaded.jobId, 'job-1');
    expect(loaded.language, 'en');
    expect(loaded.mediaReference, 'ref-abc');
    expect(loaded.declaredDurationSeconds, 900);
    expect(loaded.startedAt.toUtc(), started);

    await store.clear('audio-long');
    expect(await store.load('audio-long'), isNull);
  });

  test('load returns null for missing or corrupt payload', () async {
    expect(await store.load('missing'), isNull);

    await db.settingsDao.setValue(
      SettingsKeys.asrLongFormAttempt('bad'),
      '{not-json',
    );
    expect(await store.load('bad'), isNull);
  });
}
