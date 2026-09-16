/// Tests for the unified fetch-once gate on [TranscriptRepository]
/// (issue #718, step 5).
///
/// Pins the single-owner predicate: the controller's `_alreadyCloudFetched`
/// and `_hydrateFromPersisted` now ask the repo instead of repeating the
/// `dexieTargetTypeForId` + `transcriptFetchStateDao.getForTarget` round-trip
/// and the `lastStatus != 'error'` rule.
library;

import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/features/transcript/data/transcript_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TranscriptRepository fetch gate (single owner)', () {
    late AppDatabase db;
    late TranscriptRepository repo;

    setUp(() {
      db = AppDatabase(executor: NativeDatabase.memory());
      repo = TranscriptRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('unknown mediaId is not skippable and has no state', () async {
      expect(await repo.isCloudFetchSkippable('orphan'), isFalse);
      expect(await repo.readCloudFetchState('orphan'), isNull);
    });

    test(
      'no persisted row is not skippable (next open should fetch)',
      () async {
        // dexieTargetTypeForId only resolves known mediaIds — insert a video.
        final now = DateTime.utc(2026, 9, 16);
        await db.videoDao.insertRow(
          VideoRow(
            id: 'v-1',
            vid: 'v-1',
            provider: 'user',
            title: 't',
            description: null,
            thumbnailUrl: null,
            durationSeconds: 0,
            language: 'en',
            source: null,
            localUri: null,
            md5: null,
            size: 0,
            mediaUrl: null,
            syncStatus: null,
            serverUpdatedAt: null,
            createdAt: now,
            updatedAt: now,
          ),
        );
        expect(await repo.isCloudFetchSkippable('v-1'), isFalse);
        expect(await repo.readCloudFetchState('v-1'), isNull);
      },
    );

    test(
      'persisted lastStatus=success is skippable; error allows retry',
      () async {
        final now = DateTime.utc(2026, 9, 16);
        await db.videoDao.insertRow(
          VideoRow(
            id: 'v-1',
            vid: 'v-1',
            provider: 'user',
            title: 't',
            description: null,
            thumbnailUrl: null,
            durationSeconds: 0,
            language: 'en',
            source: null,
            localUri: null,
            md5: null,
            size: 0,
            mediaUrl: null,
            syncStatus: null,
            serverUpdatedAt: null,
            createdAt: now,
            updatedAt: now,
          ),
        );

        await db.transcriptFetchStateDao.upsertOutcome(
          targetType: 'Video',
          targetId: 'v-1',
          lastFetchedAt: now,
          lastStatus: 'success',
        );
        expect(await repo.isCloudFetchSkippable('v-1'), isTrue);
        expect((await repo.readCloudFetchState('v-1'))!.lastStatus, 'success');

        // lastStatus=error is the same "force retry" signal the
        // pre-seam controller computed — the repo carries the same
        // predicate.
        await db.transcriptFetchStateDao.upsertOutcome(
          targetType: 'Video',
          targetId: 'v-1',
          lastFetchedAt: now,
          lastStatus: 'error',
          lastError: 'boom',
        );
        expect(await repo.isCloudFetchSkippable('v-1'), isFalse);
        expect((await repo.readCloudFetchState('v-1'))!.lastError, 'boom');
      },
    );
  });
}
