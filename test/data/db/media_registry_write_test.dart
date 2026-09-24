/// Table-driven write suite for the [MediaRegistry] seam (issue #723).
///
/// Every write op is exercised against four fixtures — video-only,
/// audio-only, both tables, neither — with the both-tables case asserting
/// the video-first precedence explicitly (an id never legitimately lives in
/// both tables, but the registry's tie-break is part of its contract).
library;

import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/media_registry.dart';
import 'package:enjoy_player/features/library/domain/media.dart';
import 'package:enjoy_player/features/sync/domain/sync_types.dart';
import 'package:flutter_test/flutter_test.dart';

final DateTime _base = DateTime(2026, 7, 1);

VideoRow _videoRow({String id = 'shared', int durationSeconds = 0}) {
  return VideoRow(
    id: id,
    vid: 'vid-$id',
    provider: 'user',
    title: 'Video $id',
    durationSeconds: durationSeconds,
    language: 'en',
    localUri: '/tmp/$id.mp4',
    createdAt: _base,
    updatedAt: _base,
  );
}

AudioRow _audioRow({
  String id = 'shared',
  int durationSeconds = 0,
  String language = 'ja',
}) {
  return AudioRow(
    id: id,
    aid: 'aid-$id',
    provider: 'user',
    title: 'Audio $id',
    durationSeconds: durationSeconds,
    language: language,
    localUri: '/tmp/$id.mp3',
    createdAt: _base,
    updatedAt: _base,
  );
}

/// Which tables hold the probe id at the start of a case.
enum Fixture { videoOnly, audioOnly, both, neither }

