import 'dart:async';

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

/// `Media.id` projection the `watchAll` tests assert on.
List<String> _mediaIds(List<Media> library) =>
    library.map((media) => media.id).toList();

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

  group('watchYoutubeVideoIds', () {
    test('emits the youtube vids and ignores empty ones', () async {
      await db.videoDao.insertRow(
        _video(id: 'a', vid: 'vid-a', provider: 'youtube'),
      );
      await db.videoDao.insertRow(_video(id: 'b', vid: '', provider: 'user'));
      await db.videoDao.insertRow(
        _video(id: 'c', vid: 'vid-c', provider: 'youtube'),
      );

      final emissions = <Set<String>>[];
      final sub = registry.watchYoutubeVideoIds().listen(emissions.add);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(emissions, hasLength(1));
      expect(emissions.single, {'vid-a', 'vid-c'});

      await sub.cancel();
    });

    test('emits an empty set for an empty library', () async {
      final emissions = <Set<String>>[];
      final sub = registry.watchYoutubeVideoIds().listen(emissions.add);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(emissions, hasLength(1));
      expect(emissions.single, isEmpty);

      await sub.cancel();
    });

    // Issue #764 candidate 6: the discover timeline and a channel view both
    // join membership, and the timeline provider is keep-alive, so two
    // listeners can exist at once.
    test('two listeners on the same stream both receive', () async {
      await db.videoDao.insertRow(
        _video(id: 'a', vid: 'vid-a', provider: 'youtube'),
      );

      // ONE stream object, two listeners. The earlier version of this test
      // called the factory twice, which builds two independent streams and so
      // never exercised the shared-dedupe-state hazard it appeared to cover.
      final stream = registry.watchYoutubeVideoIds();
      final first = <Set<String>>[];
      final second = <Set<String>>[];
      final subA = stream.listen(first.add);
      final subB = stream.listen(second.add);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(first, hasLength(1));
      expect(first.single, {'vid-a'});
      expect(
        second,
        hasLength(1),
        reason: 'a second listener must not dedupe against the first one',
      );
      expect(second.single, {'vid-a'});

      await subA.cancel();
      await subB.cancel();
    });

    // Independent calls are independent streams (the production shape: the
    // timeline and channel providers each call the factory).
    test('independent calls are independent streams', () async {
      await db.videoDao.insertRow(
        _video(id: 'a', vid: 'vid-a', provider: 'youtube'),
      );

      final first = <Set<String>>[];
      final second = <Set<String>>[];
      final subA = registry.watchYoutubeVideoIds().listen(first.add);
      final subB = registry.watchYoutubeVideoIds().listen(second.add);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(first.single, {'vid-a'});
      expect(second.single, {'vid-a'});

      await subA.cancel();
      await subB.cancel();
    });

    test('a library write reaches an existing subscriber', () async {
      final emissions = <Set<String>>[];
      final sub = registry.watchYoutubeVideoIds().listen(emissions.add);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(emissions.single, isEmpty);

      await db.videoDao.insertRow(
        _video(id: 'a', vid: 'vid-a', provider: 'youtube'),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(emissions.last, {'vid-a'});

      await sub.cancel();
    });

    test('an audio-only write does not re-emit', () async {
      final emissions = <Set<String>>[];
      final sub = registry.watchYoutubeVideoIds().listen(emissions.add);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(emissions, hasLength(1));

      await db.audioDao.insertRow(_audio(id: 'x', title: 't'));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(emissions, hasLength(1), reason: 'videos table did not change');

      await sub.cancel();
    });

    test('cancelling one subscriber leaves the other listening', () async {
      final first = <Set<String>>[];
      final second = <Set<String>>[];
      final subA = registry.watchYoutubeVideoIds().listen(first.add);
      final subB = registry.watchYoutubeVideoIds().listen(second.add);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await subA.cancel();
      await db.videoDao.insertRow(
        _video(id: 'a', vid: 'vid-a', provider: 'youtube'),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(first, hasLength(1), reason: 'cancelled subscriber stopped');
      expect(second.last, {'vid-a'});

      await subB.cancel();
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

    test(
      'characterizes Drift delivery: single- vs both-table writes',
      () async {
        // Characterization first (PR #756 thread 2): this pins HOW Drift
        // delivers re-query events to the registry's two DAO listeners
        // before deciding whether `watchAll` may coalesce them:
        //
        // * (a) a single-table write, (b) a write touching both tables in
        //   one go — the production shape being sequential awaited upserts
        //   (`library_repository.importMedia`, `cloud_add_to_library`).
        //
        // `turn` counts event-loop iterations: a zero-duration periodic
        // timer fires exactly once per iteration, strictly between
        // microtask drains — so listener callbacks that observed the same
        // `turn` value ran within ONE event-loop turn (no timer/IO
        // boundary between them), while differing values mean the
        // delivery spanned a turn boundary.
        var turn = 0;
        final turnTicker = Timer.periodic(Duration.zero, (_) => turn++);
        addTearDown(turnTicker.cancel);

        // stream name -> observed turn id per delivered snapshot
        final daoEvents = <String, List<int>>{};
        void recordDao(String stream) =>
            daoEvents.putIfAbsent(stream, () => <int>[]).add(turn);

        final emissions = <List<Media>>[];
        final emissionTurns = <int>[];
        final subV = db.videoDao.watchAll().listen((_) => recordDao('video'));
        final subA = db.audioDao.watchAll().listen((_) => recordDao('audio'));
        final subReg = registry.watchAll().listen((m) {
          emissions.add(m);
          emissionTurns.add(turn);
        });
        addTearDown(() async {
          await subV.cancel();
          await subA.cancel();
          await subReg.cancel();
        });

        // Initial snapshots from both DAO streams + first merged emission.
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(
          daoEvents.keys,
          unorderedEquals(<String>['video', 'audio']),
          reason: 'initial snapshots come from both DAO streams',
        );
        expect(emissions, hasLength(1));
        daoEvents.clear();
        emissions.clear();
        emissionTurns.clear();

        // (a) Single-table write: a videos-row insert.
        await db.videoDao.insertRow(_video(id: 'v-single'));
        await Future<void>.delayed(const Duration(milliseconds: 50));
        final singleDaoEvents = {
          for (final e in daoEvents.entries) e.key: List<int>.of(e.value),
        };
        final singleEmissions = List<List<Media>>.of(emissions);
        final singleEmissionTurns = List<int>.of(emissionTurns);
        daoEvents.clear();
        emissions.clear();
        emissionTurns.clear();

        // (b) Both-tables write: one upsert per table, back to back.
        await db.videoDao.insertRow(
          _video(id: 'v-both', createdAt: DateTime(2026, 7, 2)),
        );
        await db.audioDao.insertRow(
          _audio(id: 'a-both', createdAt: DateTime(2026, 7, 3)),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));
        final bothDaoEvents = {
          for (final e in daoEvents.entries) e.key: List<int>.of(e.value),
        };
        final bothEmissions = List<List<Media>>.of(emissions);

        // --- (a) pins ---
        // A single-table write re-delivers ONLY on that table's DAO stream
        // (Drift's watch is per-table: `select(videos)` is invalidated by
        // `videos` updates only) and produces exactly one merged emission
        // carrying the new row. The other side's cached snapshot is still
        // accurate — its table did not change — so a single-table write
        // can never emit a stale partial snapshot.
        expect(singleDaoEvents.keys, equals(<String>['video']));
        expect(singleDaoEvents['video'], hasLength(1));
        expect(singleEmissions, hasLength(1));
        expect(singleEmissions.single.map((m) => m.id), ['v-single']);
        expect(singleEmissionTurns, hasLength(1));

        // --- (b) pins ---
        // THE decision criterion for PR #756 thread 2: do both DAO
        // re-deliveries of a both-tables write land in the SAME
        // event-loop turn (-> same-turn coalescing is possible) or in
        // different turns (-> coalescing would stall one side)?
        expect(bothDaoEvents.keys, unorderedEquals(<String>['video', 'audio']));
        expect(
          bothDaoEvents['video'],
          bothDaoEvents['audio'],
          reason:
              'both-tables write: DAO re-deliveries observed in different '
              'event-loop turns — the emit path must NOT wait for the '
              'other side (it would stall single-table updates)',
        );
        // Whatever the turn story, the final state is correct and ordered
        // (createdAt desc: a-both 07-03 > v-both 07-02 > v-single 07-01).
        expect(bothEmissions.last.map((m) => m.id), [
          'a-both',
          'v-both',
          'v-single',
        ]);
      },
    );

    // Architecture review #794 candidate 6: the merge state used to live in
    // one shared closure above the `Stream.multi` wrapper, so a second
    // concurrent listener on the same stream threw (single-subscription
    // wrapper) instead of receiving.
    //
    // The multi-subscriber tests below wait deterministically (review on
    // #801): `take(1).toList()` / `first` complete on the emission itself,
    // and `pumpEventQueue()` settles the drift delivery chains — no
    // wall-clock sleeps.
    test('two listeners on the same stream both receive', () async {
      await db.videoDao.insertRow(
        _video(id: 'a', vid: 'vid-a', provider: 'youtube'),
      );

      // ONE stream object, two concurrent listeners — the shape the
      // ids-watch tests above use for the same hazard. Each `take(1)`
      // future completes on that listener's own first emission (and
      // unsubscribes), so both waits are exact.
      final stream = registry.watchAll();
      final first = stream.map(_mediaIds).take(1).toList();
      final second = stream.map(_mediaIds).take(1).toList();
      final received = await Future.wait([first, second]);

      expect(received[0].single, ['a']);
      expect(
        received[1].single,
        ['a'],
        reason:
            'a second listener must not throw or dedupe against the '
            'first one',
      );
    });

    test('cancelling one subscriber leaves the other listening', () async {
      final first = <List<String>>[];
      final second = <List<String>>[];
      final subA = registry.watchAll().map(_mediaIds).listen(first.add);
      final subB = registry.watchAll().map(_mediaIds).listen(second.add);
      await pumpEventQueue();

      await subA.cancel();
      await db.videoDao.insertRow(
        _video(id: 'a', vid: 'vid-a', provider: 'youtube'),
      );
      await pumpEventQueue();

      expect(first, [isEmpty], reason: 'cancelled subscriber stopped');
      expect(second, [
        isEmpty,
        ['a'],
      ]);
      await subB.cancel();
    });

    test(
      'a fresh listener after a cancel receives the current library',
      () async {
        await db.videoDao.insertRow(
          _video(id: 'a', vid: 'vid-a', provider: 'youtube'),
        );

        // `first` both waits for the emission and cancels, so the earlier
        // listener is gone before the fresh one subscribes.
        expect(await registry.watchAll().map(_mediaIds).first, ['a']);

        // Per-listener dedupe state: the new listener's `distinctBy` gate
        // starts unset, so it receives the current library even though an
        // earlier listener on an earlier stream already saw it.
        expect(await registry.watchAll().map(_mediaIds).first, ['a']);
      },
    );

    // Review on #801: a cancel landing between a DAO delivery and its
    // coalescing microtask strands that microtask on the listener's
    // already-cancelled controller — `emit()` must bail on the `closed`
    // guard instead of adding to the dead controller. (The ids-watch
    // carried this exact guard — "a coalesced microtask can outlive the
    // last listener" — until the #795 branch's rewrite retired its
    // hand-rolled emit; this `watchAll` rewrite must not lose it.)
    //
    // The window opens deterministically, without timing: on a write, the
    // keyed drift query stream re-delivers to its subscribers in
    // subscription order within one turn — the merge's DAO listener
    // (subscribed first) buffers the snapshot and queues its emit
    // microtask, and this test's canceller watcher (subscribed last)
    // then cancels while that microtask is still pending.
    //
    // Dart 3.12 silently drops `add`s on a cancelled `Stream.multi`
    // controller rather than throwing, so the pinned contract is the
    // observable one: the stranded microtask produces no unhandled error
    // and no post-cancel delivery, while the surviving listener proves
    // the write + delivery pipeline actually ran through that window.
    test(
      'an emit scheduled before a cancel does not reach the closed controller',
      () async {
        await db.videoDao.insertRow(
          _video(id: 'a', vid: 'vid-a', provider: 'youtube'),
        );
        final stream = registry.watchAll();

        final zoneErrors = <Object>[];
        final cancelled = <List<String>>[];
        final kept = <List<String>>[];
        var cancellerFired = false;
        await runZonedGuarded(() async {
          final subCancelled = stream.map(_mediaIds).listen(cancelled.add);
          final subKept = stream.map(_mediaIds).listen(kept.add);
          await pumpEventQueue(); // initial emission for both listeners

          var armed = false;
          final canceller = db.videoDao.watchAll().listen((_) {
            cancellerFired = true;
            if (armed) unawaited(subCancelled.cancel());
          });
          await pumpEventQueue(); // canceller's inert initial delivery

          armed = true;
          await db.videoDao.insertRow(
            _video(id: 'b', vid: 'vid-b', provider: 'youtube'),
          );
          await pumpEventQueue(); // run the stranded microtask
          await canceller.cancel();
          await subKept.cancel();
        }, (error, _) => zoneErrors.add(error));

        expect(cancellerFired, isTrue, reason: 'the cancel window opened');
        // The surviving listener proves the write was delivered through
        // the same window the stranded microtask sat in.
        expect(kept, [
          ['a'],
          ['a', 'b'],
        ]);
        // The cancelled listener received nothing after its cancel, and
        // the stranded emit microtask raised no unhandled error.
        expect(cancelled, [
          ['a'],
        ]);
        expect(zoneErrors, isEmpty);
      },
    );
  });
}
