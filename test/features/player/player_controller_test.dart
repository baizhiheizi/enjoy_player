import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/data/files/file_storage.dart';
import 'package:enjoy_player/features/library/application/library_repository_provider.dart';
import 'package:enjoy_player/features/library/data/library_repository.dart';
import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';
import 'package:enjoy_player/features/player/application/engines/youtube/youtube_player_engine.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/features/player/application/player_engine_constants.dart';
import 'package:enjoy_player/features/player/application/player_engine_rev.dart';
import 'package:enjoy_player/features/player/application/player_engine_test_double_provider.dart';
import 'package:enjoy_player/features/player/application/player_preferences_provider.dart';
import 'package:enjoy_player/features/player/domain/media_relocate_exception.dart';
import 'package:enjoy_player/features/player/domain/playback_session.dart';
import 'package:enjoy_player/features/player/domain/player_settings.dart';
import 'package:enjoy_player/features/player/domain/youtube_playback_unavailable_exception.dart';
import 'package:enjoy_player/features/transcript/application/transcript_repository_provider.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride, TargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import '../../support/fake_player_engine.dart';
import '../../support/test_path_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlayerController', () {
    late AppDatabase db;
    late FakePlayerEngine fake;
    late ProviderContainer container;
    late PathProviderPlatform originalPathProvider;
    late Directory pathProviderRoot;

    Future<String> insertMedia({
      required String id,
      String kind = 'audio',
      String? localUri,
      String? mediaUrl,
      String? md5,
      String? thumbnailUrl,
      int durationSeconds = 600,
    }) async {
      final now = DateTime.now();
      late final String effectiveLocal;
      if (localUri != null) {
        effectiveLocal = localUri;
      } else {
        final ext = kind == 'video' ? '.mp4' : '.mp3';
        final tmp = File(
          p.join(
            Directory.systemTemp.path,
            'enjoy_player_ctrl_${id}_${DateTime.now().microsecondsSinceEpoch}$ext',
          ),
        );
        await tmp.writeAsBytes([1]);
        effectiveLocal = Uri.file(tmp.path).toString();
      }
      if (kind == 'video') {
        await db.videoDao.insertRow(
          VideoRow(
            id: id,
            vid: 'x',
            provider: 'user',
            title: 't',
            description: null,
            thumbnailUrl: thumbnailUrl,
            durationSeconds: durationSeconds,
            language: 'en',
            source: null,
            localUri: effectiveLocal,
            md5: md5,
            size: 1,
            mediaUrl: mediaUrl,
            syncStatus: null,
            serverUpdatedAt: null,
            createdAt: now,
            updatedAt: now,
          ),
        );
      } else {
        await db.audioDao.insertRow(
          AudioRow(
            id: id,
            aid: 'x',
            provider: 'user',
            title: 't',
            description: null,
            thumbnailUrl: thumbnailUrl,
            durationSeconds: durationSeconds,
            language: 'en',
            translationKey: null,
            sourceText: null,
            voice: null,
            source: null,
            localUri: effectiveLocal,
            md5: md5,
            size: 1,
            mediaUrl: mediaUrl,
            syncStatus: null,
            serverUpdatedAt: null,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }
      return id;
    }

    setUp(() {
      originalPathProvider = PathProviderPlatform.instance;
      pathProviderRoot = Directory.systemTemp.createTempSync(
        'enjoy_player_ctrl_path',
      );
      PathProviderPlatform.instance = TestPathProvider(pathProviderRoot.path);

      db = AppDatabase(executor: NativeDatabase.memory());
      fake = FakePlayerEngine();
      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          playerEngineTestDoubleProvider.overrideWithValue(fake),
          transcriptRepositoryProvider.overrideWithValue(
            TranscriptRepository(db),
          ),
        ],
      );
    });

    tearDown(() async {
      PathProviderPlatform.instance = originalPathProvider;
      if (pathProviderRoot.existsSync()) {
        pathProviderRoot.deleteSync(recursive: true);
      }

      await pumpEventQueue();
      container.dispose();
      await db.close();
      await fake.dispose();
    });

    test('openMedia loads row and sets session', () async {
      final id = await insertMedia(id: 'm1');
      final n = container.read(playerControllerProvider.notifier);
      await n.openMedia(id);

      final session = container.read(playerControllerProvider);
      expect(session, isNotNull);
      expect(session!.mediaId, id);
      expect(session.mediaTitle, 't');
      expect(session.dexieTargetType, 'Audio');
      expect(fake.openUris, hasLength(1));
      expect(fake.openUris.single, startsWith('file:'));
    });

    test('openMedia same id again does not reload uri', () async {
      final id = await insertMedia(id: 'm1');
      final n = container.read(playerControllerProvider.notifier);
      await n.openMedia(id);
      final firstUri = fake.openUris.single;
      await n.openMedia(id);

      expect(fake.openUris, [firstUri]);
    });

    test('openMedia bumps library updatedAt for Home recent media', () async {
      final oldUpdated = DateTime.utc(2024, 1, 1);
      final id = await insertMedia(id: 'm-recent');
      final seeded = await db.audioDao.getById(id);
      await db.audioDao.insertRow(seeded!.copyWith(updatedAt: oldUpdated));

      final n = container.read(playerControllerProvider.notifier);
      await n.openMedia(id);
      await pumpEventQueue();

      final afterOpen = await db.audioDao.getById(id);
      expect(afterOpen!.updatedAt.isAfter(oldUpdated), isTrue);

      await db.audioDao.insertRow(afterOpen.copyWith(updatedAt: oldUpdated));
      await n.openMedia(id);
      await pumpEventQueue();

      final afterReopen = await db.audioDao.getById(id);
      expect(afterReopen!.updatedAt.isAfter(oldUpdated), isTrue);
      expect(fake.openUris, hasLength(1));
    });

    test('openMedia ignores stale completion when superseded', () async {
      fake.openDelay = () =>
          Future<void>.delayed(const Duration(milliseconds: 250));
      final idA = await insertMedia(id: 'a');
      final idB = await insertMedia(id: 'b');

      final n = container.read(playerControllerProvider.notifier);
      final f1 = n.openMedia(idA);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final f2 = n.openMedia(idB);
      await Future.wait([f1, f2]);

      expect(container.read(playerControllerProvider)?.mediaId, idB);
    });

    test('clear invalidates in-flight openMedia', () async {
      fake.openDelay = () =>
          Future<void>.delayed(const Duration(milliseconds: 250));
      final idA = await insertMedia(id: 'a');
      final idB = await insertMedia(id: 'b');

      final n = container.read(playerControllerProvider.notifier);
      final f1 = n.openMedia(idA);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await n.clear();
      final f2 = n.openMedia(idB);
      await Future.wait([f1, f2]);

      expect(container.read(playerControllerProvider)?.mediaId, idB);
    });

    test('debounced session persistence writes position', () async {
      final id = await insertMedia(id: 'm1');
      final n = container.read(playerControllerProvider.notifier);
      await n.openMedia(id);

      fake.emitDuration(const Duration(seconds: 120));
      fake.emitPosition(const Duration(seconds: 7));

      await Future<void>.delayed(const Duration(milliseconds: 550));

      final row = await db.echoSessionDao.getLatestForTarget('Audio', id);
      expect(row, isNotNull);
      expect(row!.currentTimeMs, closeTo(7000, 50));
    });

    test('echo mode seeks back into window', () async {
      final id = await insertMedia(id: 'm1');
      final n = container.read(playerControllerProvider.notifier);
      await n.openMedia(id);

      container
          .read(echoModeProvider.notifier)
          .activate(
            startLineIndex: 0,
            endLineIndex: 1,
            startTimeSeconds: 2,
            endTimeSeconds: 5,
          );

      fake.emitPosition(const Duration(milliseconds: 500));

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(fake.seekCalls, isNotEmpty);
      expect(fake.seekCalls.last, const Duration(milliseconds: 2000));
    });

    test(
      'echo pause-and-rewind fires on the boundary tick, not the next bucket',
      () async {
        final id = await insertMedia(id: 'echo-boundary');
        final n = container.read(playerControllerProvider.notifier);
        await n.openMedia(id);

        container
            .read(echoModeProvider.notifier)
            .activate(
              startLineIndex: 0,
              endLineIndex: 1,
              startTimeSeconds: 2,
              endTimeSeconds: 5,
            );

        fake.emitPosition(const Duration(milliseconds: 4950));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(
          fake.pauseCallCount,
          0,
          reason: 'below end guard must not pause',
        );

        fake.emitPosition(const Duration(milliseconds: 4970));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(fake.pauseCallCount, greaterThanOrEqualTo(1));
        expect(fake.seekCalls.last, const Duration(milliseconds: 2000));
      },
    );

    test(
      'echo enforcement fires within the same 400ms bucket at the boundary',
      () async {
        final id = await insertMedia(id: 'echo-fine');
        final n = container.read(playerControllerProvider.notifier);
        await n.openMedia(id);

        container
            .read(echoModeProvider.notifier)
            .activate(
              startLineIndex: 0,
              endLineIndex: 1,
              startTimeSeconds: 2,
              endTimeSeconds: 5,
            );

        fake.emitPosition(const Duration(milliseconds: 4850));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(fake.pauseCallCount, 0);

        fake.emitPosition(const Duration(milliseconds: 4900));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(fake.pauseCallCount, 0);

        fake.emitPosition(const Duration(milliseconds: 4960));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(fake.pauseCallCount, greaterThanOrEqualTo(1));
        expect(fake.seekCalls.last, const Duration(milliseconds: 2000));
      },
    );

    test(
      'echo enforcement is single-flight: concurrent seeks do not interleave',
      () async {
        final id = await insertMedia(id: 'echo-serial');
        final n = container.read(playerControllerProvider.notifier);
        await n.openMedia(id);

        container
            .read(echoModeProvider.notifier)
            .activate(
              startLineIndex: 0,
              endLineIndex: 1,
              startTimeSeconds: 2,
              endTimeSeconds: 5,
            );

        final gate = Completer<void>();
        fake.seekGate = gate;

        fake.emitPosition(const Duration(milliseconds: 4970));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(fake.pauseCallCount, 1);
        expect(fake.seekCalls.last, const Duration(milliseconds: 2000));
        final seeksWhileRewinding = fake.seekCalls.length;

        fake.emitPosition(const Duration(milliseconds: 4980));
        fake.emitPosition(const Duration(milliseconds: 4990));
        final clampFuture = n.seekToSeconds(2.5);
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(
          fake.pauseCallCount,
          1,
          reason: 'no concurrent pause while in flight',
        );
        expect(
          fake.seekCalls.length,
          seeksWhileRewinding,
          reason: 'no overlapping seek while the rewind is in flight',
        );

        gate.complete();
        await clampFuture;
        expect(fake.seekCalls.last, const Duration(milliseconds: 2500));
      },
    );

    test(
      'position is durably written mid-playback (survives a simulated crash)',
      () async {
        final id = await insertMedia(id: 'echo-crash');
        final n = container.read(playerControllerProvider.notifier);
        await n.openMedia(id);
        fake.emitDuration(const Duration(seconds: 120));

        fakeAsync((async) {
          for (var ms = 400; ms <= 2800; ms += 400) {
            fake.emitPosition(Duration(milliseconds: ms));
            async.elapse(const Duration(milliseconds: 400));
          }
        });

        int? persistedMs;
        for (var i = 0; i < 40; i++) {
          final row = await db.echoSessionDao.getLatestForTarget('Audio', id);
          if (row != null && row.currentTimeMs > 0) {
            persistedMs = row.currentTimeMs;
            break;
          }
          await Future<void>.delayed(const Duration(milliseconds: 25));
        }

        expect(
          persistedMs,
          isNotNull,
          reason: 'max-age flush must write mid-playback',
        );
        expect(persistedMs!, greaterThan(1500));
        expect(persistedMs, lessThanOrEqualTo(2800));
      },
    );

    test(
      'openMedia throws MediaNeedsRelocateException when local missing and hash set',
      () async {
        final now = DateTime.now();
        const id = 'reloc-1';
        const fingerprint =
            'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
        final missingPath = p.join(
          Directory.systemTemp.path,
          'enjoy_missing_${DateTime.now().microsecondsSinceEpoch}.mp4',
        );
        final uri = Uri.file(missingPath).toString();

        await db.videoDao.insertRow(
          VideoRow(
            id: id,
            vid: fingerprint,
            provider: 'user',
            title: 'From sync',
            description: null,
            thumbnailUrl: null,
            durationSeconds: 1,
            language: 'en',
            source: null,
            localUri: uri,
            md5: fingerprint,
            size: 100,
            mediaUrl: null,
            syncStatus: null,
            serverUpdatedAt: null,
            createdAt: now,
            updatedAt: now,
          ),
        );

        final n = container.read(playerControllerProvider.notifier);
        await expectLater(
          n.openMedia(id),
          throwsA(isA<MediaNeedsRelocateException>()),
        );
        expect(fake.openUris, isEmpty);
      },
    );

    test('openMedia uses mediaUrl when local file is missing', () async {
      final id = await insertMedia(
        id: 'net-1',
        localUri: Uri.file(
          p.join(
            Directory.systemTemp.path,
            'surely_missing_${DateTime.now().microsecondsSinceEpoch}.mp3',
          ),
        ).toString(),
        mediaUrl: 'https://example.com/media.mp4',
        md5: 'any',
      );
      final n = container.read(playerControllerProvider.notifier);
      await n.openMedia(id);
      expect(fake.openUris, ['https://example.com/media.mp4']);
    });

    test('openMedia prefers trusted localUri over mediaUrl', () async {
      final file = File(
        p.join(
          Directory.systemTemp.path,
          'enjoy_local_prefers_${DateTime.now().microsecondsSinceEpoch}.mp4',
        ),
      );
      await file.writeAsBytes(const [1]);
      addTearDown(() async {
        if (await file.exists()) await file.delete();
      });
      final localUri = Uri.file(file.path).toString();
      final id = await insertMedia(
        id: 'local-pref-1',
        kind: 'video',
        localUri: localUri,
        mediaUrl: 'https://example.com/should-not-open.mp4',
        md5: 'hash-local-pref',
      );
      final n = container.read(playerControllerProvider.notifier);
      await n.openMedia(id);
      expect(fake.openUris, [localUri]);
    });

    test(
      'openMedia persists video poster from screenshot when thumbnail missing',
      () async {
        const hash =
            '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';
        final id = await insertMedia(id: 'v-cap', kind: 'video', md5: hash);
        fake.screenshotReturnValue = Uint8List.fromList(const [10, 11, 12]);
        final n = container.read(playerControllerProvider.notifier);
        await n.openMedia(id);

        VideoRow? row = await db.videoDao.getById(id);
        final deadline = DateTime.now().add(const Duration(seconds: 5));
        while (row?.thumbnailUrl == null && DateTime.now().isBefore(deadline)) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          row = await db.videoDao.getById(id);
        }

        expect(fake.screenshotCalls, greaterThanOrEqualTo(1));
        expect(row!.thumbnailUrl, isNotNull);
        final thumbFile = File(row.thumbnailUrl!);
        expect(thumbFile.existsSync(), isTrue);
        expect(await thumbFile.readAsBytes(), fake.screenshotReturnValue);

        final session = container.read(playerControllerProvider);
        expect(session?.thumbnailUrl, row.thumbnailUrl);
      },
    );

    test(
      'openMedia skips poster capture when remote thumbnail url set',
      () async {
        final id = await insertMedia(
          id: 'v-remote',
          kind: 'video',
          thumbnailUrl: 'https://cdn.example/x.jpg',
        );
        fake.screenshotReturnValue = Uint8List.fromList(const [1, 2, 3]);
        final n = container.read(playerControllerProvider.notifier);
        await n.openMedia(id);
        await Future<void>.delayed(const Duration(milliseconds: 1200));
        expect(fake.screenshotCalls, 0);
      },
    );

    test(
      'openMedia skips poster capture when local thumbnail file exists',
      () async {
        final tmp = File(
          p.join(
            Directory.systemTemp.path,
            'enjoy_thumb_${DateTime.now().microsecondsSinceEpoch}.jpg',
          ),
        );
        await tmp.writeAsBytes(const [1, 2, 3]);
        final id = await insertMedia(
          id: 'v-has-thumb',
          kind: 'video',
          thumbnailUrl: tmp.path,
        );
        fake.screenshotReturnValue = Uint8List.fromList(const [9, 9, 9]);
        final n = container.read(playerControllerProvider.notifier);
        await n.openMedia(id);
        await Future<void>.delayed(const Duration(milliseconds: 1200));
        expect(fake.screenshotCalls, 0);
      },
    );

    test('openMedia does not capture poster for audio', () async {
      final id = await insertMedia(id: 'a-cap');
      fake.screenshotReturnValue = Uint8List.fromList(const [1]);
      final n = container.read(playerControllerProvider.notifier);
      await n.openMedia(id);
      await Future<void>.delayed(const Duration(milliseconds: 800));
      expect(fake.screenshotCalls, 0);
    });

    test('openMedia applies default volume and rate to engine', () async {
      final id = await insertMedia(id: 'prefs-1');
      final n = container.read(playerControllerProvider.notifier);
      await n.openMedia(id);
      expect(fake.lastVolume, 1.0);
      expect(fake.lastRate, 1.0);
    });

    test('clear stops engine and clears session', () async {
      final id = await insertMedia(id: 'clr-1');
      final n = container.read(playerControllerProvider.notifier);
      await n.openMedia(id);
      expect(container.read(playerControllerProvider), isNotNull);
      await n.clear();
      expect(container.read(playerControllerProvider), isNull);
      expect(fake.stopCallCount, greaterThan(0));
    });

    test(
      'Linux YouTube open throws typed unavailable, keeps engines untouched, '
      'and later audio still opens (ADR-0048 regression)',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.linux;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);
        final now = DateTime.now();
        await db.videoDao.insertRow(
          VideoRow(
            id: 'yt-linux-1',
            vid: 'dQw4w9WgXcQ',
            provider: 'youtube',
            title: 'YouTube on Linux',
            description: null,
            thumbnailUrl: null,
            durationSeconds: 212,
            language: 'en',
            source: 'youtube',
            localUri: null,
            md5: null,
            size: null,
            mediaUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
            syncStatus: null,
            serverUpdatedAt: null,
            createdAt: now,
            updatedAt: now,
          ),
        );
        final audioId = await insertMedia(id: 'audio-after-yt');

        final n = container.read(playerControllerProvider.notifier);
        final revBefore = container.read(playerEngineRevProvider);

        await expectLater(
          n.openMedia('yt-linux-1'),
          throwsA(isA<YouTubePlaybackUnavailableException>()),
        );

        expect(n.ownedEngine, isNull);
        expect(container.read(playerEngineRevProvider), revBefore);
        expect(fake.openUris, isEmpty);

        await n.openMedia(audioId);
        expect(container.read(playerControllerProvider)?.mediaId, audioId);
        expect(fake.openUris, isNotEmpty);
      },
    );

    test('YouTube placeholder-row open refreshes metadata without self-dep '
        'Ref read (issue #676 regression)', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      final repo = _FakeYoutubeRefreshRepository(db);
      final ytContainer = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          playerEngineTestDoubleProvider.overrideWithValue(fake),
          transcriptRepositoryProvider.overrideWithValue(
            TranscriptRepository(db),
          ),
          mediaLibraryRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(ytContainer.dispose);

      final id = await insertYoutubeRow(
        db,
        id: 'yt-placeholder',
        title: 'YouTube video dQw4w9WgXcQ',
        thumbnailUrl: null,
      );

      final n = ytContainer.read(playerControllerProvider.notifier);
      await n.openMedia(id);
      await _settleYoutubeRefresh(fake);

      expect(repo.refreshCalls, contains(id));
      expect(
        ytContainer.read(playerControllerProvider)?.mediaTitle,
        'Refreshed title',
      );
    });

    test('YouTube metadata refresh failure is logged, never escapes as an '
        'unhandled async error (issue #676)', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      final repo = _ThrowingYoutubeRefreshRepository(db);
      final ytContainer = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          playerEngineTestDoubleProvider.overrideWithValue(fake),
          transcriptRepositoryProvider.overrideWithValue(
            TranscriptRepository(db),
          ),
          mediaLibraryRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(ytContainer.dispose);

      final id = await insertYoutubeRow(
        db,
        id: 'yt-boom',
        title: 'YouTube video dQw4w9WgXcQ',
        thumbnailUrl: null,
      );

      final n = ytContainer.read(playerControllerProvider.notifier);
      await n.openMedia(id);
      await _settleYoutubeRefresh(fake);

      expect(repo.refreshCalls, contains(id));
      expect(ytContainer.read(playerControllerProvider)?.mediaId, id);
    });

    test('clear retains YoutubePlayerEngine without rev bump', () async {
      Future<String> insertYoutube({required String id}) async {
        final now = DateTime.now();
        await db.videoDao.insertRow(
          VideoRow(
            id: id,
            vid: 'dQw4w9WgXcQ',
            provider: 'youtube',
            title: 'YouTube test',
            description: null,
            thumbnailUrl: 'https://i.ytimg.com/vi/dQw4w9WgXcQ/mqdefault.jpg',
            durationSeconds: 212,
            language: 'en',
            source: 'youtube',
            localUri: null,
            md5: null,
            size: null,
            mediaUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
            syncStatus: null,
            serverUpdatedAt: null,
            createdAt: now,
            updatedAt: now,
          ),
        );
        return id;
      }

      final ytContainer = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          transcriptRepositoryProvider.overrideWithValue(
            TranscriptRepository(db),
          ),
        ],
      );
      addTearDown(ytContainer.dispose);

      final id = await insertYoutube(id: 'yt-retain');
      final n = ytContainer.read(playerControllerProvider.notifier);
      await n.openMedia(id);
      final revAfterOpen = ytContainer.read(playerEngineRevProvider);

      expect(n.engine, isA<YoutubePlayerEngine>());
      await n.clear();

      expect(ytContainer.read(playerControllerProvider), isNull);
      expect(n.engine, isA<YoutubePlayerEngine>());
      expect(ytContainer.read(playerEngineRevProvider), revAfterOpen);
    });

    test(
      'openMedia persists decoded duration when video row duration is zero',
      () async {
        final id = await insertMedia(
          id: 'v-dur0',
          kind: 'video',
          durationSeconds: 0,
        );
        final n = container.read(playerControllerProvider.notifier);
        await n.openMedia(id);
        fake.emitDuration(const Duration(seconds: 91));
        await Future<void>.delayed(const Duration(milliseconds: 120));
        final row = await db.videoDao.getById(id);
        expect(row!.durationSeconds, 91);
      },
    );

    test(
      'RepeatMode.single loops on completion: seek-to-zero + play per fire',
      () async {
        final id = await insertMedia(id: 'eom-single');
        await container
            .read(playerPreferencesCtrlProvider.notifier)
            .setRepeatMode(RepeatMode.single);
        final n = container.read(playerControllerProvider.notifier);
        await n.openMedia(id);
        fake.emitDuration(const Duration(seconds: 10));

        fake.emitCompleted();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(fake.seekCalls, contains(Duration.zero));
        expect(fake.playCallCount, greaterThanOrEqualTo(1));

        final seeksAfterFirst = fake.seekCalls.length;

        fake.emitCompleted();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(
          fake.seekCalls.length,
          seeksAfterFirst + 1,
          reason: 'second completion triggers exactly one more seek',
        );
      },
    );

    test(
      'duplicate completed events do not double-seek (single-flight)',
      () async {
        final id = await insertMedia(id: 'eom-dup');
        await container
            .read(playerPreferencesCtrlProvider.notifier)
            .setRepeatMode(RepeatMode.single);
        final n = container.read(playerControllerProvider.notifier);
        await n.openMedia(id);

        fake.emitCompleted();
        fake.emitCompleted();
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final seeksAfterBurst = fake.seekCalls.length;
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(
          fake.seekCalls.length,
          seeksAfterBurst,
          reason: 'duplicate completions must not cause extra seeks',
        );
      },
    );

    test(
      'late completion after gen bump is a no-op (no stray seek on next media)',
      () async {
        final idA = await insertMedia(id: 'eom-late-a');
        final idB = await insertMedia(id: 'eom-late-b');
        await container
            .read(playerPreferencesCtrlProvider.notifier)
            .setRepeatMode(RepeatMode.single);
        final n = container.read(playerControllerProvider.notifier);
        await n.openMedia(idA);

        n.abandonPendingOpen();

        fake.emitCompleted();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(
          fake.seekCalls.where((d) => d == Duration.zero).length,
          0,
          reason: 'stale completion must not cause a seek',
        );

        await n.openMedia(idB);
        expect(container.read(playerControllerProvider)?.mediaId, idB);
      },
    );

    test('RepeatMode.none stops the loop (no seek, no advance)', () async {
      final id = await insertMedia(id: 'eom-none');
      await container
          .read(playerPreferencesCtrlProvider.notifier)
          .setRepeatMode(RepeatMode.none);
      final n = container.read(playerControllerProvider.notifier);
      await n.openMedia(id);

      final seeksBefore = fake.seekCalls.length;
      fake.emitCompleted();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(
        fake.seekCalls.length,
        seeksBefore,
        reason: 'RepeatMode.none must not seek on completion',
      );

      fake.emitCompleted();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(fake.seekCalls.length, seeksBefore);
    });

    test(
      'RepeatMode.segment seeks to echo start on completion when echo active',
      () async {
        final id = await insertMedia(id: 'eom-segment');
        await container
            .read(playerPreferencesCtrlProvider.notifier)
            .setRepeatMode(RepeatMode.segment);
        final n = container.read(playerControllerProvider.notifier);
        await n.openMedia(id);
        fake.emitDuration(const Duration(seconds: 30));

        container
            .read(echoModeProvider.notifier)
            .activate(
              startLineIndex: 0,
              endLineIndex: 1,
              startTimeSeconds: 3,
              endTimeSeconds: 8,
            );

        fake.emitCompleted();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(
          fake.seekCalls.last,
          const Duration(seconds: 3),
          reason: 'segment repeat must seek to echo start',
        );
        expect(fake.playCallCount, greaterThanOrEqualTo(1));
      },
    );

    test(
      'RepeatMode.segment without echo falls back to stop (no seek)',
      () async {
        final id = await insertMedia(id: 'eom-seg-noecho');
        await container
            .read(playerPreferencesCtrlProvider.notifier)
            .setRepeatMode(RepeatMode.segment);
        final n = container.read(playerControllerProvider.notifier);
        await n.openMedia(id);

        final seeksBefore = fake.seekCalls.length;
        fake.emitCompleted();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(
          fake.seekCalls.length,
          seeksBefore,
          reason: 'segment repeat without echo must not seek',
        );
      },
    );

    test(
      'clear cancels the completion loop (no stray seek after clear)',
      () async {
        final id = await insertMedia(id: 'eom-clear');
        await container
            .read(playerPreferencesCtrlProvider.notifier)
            .setRepeatMode(RepeatMode.single);
        final n = container.read(playerControllerProvider.notifier);
        await n.openMedia(id);

        await n.clear();
        final seeksAfterClear = fake.seekCalls.length;

        fake.emitCompleted();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(
          fake.seekCalls.length,
          seeksAfterClear,
          reason: 'completion after clear must not seek',
        );
      },
    );

    test(
      'user seek bumps playbackGen — stale completion during seek is discarded',
      () async {
        final id = await insertMedia(id: 'eom-seek');
        await container
            .read(playerPreferencesCtrlProvider.notifier)
            .setRepeatMode(RepeatMode.single);
        final n = container.read(playerControllerProvider.notifier);
        await n.openMedia(id);

        fake.emitCompleted();
        await n.seekToSeconds(5.0);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(fake.seekCalls, contains(const Duration(seconds: 5)));
      },
    );
  });

  group('PlayerController.warmYoutubeSurface Linux opt-out (ADR-0048)', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() {
      db = AppDatabase(executor: NativeDatabase.memory());
      container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
    });

    tearDown(() async {
      debugDefaultTargetPlatformOverride = null;
      await pumpEventQueue();
      container.dispose();
      await db.close();
    });

    test('does not install the YouTube engine when opted out', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;

      final n = container.read(playerControllerProvider.notifier);
      n.warmYoutubeSurface();

      expect(
        n.ownedEngine,
        isNull,
        reason: 'feed-scroll warm must not install a YouTube engine on Linux',
      );
      expect(
        container.read(playerEngineRevProvider),
        0,
        reason: 'no engine swap happened, so the host rev must not bump',
      );
    });

    test('installs and warms a YouTube engine on other targets', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      final n = container.read(playerControllerProvider.notifier);
      n.warmYoutubeSurface();

      expect(n.ownedEngine, isA<YoutubePlayerEngine>());
      expect(container.read(playerEngineRevProvider), 1);
    });
  });

  group('PlayerController.warmYoutubeSurface idle gate (issue #657)', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() {
      db = AppDatabase(executor: NativeDatabase.memory());
      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          transcriptRepositoryProvider.overrideWithValue(
            TranscriptRepository(db),
          ),
        ],
      );
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
    });

    tearDown(() async {
      debugDefaultTargetPlatformOverride = null;
      await pumpEventQueue();
      container.dispose();
      await db.close();
    });

    Future<String> insertYoutube({required String id}) async {
      final now = DateTime.now();
      await db.videoDao.insertRow(
        VideoRow(
          id: id,
          vid: 'dQw4w9WgXcQ',
          provider: 'youtube',
          title: 'YouTube test',
          description: null,
          thumbnailUrl: 'https://i.ytimg.com/vi/dQw4w9WgXcQ/mqdefault.jpg',
          durationSeconds: 212,
          language: 'en',
          source: 'youtube',
          localUri: null,
          md5: null,
          size: null,
          mediaUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
          syncStatus: null,
          serverUpdatedAt: null,
          createdAt: now,
          updatedAt: now,
        ),
      );
      return id;
    }

    PlaybackSession liveSession(String mediaId) {
      final now = DateTime.now();
      return PlaybackSession(
        mediaId: mediaId,
        dexieTargetType: 'Audio',
        mediaType: 'audio',
        mediaTitle: 't',
        durationSeconds: 600,
        currentTimeSeconds: 12,
        currentSegmentIndex: 0,
        language: 'en',
        startedAt: now,
        lastActiveAt: now,
      );
    }

    test('keeps a parked local engine instead of installing YouTube', () {
      final n = container.read(playerControllerProvider.notifier);
      final parked = FakePlayerEngine();
      n.ownedEngine = parked;
      final revBefore = container.read(playerEngineRevProvider);

      n.warmYoutubeSurface();

      expect(
        identical(n.ownedEngine, parked),
        isTrue,
        reason: 'warming must not swap out a parked local engine',
      );
      expect(
        parked.disposeCallCount,
        0,
        reason: 'disposing mpv outside the open path wedges the native pump',
      );
      expect(parked.warmVideoSurfaceCallCount, 0);
      expect(
        container.read(playerEngineRevProvider),
        revBefore,
        reason: 'no engine swap happened, so the host rev must not bump',
      );
    });

    test('keeps the live engine while a local session is open', () {
      final n = container.read(playerControllerProvider.notifier);
      final live = FakePlayerEngine();
      n.ownedEngine = live;
      n.publishSession(liveSession('local-live'));
      final revBefore = container.read(playerEngineRevProvider);

      n.warmYoutubeSurface();

      expect(
        identical(n.ownedEngine, live),
        isTrue,
        reason: 'a live session must keep its engine — no mid-playback dispose',
      );
      expect(
        live.disposeCallCount,
        0,
        reason: 'playback must be unaffected by feed-scroll warming',
      );
      expect(live.warmVideoSurfaceCallCount, 0);
      expect(container.read(playerEngineRevProvider), revBefore);
      expect(container.read(playerControllerProvider)?.mediaId, 'local-live');
    });

    test('does not install under an in-flight open', () async {
      final id = await insertYoutube(id: 'yt-inflight');
      final n = container.read(playerControllerProvider.notifier);
      final revBefore = container.read(playerEngineRevProvider);

      final open = n.openMedia(id);
      n.warmYoutubeSurface();

      expect(
        n.ownedEngine,
        isNull,
        reason: 'the in-flight open installs the engine, not the warm',
      );
      expect(container.read(playerEngineRevProvider), revBefore);

      await open;
      expect(n.ownedEngine, isA<YoutubePlayerEngine>());
    });

    test('still installs and warms YouTube when idle with no owned engine', () {
      final n = container.read(playerControllerProvider.notifier);
      n.warmYoutubeSurface();

      final installed = n.ownedEngine;
      expect(installed, isA<YoutubePlayerEngine>());
      expect(container.read(playerEngineRevProvider), 1);

      n.warmYoutubeSurface();
      expect(identical(n.ownedEngine, installed), isTrue);
      expect(container.read(playerEngineRevProvider), 1);
    });

    test(
      'reuses a retained YouTube engine without dispose or swap churn',
      () async {
        final id = await insertYoutube(id: 'yt-retain-warm');
        final n = container.read(playerControllerProvider.notifier);
        await n.openMedia(id);
        final retained = n.ownedEngine;
        expect(retained, isA<YoutubePlayerEngine>());
        await n.clear();
        expect(container.read(playerControllerProvider), isNull);

        final revBefore = container.read(playerEngineRevProvider);
        n.warmYoutubeSurface();

        expect(
          identical(n.ownedEngine, retained),
          isTrue,
          reason: 'an idle YouTube engine must be warmed, not replaced',
        );
        expect(
          container.read(playerEngineRevProvider),
          revBefore,
          reason: 're-warming must not swap engines',
        );
      },
    );
  });

  group('PlayerController.warmYoutubeSurface idle eviction (issue #810 G)', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() {
      db = AppDatabase(executor: NativeDatabase.memory());
      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          transcriptRepositoryProvider.overrideWithValue(
            TranscriptRepository(db),
          ),
        ],
      );
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      PlayerController.warmedYoutubeEvictionDelay = const Duration(
        milliseconds: 50,
      );
    });

    tearDown(() async {
      debugDefaultTargetPlatformOverride = null;
      PlayerController.warmedYoutubeEvictionDelay =
          kWarmedYoutubeSurfaceEvictionDelay;
      await pumpEventQueue();
      container.dispose();
      await db.close();
    });

    Future<String> insertYoutube({required String id}) async {
      final now = DateTime.now();
      await db.videoDao.insertRow(
        VideoRow(
          id: id,
          vid: 'dQw4w9WgXcQ',
          provider: 'youtube',
          title: 'YouTube test',
          description: null,
          thumbnailUrl: 'https://i.ytimg.com/vi/dQw4w9WgXcQ/mqdefault.jpg',
          durationSeconds: 212,
          language: 'en',
          source: 'youtube',
          localUri: null,
          md5: null,
          size: null,
          mediaUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
          syncStatus: null,
          serverUpdatedAt: null,
          createdAt: now,
          updatedAt: now,
        ),
      );
      return id;
    }

    test('evicts the warmed engine after the idle window', () async {
      final n = container.read(playerControllerProvider.notifier);
      n.warmYoutubeSurface();
      expect(n.ownedEngine, isA<YoutubePlayerEngine>());
      expect(container.read(playerEngineRevProvider), 1);

      await Future<void>.delayed(const Duration(milliseconds: 250));
      await pumpEventQueue();

      expect(
        n.ownedEngine,
        isNull,
        reason: 'the warmed engine and its WebView must not persist forever',
      );
      expect(container.read(playerEngineRevProvider), 2);
    });

    test('an open cancels the eviction timer', () async {
      final id = await insertYoutube(id: 'yt-evict-open');
      final n = container.read(playerControllerProvider.notifier);
      n.warmYoutubeSurface();
      final warmed = n.ownedEngine;

      await n.openMedia(id);
      await Future<void>.delayed(const Duration(milliseconds: 250));
      await pumpEventQueue();

      expect(
        identical(n.ownedEngine, warmed),
        isTrue,
        reason: 'an opened engine must never be evicted out from playback',
      );
      expect(container.read(playerControllerProvider)?.mediaId, id);
    });

    test('re-warming re-arms the idle window', () async {
      final n = container.read(playerControllerProvider.notifier);
      n.warmYoutubeSurface();
      final warmed = n.ownedEngine;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      n.warmYoutubeSurface();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(
        identical(n.ownedEngine, warmed),
        isTrue,
        reason: 'still inside the re-armed window',
      );

      await Future<void>.delayed(const Duration(milliseconds: 250));
      await pumpEventQueue();
      expect(n.ownedEngine, isNull);
    });

    test(
      'a failing surface detach still completes the engine dispose',
      () async {
        final n = container.read(playerControllerProvider.notifier);
        final engine = _EvictionSeamEngine(detachError: StateError('detach'));
        n.ownedEngine = engine;
        n.warmYoutubeSurface();

        await Future<void>.delayed(const Duration(milliseconds: 300));
        await pumpEventQueue();

        expect(
          n.ownedEngine,
          isNull,
          reason: 'the identity slot must stay empty after a failed detach',
        );
        expect(
          engine.disposeCalled,
          isTrue,
          reason: 'dispose must land even when the detach wait throws',
        );
      },
    );

    test('a failing engine dispose after eviction stays contained', () async {
      final n = container.read(playerControllerProvider.notifier);
      final engine = _EvictionSeamEngine(disposeError: StateError('dispose'));
      n.ownedEngine = engine;
      n.warmYoutubeSurface();

      await Future<void>.delayed(const Duration(milliseconds: 300));
      await pumpEventQueue();

      expect(n.ownedEngine, isNull);
      expect(engine.disposeCalled, isTrue);
    });
  });
}