const _fixtureLabels = {
  Fixture.videoOnly: 'video only',
  Fixture.audioOnly: 'audio only',
  Fixture.both: 'both tables',
  Fixture.neither: 'neither table',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late MediaRegistry registry;

  /// Seeds [f] for `id` and returns the kind the registry must report.
  Future<MediaKind?> seed(Fixture f, {String id = 'shared'}) async {
    switch (f) {
      case Fixture.videoOnly:
        await db.videoDao.insertRow(_videoRow(id: id));
        return MediaKind.video;
      case Fixture.audioOnly:
        await db.audioDao.insertRow(_audioRow(id: id));
        return MediaKind.audio;
      case Fixture.both:
        await db.videoDao.insertRow(_videoRow(id: id));
        await db.audioDao.insertRow(_audioRow(id: id));
        return MediaKind.video;
      case Fixture.neither:
        return null;
    }
  }

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    registry = MediaRegistry(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('deleteById', () {
    for (final f in Fixture.values) {
      test('deletes ${_fixtureLabels[f]}', () async {
        final expected = await seed(f);
        final kind = await registry.deleteById('shared');
        expect(kind, expected);
        expect(await db.videoDao.getById('shared'), isNull);
        // Video-first: with a video match the audios table is never probed,
        // so its row (if any) survives — pinned by the test below.
        if (expected != MediaKind.video) {
          expect(await db.audioDao.getById('shared'), isNull);
        }
      });
    }

    test('both tables: only the video row is removed (video first)', () async {
      await seed(Fixture.both);
      await registry.deleteById('shared');
      expect(await db.videoDao.getById('shared'), isNull);
      // The audio row was never probed, let alone deleted.
      expect(await db.audioDao.getById('shared'), isNotNull);
    });

    test('unknown id touches nothing', () async {
      await seed(Fixture.videoOnly);
      expect(await registry.deleteById('other'), isNull);
      expect(await db.videoDao.getById('shared'), isNotNull);
    });
  });

  group('touchUpdatedAt', () {
    for (final f in Fixture.values) {
      test('bumps updatedAt for ${_fixtureLabels[f]}', () async {
        final expected = await seed(f);
        await registry.touchUpdatedAt('shared');
        if (expected == MediaKind.video) {
          expect(
            (await db.videoDao.getById('shared'))!.updatedAt.isAfter(_base),
            isTrue,
          );
        }
        if (expected == MediaKind.audio) {
          expect(
            (await db.audioDao.getById('shared'))!.updatedAt.isAfter(_base),
            isTrue,
          );
        }
      });
    }

    test('both tables: only the video row is bumped', () async {
      await seed(Fixture.both);
      await registry.touchUpdatedAt('shared');
      expect(
        (await db.videoDao.getById('shared'))!.updatedAt.isAfter(_base),
        isTrue,
      );
      expect((await db.audioDao.getById('shared'))!.updatedAt, _base);
    });

    test('unknown id is a silent no-op', () async {
      await registry.touchUpdatedAt('missing');
    });
  });

  group('updateLanguage', () {
    for (final f in Fixture.values) {
      test('writes the tag for ${_fixtureLabels[f]}', () async {
        final expected = await seed(f);
        final kind = await registry.updateLanguage('shared', 'de');
        expect(kind, expected);
        if (expected == MediaKind.video) {
          expect((await db.videoDao.getById('shared'))!.language, 'de');
        }
        if (expected == MediaKind.audio) {
          expect((await db.audioDao.getById('shared'))!.language, 'de');
        }
      });
    }

    test('both tables: only the video row is re-tagged', () async {
      await seed(Fixture.both);
      await registry.updateLanguage('shared', 'de');
      expect((await db.videoDao.getById('shared'))!.language, 'de');
      expect((await db.audioDao.getById('shared'))!.language, 'ja');
    });

    test('writes the tag verbatim (no canonicalization)', () async {
      await seed(Fixture.audioOnly);
      await registry.updateLanguage('shared', 'EN-US');
      expect((await db.audioDao.getById('shared'))!.language, 'EN-US');
    });
  });

  group('updateLocalFile', () {
    final bookmark = Uint8List.fromList([1, 2, 3]);

    for (final f in Fixture.values) {
      test('persists relocate fields for ${_fixtureLabels[f]}', () async {
        final expected = await seed(f);
        final kind = await registry.updateLocalFile(
          'shared',
          localUri: '/tmp/new.mp4',
          bookmarkData: bookmark,
          size: 42,
          mtimeMs: 1234,
        );
        expect(kind, expected);
        if (expected == MediaKind.video) {
          final row = await db.videoDao.getById('shared');
          expect(row!.localUri, '/tmp/new.mp4');
          expect(row.bookmarkData, bookmark);
          expect(row.size, 42);
          expect(row.localMtimeMs, 1234);
          expect(row.updatedAt.isAfter(_base), isTrue);
        }
        if (expected == MediaKind.audio) {
          final row = await db.audioDao.getById('shared');
          expect(row!.localUri, '/tmp/new.mp4');
          expect(row.bookmarkData, bookmark);
          expect(row.size, 42);
          expect(row.localMtimeMs, 1234);
          expect(row.updatedAt.isAfter(_base), isTrue);
        }
      });
    }

    test('a null bookmark clears a stale one', () async {
      await db.videoDao.insertRow(
        _videoRow().copyWith(
          bookmarkData: Value(bookmark),
          size: const Value(9),
        ),
      );
      await registry.updateLocalFile(
        'shared',
        localUri: '/tmp/moved.mp4',
        bookmarkData: null,
        size: 10,
        mtimeMs: null,
      );
      final row = await db.videoDao.getById('shared');
      expect(row!.localUri, '/tmp/moved.mp4');
      expect(row.bookmarkData, isNull);
      expect(row.size, 10);
      expect(row.localMtimeMs, isNull);
    });
  });

  group('patchDurationIfZero', () {
    for (final f in Fixture.values) {
      test('patches a zero duration for ${_fixtureLabels[f]}', () async {
        final expected = await seed(f);
        final kind = await registry.patchDurationIfZero('shared', 77);
        expect(kind, expected);
        if (expected == MediaKind.video) {
          expect((await db.videoDao.getById('shared'))!.durationSeconds, 77);
        }
        if (expected == MediaKind.audio) {
          expect((await db.audioDao.getById('shared'))!.durationSeconds, 77);
        }
      });
    }

    test(
      'skips a row whose duration is already set (first writer wins)',
      () async {
        await db.videoDao.insertRow(_videoRow(durationSeconds: 12));
        expect(await registry.patchDurationIfZero('shared', 77), isNull);
        expect((await db.videoDao.getById('shared'))!.durationSeconds, 12);
      },
    );

    test('both tables: only the video row is patched', () async {
      await seed(Fixture.both);
      await registry.patchDurationIfZero('shared', 77);
      expect((await db.videoDao.getById('shared'))!.durationSeconds, 77);
      expect((await db.audioDao.getById('shared'))!.durationSeconds, 0);
    });

    test('concurrent backfills do not double-write — only one wins', () async {
      await seed(Fixture.videoOnly);
      final results = await Future.wait([
        registry.patchDurationIfZero('shared', 77),
        registry.patchDurationIfZero('shared', 88),
        registry.patchDurationIfZero('shared', 99),
      ]);
      // The shared WHERE duration_seconds = 0 guard means exactly one
      // write touches the row; the others must report null.
      expect(results.where((k) => k != null), hasLength(1));
      expect(results.where((k) => k == null), hasLength(2));
      final row = (await db.videoDao.getById('shared'))!;
      expect(row.durationSeconds, anyOf(77, 88, 99));
    });

    test(
      'unrelated field changes between the read and the patch are preserved',
      () async {
        // The pre-fix probe+copyWith could write a stale row back on top
        // of a parallel change to another column. Seed an initial row,
        // bump `title` (unrelated to duration), then patch — `title` must
        // survive.
        await db.videoDao.insertRow(
          _videoRow().copyWith(title: 'Original Title'),
        );
        await db.videoDao.updateLocalThumbnail('shared', '/tmp/thumb.jpg');
        final patched = await registry.patchDurationIfZero('shared', 77);
        expect(patched, MediaKind.video);
        final row = (await db.videoDao.getById('shared'))!;
        expect(row.durationSeconds, 77);
        expect(row.title, 'Original Title');
        expect(row.thumbnailUrl, '/tmp/thumb.jpg');
      },
    );
  });

  group('upsertVideo / upsertAudio', () {
    test('insert then replace by id', () async {
      await registry.upsertVideo(_videoRow(id: 'v9'));
      await registry.upsertVideo(
        _videoRow(id: 'v9').copyWith(title: 'Replaced'),
      );
      expect((await db.videoDao.getById('v9'))!.title, 'Replaced');
      expect((await db.videoDao.listAll()), hasLength(1));

      await registry.upsertAudio(_audioRow(id: 'a9'));
      await registry.upsertAudio(
        _audioRow(id: 'a9').copyWith(title: 'Replaced'),
      );
      expect((await db.audioDao.getById('a9'))!.title, 'Replaced');
    });
  });

  group('updateVideoThumbnail', () {
    test('writes the absolute path and bumps updatedAt', () async {
      await db.videoDao.insertRow(_videoRow());
      await registry.updateVideoThumbnail('shared', '/tmp/thumb.jpg');
      final row = await db.videoDao.getById('shared');
      expect(row!.thumbnailUrl, '/tmp/thumb.jpg');
      expect(row.updatedAt.isAfter(_base), isTrue);
    });
  });

  group('updateYoutubeMetadata', () {
    test(
      'writes title + thumbnail onto the video row and bumps updatedAt',
      () async {
        await db.videoDao.insertRow(_videoRow());
        await registry.updateYoutubeMetadata(
          id: 'shared',
          title: 'Resolved title',
          thumbnailUrl: '/tmp/yt-thumb.jpg',
        );
        final row = await db.videoDao.getById('shared');
        expect(row!.title, 'Resolved title');
        expect(row.thumbnailUrl, '/tmp/yt-thumb.jpg');
        expect(row.updatedAt.isAfter(_base), isTrue);
      },
    );

    test('a null thumbnail leaves the stored thumbnail untouched', () async {
      await db.videoDao.insertRow(_videoRow());
      await db.videoDao.updateLocalThumbnail('shared', '/tmp/old.jpg');
      await registry.updateYoutubeMetadata(
        id: 'shared',
        title: 'Title only',
        thumbnailUrl: null,
      );
      final row = await db.videoDao.getById('shared');
      expect(row!.title, 'Title only');
      expect(row.thumbnailUrl, '/tmp/old.jpg');
    });

    test('audio-only id is a silent no-op (video-only write)', () async {
      await seed(Fixture.audioOnly);
      await registry.updateYoutubeMetadata(
        id: 'shared',
        title: 'Nope',
        thumbnailUrl: '/tmp/nope.jpg',
      );
      final row = await db.audioDao.getById('shared');
      expect(row!.title, 'Audio shared');
      expect(row.thumbnailUrl, isNull);
    });

    test(
      'both tables: only the video row is rewritten (video first)',
      () async {
        await seed(Fixture.both);
        await registry.updateYoutubeMetadata(
          id: 'shared',
          title: 'Video updated',
          thumbnailUrl: null,
        );
        expect((await db.videoDao.getById('shared'))!.title, 'Video updated');
        expect((await db.audioDao.getById('shared'))!.title, 'Audio shared');
      },
    );
  });

  group('probeBoth', () {
    test('returns full rows for the holding table', () async {
      await seed(Fixture.audioOnly);
      final hit = await registry.probeBoth('shared');
      expect(hit.video, isNull);
      expect(hit.audio!.id, 'shared');
    });

    test('short-circuits: audio stays null when a video matched', () async {
      await seed(Fixture.both);
      final hit = await registry.probeBoth('shared');
      expect(hit.video!.id, 'shared');
      expect(hit.audio, isNull);
    });

    test('neither table yields nulls', () async {
      final hit = await registry.probeBoth('missing');
      expect(hit.video, isNull);
      expect(hit.audio, isNull);
    });
  });

  group('syncEntityTypeOf', () {
    test('maps kinds onto sync entities', () {
      expect(
        MediaRegistry.syncEntityTypeOf(MediaKind.video),
        SyncEntityType.video,
      );
      expect(
        MediaRegistry.syncEntityTypeOf(MediaKind.audio),
        SyncEntityType.audio,
      );
    });
  });
}
