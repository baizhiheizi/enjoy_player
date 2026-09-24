import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/media_registry.dart';
import 'package:enjoy_player/features/library/domain/media.dart';
import 'package:flutter_test/flutter_test.dart';

VideoRow _video({
  String id = 'v-1',
  String vid = 'vid-1',
  String provider = 'user',
  String title = 'Sample',
  int durationSeconds = 60,
  String language = 'und',
  String? source,
  String? localUri,
  int? size,
  String? mediaUrl,
  String? md5,
  DateTime? createdAt,
}) {
  final now = createdAt ?? DateTime(2026, 7, 1);
  return VideoRow(
    id: id,
    vid: vid,
    provider: provider,
    title: title,
    durationSeconds: durationSeconds,
    language: language,
    source: source,
    localUri: localUri,
    size: size,
    mediaUrl: mediaUrl,
    md5: md5,
    createdAt: now,
    updatedAt: now,
  );
}

AudioRow _audio({
  String id = 'a-1',
  String aid = 'aid-1',
  String provider = 'user',
  String title = 'Audio',
  int durationSeconds = 30,
  String language = 'und',
  String? localUri,
  int? size,
  String? mediaUrl,
  String? md5,
  DateTime? createdAt,
}) {
  final now = createdAt ?? DateTime(2026, 7, 1);
  return AudioRow(
    id: id,
    aid: aid,
    provider: provider,
    title: title,
    durationSeconds: durationSeconds,
    language: language,
    localUri: localUri,
    size: size,
    mediaUrl: mediaUrl,
    md5: md5,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late MediaRegistry registry;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    registry = MediaRegistry(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('getById', () {
    test('maps a video row to domain Media', () async {
      await db.videoDao.insertRow(
        _video(
          localUri: '/tmp/movie.mp4',
          mediaUrl: 'https://x.example/movie.mp4',
          size: 123,
        ),
      );
      final media = await registry.getById('v-1');
      expect(
        media,
        Media(
          id: 'v-1',
          kind: MediaKind.video,
          title: 'Sample',
          sourceUri: '/tmp/movie.mp4',
          thumbnailPath: null,
          durationMs: 60000,
          language: 'und',
          contentHash: 'vid-1',
          fileSize: 123,
          mediaUrl: 'https://x.example/movie.mp4',
          source: null,
          provider: 'user',
          syncStatus: null,
          createdAt: DateTime(2026, 7, 1),
          updatedAt: DateTime(2026, 7, 1),
        ),
      );
    });

    test('maps an audio row to domain Media', () async {
      await db.audioDao.insertRow(_audio(mediaUrl: 'https://x.example/a.mp3'));
      final media = await registry.getById('a-1');
      expect(media, isNotNull);
      expect(media!.kind, MediaKind.audio);
      expect(media.contentHash, 'aid-1');
      // No localUri: sourceUri falls back to mediaUrl.
      expect(media.sourceUri, 'https://x.example/a.mp3');
      expect(media.durationMs, 30000);
      expect(media.fileSize, 0);
    });

    test('returns null when neither table holds the id', () async {
      expect(await registry.getById('missing'), isNull);
    });

    test('video wins when the same id exists in both tables', () async {
      await db.videoDao.insertRow(_video(id: 'shared'));
      await db.audioDao.insertRow(_audio(id: 'shared'));
      final media = await registry.getById('shared');
      expect(media!.kind, MediaKind.video);
    });
  });

  group('kindOf', () {
    test('resolves video and audio kinds', () async {
      await db.videoDao.insertRow(_video());
      await db.audioDao.insertRow(_audio());
      expect(await registry.kindOf('v-1'), MediaKind.video);
      expect(await registry.kindOf('a-1'), MediaKind.audio);
      expect(await registry.kindOf('missing'), isNull);
    });
  });

  group('dexieTargetTypeForId', () {
    test('returns weapp target types', () async {
      await db.videoDao.insertRow(_video());
      await db.audioDao.insertRow(_audio());
      expect(await registry.dexieTargetTypeForId('v-1'), 'Video');
      expect(await registry.dexieTargetTypeForId('a-1'), 'Audio');
      expect(await registry.dexieTargetTypeForId('missing'), isNull);
    });
  });

  group('localUriOf', () {
    test('returns the localUri of whichever table holds the id', () async {
      await db.videoDao.insertRow(_video(localUri: '/tmp/v.mp4'));
      await db.audioDao.insertRow(_audio(localUri: '/tmp/a.mp3'));
      expect(await registry.localUriOf('v-1'), '/tmp/v.mp4');
      expect(await registry.localUriOf('a-1'), '/tmp/a.mp3');
    });

    test('returns null for a missing row or a row without localUri', () async {
      await db.videoDao.insertRow(_video(id: 'remote-only'));
      expect(await registry.localUriOf('remote-only'), isNull);
      expect(await registry.localUriOf('missing'), isNull);
    });
  });

  group('kind-known reads', () {
    test('getVideoById / getAudioById read only their own table', () async {
      await db.videoDao.insertRow(_video(id: 'v-1'));
      await db.audioDao.insertRow(_audio(id: 'a-1'));
      expect((await registry.getVideoById('v-1'))!.id, 'v-1');
      expect((await registry.getAudioById('a-1'))!.id, 'a-1');
    });

    test(
      'a kind-known read misses when the id lives in the other table',
      () async {
        // Direct-DAO semantics preserved: an audio id must read as null from
        // the video side (and vice versa) — no cross-table fallback.
        await db.audioDao.insertRow(_audio(id: 'a-only'));
        await db.videoDao.insertRow(_video(id: 'v-only'));
        expect(await registry.getVideoById('a-only'), isNull);
        expect(await registry.getAudioById('v-only'), isNull);
        expect(await registry.getVideoById('missing'), isNull);
        expect(await registry.getAudioById('missing'), isNull);
      },
    );

    test('getAudioByMd5 finds an audio row by content hash', () async {
      await db.audioDao.insertRow(_audio(id: 'a-md5', md5: 'hash-1'));
      expect((await registry.getAudioByMd5('hash-1'))!.id, 'a-md5');
      expect(await registry.getAudioByMd5('nope'), isNull);
    });

    test('getAudioByMd5 ignores a video row sharing the md5', () async {
      // Craft dedupe is audio-only by design — a videos row with the same
      // hash must not shadow or satisfy the lookup.
      await db.videoDao.insertRow(_video(id: 'v-md5', md5: 'hash-1'));
      expect(await registry.getAudioByMd5('hash-1'), isNull);
    });

    test('getYoutubeVideoByVid matches provider=youtube rows only', () async {
      await db.videoDao.insertRow(
        _video(id: 'yt-1', vid: 'plat1', provider: 'youtube'),
      );
      await db.videoDao.insertRow(
        _video(id: 'user-1', vid: 'plat1', provider: 'user'),
      );
      expect((await registry.getYoutubeVideoByVid('plat1'))!.id, 'yt-1');
      expect(await registry.getYoutubeVideoByVid('unknown'), isNull);
    });
  });

  group('existsByLocalUri', () {
    test('true when a video or audio row references the uri', () async {
      await db.videoDao.insertRow(_video(localUri: '/tmp/v.mp4'));
      await db.audioDao.insertRow(_audio(localUri: '/tmp/a.mp3'));
      expect(await registry.existsByLocalUri('/tmp/v.mp4'), isTrue);
      expect(await registry.existsByLocalUri('/tmp/a.mp3'), isTrue);
    });

    test('false when no row references the uri', () async {
      await db.videoDao.insertRow(_video(localUri: '/tmp/v.mp4'));
      expect(await registry.existsByLocalUri('/tmp/orphan.mp4'), isFalse);
      expect(await registry.existsByLocalUri(''), isFalse);
    });
  });

  group('watchAll', () {
    test('emits once for an empty library', () async {
      // Moved pin (issue #753): the merged stream now lives on the registry;
      // `lastEmitted` staying nullable is what keeps a zero-row library from
      // being swallowed by the dedupe check (see `a12634c3` and the
      // library_repository_test copy of this pin).
      final emissions = <List<Media>>[];
      final sub = registry.watchAll().listen(emissions.add);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(emissions, hasLength(1));
      expect(emissions.single, isEmpty);

      await sub.cancel();
    });

    test('deduplicates identical re-emissions', () async {
      await db.audioDao.insertRow(_audio(id: 'dup-1', title: 'x'));

      final emissions = <List<Media>>[];
      final sub = registry.watchAll().listen(emissions.add);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(emissions, hasLength(1));
      expect(emissions.first, hasLength(1));

      // No-op write: same row, same fields. Both DAO streams re-query and
      // push the unchanged merged list back — the registry must suppress it.
      await db.audioDao.insertRow(_audio(id: 'dup-1', title: 'x'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(emissions, hasLength(1));

      // A real change must still emit.
      await db.audioDao.insertRow(_audio(id: 'dup-1', title: 'renamed'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(emissions, hasLength(2));
      expect(emissions.last.single.title, 'renamed');

      await sub.cancel();
    });

    test('merges both tables sorted by createdAt descending', () async {
      await db.videoDao.insertRow(
        _video(id: 'v-old', createdAt: DateTime(2026, 7, 1)),
      );
      await db.videoDao.insertRow(
        _video(id: 'v-mid', createdAt: DateTime(2026, 7, 2)),
      );
      await db.audioDao.insertRow(
        _audio(id: 'a-new', createdAt: DateTime(2026, 7, 3)),
      );

      final emissions = <List<Media>>[];
      final sub = registry.watchAll().listen(emissions.add);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // The final emission carries the full merged, createdAt-desc list —
      // the two DAO streams may have delivered one partial snapshot first.
      expect(emissions.last.map((m) => m.id), ['a-new', 'v-mid', 'v-old']);

      await sub.cancel();
    });
  });
}