/// Emits `buffering=false` repeatedly for a short window so the unawaited
/// metadata refresh catches it whenever it subscribes (its first DB read
/// yields past the open call), then lets the whole side effect drain.
Future<void> _settleYoutubeRefresh(FakePlayerEngine fake) async {
  for (var i = 0; i < 20; i++) {
    fake.emitBuffering(false);
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  await pumpEventQueue();
}

/// Seeds a YouTube-provider video row the resolver turns into a
/// [YoutubePlayableSource] (same shape as the side-effects test fixture).
Future<String> insertYoutubeRow(
  AppDatabase db, {
  required String id,
  required String title,
  String? thumbnailUrl,
}) async {
  final now = DateTime.now();
  await db.videoDao.insertRow(
    VideoRow(
      id: id,
      vid: 'dQw4w9WgXcQ',
      provider: 'youtube',
      title: title,
      description: null,
      thumbnailUrl: thumbnailUrl,
      durationSeconds: 212,
      language: 'en',
      source: 'youtube',
      localUri: null,
      md5: null,
      size: null,
      mediaUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      syncStatus: null,
      serverUpdatedAt: null,
      createdAt: now,
      updatedAt: now,
    ),
  );
  return id;
}

/// Returns a fixed metadata patch instead of hitting oEmbed / the DB write.
class _FakeYoutubeRefreshRepository extends MediaLibraryRepository {
  _FakeYoutubeRefreshRepository(AppDatabase db)
    : super(db, FileStorage(), enqueueSync: null);

  final List<String> refreshCalls = [];

  @override
  Future<YoutubeMetadataPatch?> refreshYoutubeMetadataIfNeeded(
    String mediaId,
  ) async {
    refreshCalls.add(mediaId);
    return (title: 'Refreshed title', thumbnailUrl: null);
  }
}

/// Throws like a failing oEmbed fetch / DB write would.
class _ThrowingYoutubeRefreshRepository extends MediaLibraryRepository {
  _ThrowingYoutubeRefreshRepository(AppDatabase db)
    : super(db, FileStorage(), enqueueSync: null);

  final List<String> refreshCalls = [];

  @override
  Future<YoutubeMetadataPatch?> refreshYoutubeMetadataIfNeeded(
    String mediaId,
  ) async {
    refreshCalls.add(mediaId);
    throw StateError('oembed_boom');
  }
}

/// Warms like a stock engine but lets a test fail the detach wait or the
/// dispose, installed through the plain `ownedEngine` field seam.
class _EvictionSeamEngine extends YoutubePlayerEngine {
  _EvictionSeamEngine({this.detachError, this.disposeError});

  final Object? detachError;
  final Object? disposeError;
  bool disposeCalled = false;

  @override
  Future<void> awaitSurfaceDetached() async {
    final error = detachError;
    if (error != null) throw error;
  }

  @override
  Future<void> dispose() async {
    disposeCalled = true;
    final error = disposeError;
    if (error != null) throw error;
  }
}
