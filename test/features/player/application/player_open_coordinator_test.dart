import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';
import 'package:enjoy_player/features/player/application/playback_session_persister.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/features/player/application/player_engine.dart';
import 'package:enjoy_player/features/player/application/player_engine_test_double_provider.dart';
import 'package:enjoy_player/features/player/application/player_open_coordinator.dart';
import 'package:enjoy_player/features/player/application/video_poster_capture_service.dart';
import 'package:enjoy_player/features/player/application/position_buckets.dart';
import 'package:enjoy_player/features/player/domain/playback_session.dart';
import 'package:enjoy_player/features/transcript/application/transcript_blur_mode_provider.dart';
import 'package:enjoy_player/features/transcript/application/transcript_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import '../../../support/fake_player_engine.dart';
import '../../../support/test_path_provider.dart';

/// Echo-session DAO that records entries and can hold the read in flight —
/// the barrier-controlled double from docs/perf-measurement.md (Pattern 3):
/// count method entries instead of racing concurrent calls.
class _CountingEchoSessionDao extends EchoSessionDao {
  _CountingEchoSessionDao(super.db);

  int getLatestCalls = 0;

  /// When set, the read only resolves once the test releases it.
  Completer<void>? entryGate;

  @override
  Future<EchoSessionRow?> getLatestForTarget(
    String targetType,
    String targetId,
  ) {
    getLatestCalls++;
    final read = super.getLatestForTarget(targetType, targetId);
    final gate = entryGate;
    if (gate == null) return read;
    return gate.future.then((_) => read);
  }
}

/// [AppDatabase] exposing the counting echo-session DAO.
class _CountingEchoDb extends AppDatabase {
  _CountingEchoDb({required super.executor});

  late final _CountingEchoSessionDao countingDao = _CountingEchoSessionDao(
    this,
  );

  @override
  EchoSessionDao get echoSessionDao => countingDao;
}

/// [VideoPosterCaptureService] double: records each capture request the open
/// choreography schedules and hands the `onSessionThumbnail` callback to the
/// test, which fires it late to reproduce the stale-capture race.
class _StubPosterCaptureService extends VideoPosterCaptureService {
  _StubPosterCaptureService(super.ref);

  final requests = <String, void Function(String absoluteThumbPath)>{};

  @override
  void scheduleCapture({
    required String mediaId,
    required VideoRow video,
    required int restoredPositionMs,
    required int gen,
    required int Function() currentOpenGeneration,
    required String? Function() currentSessionMediaId,
    required double? Function() sessionDurationSeconds,
    required PlayerEngine activeEngine,
    required void Function(String absoluteThumbPath) onSessionThumbnail,
  }) {
    requests[mediaId] = onSessionThumbnail;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('runPlayerOpen engine.open timeout', () {
    late AppDatabase db;
    late FakePlayerEngine fake;
    late ProviderContainer container;
    late PathProviderPlatform originalPathProvider;

    setUp(() async {
      originalPathProvider = PathProviderPlatform.instance;
      PathProviderPlatform.instance = TestPathProvider(
        Directory.systemTemp.createTempSync('enjoy_player_open_coord').path,
      );
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

      final now = DateTime.now();
      final file = File(
        p.join(
          Directory.systemTemp.path,
          'enjoy_open_coord_${DateTime.now().microsecondsSinceEpoch}.mp3',
        ),
      );
      await file.writeAsBytes([1]);
      addTearDown(() async {
        if (await file.exists()) await file.delete();
      });
      await db.audioDao.insertRow(
        AudioRow(
          id: 'hang-1',
          aid: 'x',
          provider: 'user',
          title: 't',
          description: null,
          thumbnailUrl: null,
          durationSeconds: 600,
          language: 'en',
          translationKey: null,
          sourceText: null,
          voice: null,
          source: null,
          localUri: Uri.file(file.path).toString(),
          md5: null,
          size: 1,
          mediaUrl: null,
          syncStatus: null,
          serverUpdatedAt: null,
          createdAt: now,
          updatedAt: now,
        ),
      );
    });

    tearDown(() async {
      PathProviderPlatform.instance = originalPathProvider;
      await pumpEventQueue();
      container.dispose();
      await db.close();
      await fake.dispose();
    });

    test('a wedged engine.open fails with TimeoutException instead of hanging, '
        'and invalidates the open generation', () async {
      final hang = Completer<void>();
      fake.openDelay = () => hang.future;

      final controller = container.read(playerControllerProvider.notifier);
      final genBefore = controller.openGeneration;

      await expectLater(
        runPlayerOpen(
          controller,
          'hang-1',
          openTimeout: const Duration(milliseconds: 50),
        ),
        throwsA(isA<TimeoutException>()),
      );

      expect(controller.session, isNull);
      expect(controller.openGeneration, greaterThan(genBefore));

      hang.complete();
      await pumpEventQueue();
      expect(controller.session, isNull);
    });

    test(
      'a wedged first engine.open retries and still publishes the session',
      () async {
        var attempts = 0;
        fake.openDelay = () async {
          attempts++;
          if (attempts == 1) {
            await Completer<void>().future;
          }
        };

        final controller = container.read(playerControllerProvider.notifier);
        await runPlayerOpen(
          controller,
          'hang-1',
          openTimeout: const Duration(milliseconds: 50),
        );

        expect(attempts, 2);
        expect(
          controller.session,
          isNotNull,
          reason: 'session must publish after the open retry',
        );
      },
    );

    test(
      'a wedged post-open command degrades instead of hanging the open',
      () async {
        final now = DateTime.now();
        await db.echoSessionDao.upsert(
          EchoSessionRow(
            id: 'es-wedge-1',
            targetType: 'Audio',
            targetId: 'hang-1',
            language: 'en',
            currentTimeMs: 120000,
            playbackRate: 1,
            volume: 1,
            recordingsCount: 0,
            recordingsDurationMs: 0,
            currentSegmentIndex: -1,
            echoActive: false,
            echoStartLine: -1,
            echoEndLine: -1,
            blurActive: false,
            createdAt: now,
            updatedAt: now,
            startedAt: now,
            lastActiveAt: now,
          ),
        );
        final gate = Completer<void>();
        fake.seekGate = gate;
        addTearDown(() {
          if (!gate.isCompleted) gate.complete();
        });

        final controller = container.read(playerControllerProvider.notifier);
        await runPlayerOpen(
          controller,
          'hang-1',
          engineCommandTimeout: const Duration(milliseconds: 50),
        );

        expect(
          controller.session,
          isNotNull,
          reason: 'session must publish despite the never-completing seek',
        );
        expect(fake.seekCalls, isNotEmpty, reason: 'the seek was attempted');
      },
    );
  });

  group('runPlayerOpen typed failure on unplayable media', () {
    late AppDatabase db;
    late FakePlayerEngine fake;
    late ProviderContainer container;
    late PathProviderPlatform originalPathProvider;

    setUp(() async {
      originalPathProvider = PathProviderPlatform.instance;
      PathProviderPlatform.instance = TestPathProvider(
        Directory.systemTemp
            .createTempSync('enjoy_player_open_unplayable')
            .path,
      );
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

      final now = DateTime.now();
      await db.audioDao.insertRow(
        AudioRow(
          id: 'unplayable-1',
          aid: 'x',
          provider: 'user',
          title: 'gone',
          description: null,
          thumbnailUrl: null,
          durationSeconds: 600,
          language: 'en',
          translationKey: null,
          sourceText: null,
          voice: null,
          source: null,
          localUri: Uri.file(
            p.join(
              Directory.systemTemp.path,
              'enjoy_gone_${DateTime.now().microsecondsSinceEpoch}.mp3',
            ),
          ).toString(),
          md5: null,
          size: 1,
          mediaUrl: null,
          syncStatus: null,
          serverUpdatedAt: null,
          createdAt: now,
          updatedAt: now,
        ),
      );
    });

    tearDown(() async {
      PathProviderPlatform.instance = originalPathProvider;
      await pumpEventQueue();
      container.dispose();
      await db.close();
      await fake.dispose();
    });

    test(
      'an unknown media id fails with StateError instead of a silent success',
      () async {
        await expectLater(
          runPlayerOpen(
            container.read(playerControllerProvider.notifier),
            'missing-id',
          ),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('No playable source for media missing-id'),
            ),
          ),
        );
        expect(
          container.read(playerControllerProvider),
          isNull,
          reason: 'no session may publish for an unknown media id',
        );
        expect(fake.openUris, isEmpty, reason: 'no engine command may run');
      },
    );

    test(
      'an unplayable row (missing file, no URL, no hash) throws StateError',
      () async {
        await expectLater(
          runPlayerOpen(
            container.read(playerControllerProvider.notifier),
            'unplayable-1',
          ),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('No playable source for media unplayable-1'),
            ),
          ),
        );
        expect(container.read(playerControllerProvider), isNull);
        expect(fake.openUris, isEmpty);
      },
    );
  });

  group('runPlayerOpen persister hand-off (issue #653)', () {
    late AppDatabase db;
    late FakePlayerEngine fake;
    late ProviderContainer container;
    late PathProviderPlatform originalPathProvider;

    setUp(() async {
      originalPathProvider = PathProviderPlatform.instance;
      PathProviderPlatform.instance = TestPathProvider(
        Directory.systemTemp.createTempSync('enjoy_player_open_flush').path,
      );
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

      final now = DateTime.now();
      for (final id in const ['media-a', 'media-b']) {
        final file = File(
          p.join(
            Directory.systemTemp.path,
            'enjoy_flush_${id}_${DateTime.now().microsecondsSinceEpoch}.mp3',
          ),
        );
        await file.writeAsBytes([1]);
        addTearDown(() async {
          if (await file.exists()) await file.delete();
        });
        await db.audioDao.insertRow(
          AudioRow(
            id: id,
            aid: 'x-$id',
            provider: 'user',
            title: id,
            description: null,
            thumbnailUrl: null,
            durationSeconds: 600,
            language: 'en',
            translationKey: null,
            sourceText: null,
            voice: null,
            source: null,
            localUri: Uri.file(file.path).toString(),
            md5: null,
            size: 1,
            mediaUrl: null,
            syncStatus: null,
            serverUpdatedAt: null,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }

      await db.echoSessionDao.upsert(
        EchoSessionRow(
          id: 'es-b',
          targetType: 'Audio',
          targetId: 'media-b',
          language: 'en',
          currentTimeMs: 5000,
          playbackRate: 1,
          volume: 1,
          recordingsCount: 0,
          recordingsDurationMs: 0,
          currentSegmentIndex: -1,
          echoActive: true,
          echoStartLine: 7,
          echoEndLine: 9,
          echoStartMs: 30000,
          echoEndMs: 40000,
          blurActive: false,
          createdAt: now,
          updatedAt: now,
          startedAt: now,
          lastActiveAt: now,
        ),
      );
    });

    tearDown(() async {
      PathProviderPlatform.instance = originalPathProvider;
      await pumpEventQueue();
      container.dispose();
      await db.close();
      await fake.dispose();
    });

    PlaybackSession sessionA() {
      final now = DateTime(2026, 8, 30);
      return PlaybackSession(
        mediaId: 'media-a',
        dexieTargetType: 'Audio',
        mediaType: 'audio',
        mediaTitle: 'A',
        durationSeconds: 600,
        currentTimeSeconds: 42,
        currentSegmentIndex: 3,
        language: 'en',
        startedAt: now,
        lastActiveAt: now,
      );
    }

    test(
      'a pending write keeps the previous media echo/blur when new media opens',
      () async {
        final controller = container.read(playerControllerProvider.notifier);
        final persister = container.read(playbackSessionPersisterProvider);

        container
            .read(echoModeProvider.notifier)
            .activate(
              startLineIndex: 2,
              endLineIndex: 4,
              startTimeSeconds: 10,
              endTimeSeconds: 20,
            );
        container.read(transcriptBlurModeProvider.notifier).activate();

        persister.schedule(
          mediaId: 'media-a',
          dexieTargetType: 'Audio',
          session: sessionA(),
        );

        controller.publishSession(sessionA());

        await runPlayerOpen(controller, 'media-b');
        final echo = container.read(echoModeProvider);
        expect(echo.active, isTrue);
        expect(
          echo.startTimeSeconds,
          30,
          reason: 'B restored echo must own the providers now',
        );
        expect(container.read(transcriptBlurModeProvider), isFalse);

        await Future<void>.delayed(
          const Duration(milliseconds: kPlaybackSessionDebounceMs + 200),
        );
        await pumpEventQueue();

        final rowA = await db.echoSessionDao.getLatestForTarget(
          'Audio',
          'media-a',
        );
        expect(rowA, isNotNull, reason: 'the open must flush media A');
        expect(rowA!.currentTimeMs, 42000);
        expect(rowA.currentSegmentIndex, 3);
        expect(rowA.echoActive, isTrue);
        expect(rowA.echoStartLine, 2);
        expect(rowA.echoEndLine, 4);
        expect(rowA.echoStartMs, 10000);
        expect(rowA.echoEndMs, 20000);
        expect(rowA.blurActive, isTrue);
      },
    );
  });

  group('OpenSteps', () {
    test('run completes a step and returns its result while current', () async {
      final steps = OpenSteps(isStale: () => false);
      final value = await steps.run('x', () async => 7);
      expect(value, 7);
    });

    test('runBounded completes when the step completes', () async {
      var ran = false;
      final steps = OpenSteps(isStale: () => false);
      await steps.runBounded('x', () async => ran = true);
      expect(ran, isTrue);
    });

    test('a wedged step times out, logs, and does not throw', () async {
      final logs = <String>[];
      final steps = OpenSteps(isStale: () => false, logWarning: logs.add);
      await steps.runBounded(
        'wedged step',
        () => Completer<void>().future,
        limit: const Duration(milliseconds: 20),
      );
      expect(logs, hasLength(1));
      expect(logs.single, contains('wedged step timed out'));
    });

    test('a failing step still throws (only timeouts are swallowed)', () async {
      final steps = OpenSteps(isStale: () => false);
      await expectLater(
        steps.runBounded('boom', () async => throw StateError('boom')),
        throwsStateError,
      );
      await expectLater(
        steps.run('boom', () async => throw StateError('boom')),
        throwsStateError,
      );
    });

    test('a step that completes after a generation bump runs its cleanup and '
        'unwinds', () async {
      var stale = false;
      var cleaned = false;
      final steps = OpenSteps(isStale: () => stale);
      await expectLater(
        steps.run(
          'first',
          () async => stale = true,
          onSuperseded: () async => cleaned = true,
        ),
        throwsA(isA<OpenSupersededException>()),
      );
      expect(
        cleaned,
        isTrue,
        reason: 'onSuperseded must run before the unwind',
      );
    });

    test('later steps never run once the generation moved on', () async {
      var stale = false;
      var secondRan = false;
      final steps = OpenSteps(isStale: () => stale);
      await expectLater(() async {
        await steps.run('first', () async => stale = true);
        await steps.run('second', () async => secondRan = true);
      }, throwsA(isA<OpenSupersededException>()));
      expect(
        secondRan,
        isFalse,
        reason: 'a new step through the mechanism cannot outlive a bump',
      );
    });

    test(
      'a step is skipped outright when the generation already moved on',
      () async {
        var ran = false;
        final steps = OpenSteps(isStale: () => true);
        await expectLater(
          () => steps.run('never', () async => ran = true),
          throwsA(isA<OpenSupersededException>()),
        );
        expect(ran, isFalse);
      },
    );
  });

  group('runPlayerOpen echo-session read overlap (issue #661)', () {
    late _CountingEchoDb db;
    late AppDatabase bystanderDb;
    late FakePlayerEngine fake;
    late ProviderContainer container;
    late PathProviderPlatform originalPathProvider;

    setUp(() async {
      originalPathProvider = PathProviderPlatform.instance;
      PathProviderPlatform.instance = TestPathProvider(
        Directory.systemTemp.createTempSync('enjoy_player_open_overlap').path,
      );
      db = _CountingEchoDb(executor: NativeDatabase.memory());
      bystanderDb = AppDatabase(executor: NativeDatabase.memory());
      fake = FakePlayerEngine();
      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          playerEngineTestDoubleProvider.overrideWithValue(fake),
          transcriptRepositoryProvider.overrideWithValue(
            TranscriptRepository(bystanderDb),
          ),
        ],
      );

      final now = DateTime.now();
      final file = File(
        p.join(
          Directory.systemTemp.path,
          'enjoy_open_overlap_${DateTime.now().microsecondsSinceEpoch}.mp3',
        ),
      );
      await file.writeAsBytes([1]);
      addTearDown(() async {
        if (await file.exists()) await file.delete();
      });
      await db.audioDao.insertRow(
        AudioRow(
          id: 'hang-1',
          aid: 'x',
          provider: 'user',
          title: 't',
          description: null,
          thumbnailUrl: null,
          durationSeconds: 600,
          language: 'en',
          translationKey: null,
          sourceText: null,
          voice: null,
          source: null,
          localUri: Uri.file(file.path).toString(),
          md5: null,
          size: 1,
          mediaUrl: null,
          syncStatus: null,
          serverUpdatedAt: null,
          createdAt: now,
          updatedAt: now,
        ),
      );
    });

    tearDown(() async {
      PathProviderPlatform.instance = originalPathProvider;
      await pumpEventQueue();
      container.dispose();
      await db.close();
      await bystanderDb.close();
      await fake.dispose();
    });

    test(
      'the echo-session read starts while engine.open is still in flight',
      () async {
        final openGate = Completer<void>();
        fake.openDelay = () => openGate.future;
        db.countingDao.entryGate = Completer<void>();
        addTearDown(() {
          if (!db.countingDao.entryGate!.isCompleted) {
            db.countingDao.entryGate!.complete();
          }
          if (!openGate.isCompleted) openGate.complete();
        });

        final controller = container.read(playerControllerProvider.notifier);
        final open = runPlayerOpen(controller, 'hang-1');

        await fake.openEntered.future.timeout(const Duration(seconds: 10));
        expect(fake.openUris, isNotEmpty, reason: 'engine.open was entered');
        expect(
          db.countingDao.getLatestCalls,
          1,
          reason:
              'the echo-session read must start before engine.open resolves',
        );

        db.countingDao.entryGate!.complete();
        openGate.complete();
        await expectLater(open, completes);
        expect(controller.session, isNotNull);
      },
    );

    test(
      'the overlapped read still drives the position + echo restore',
      () async {
        final now = DateTime.now();
        await db.echoSessionDao.upsert(
          EchoSessionRow(
            id: 'es-overlap-1',
            targetType: 'Audio',
            targetId: 'hang-1',
            language: 'en',
            currentTimeMs: 9000,
            playbackRate: 1,
            volume: 1,
            recordingsCount: 0,
            recordingsDurationMs: 0,
            currentSegmentIndex: 5,
            echoActive: true,
            echoStartLine: 1,
            echoEndLine: 3,
            echoStartMs: 1000,
            echoEndMs: 2000,
            blurActive: false,
            createdAt: now,
            updatedAt: now,
            startedAt: now,
            lastActiveAt: now,
          ),
        );

        final controller = container.read(playerControllerProvider.notifier);
        await runPlayerOpen(controller, 'hang-1');

        expect(db.countingDao.getLatestCalls, 1);
        expect(fake.seekCalls, [const Duration(milliseconds: 9000)]);
        expect(controller.session, isNotNull);
        expect(controller.session!.currentTimeSeconds, 9);
        expect(controller.session!.currentSegmentIndex, 5);
      },
    );
  });

  group('runPlayerOpen re-reads the per-user database on a session switch', () {
    test(
      'the second open drives the switched-in database, not the closed one',
      () async {
        final db1 = _CountingEchoDb(executor: NativeDatabase.memory());
        final db2 = _CountingEchoDb(executor: NativeDatabase.memory());
        final bystanderDb = AppDatabase(executor: NativeDatabase.memory());
        final fake = FakePlayerEngine();
        var currentDb = db1;
        final container = ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWith((ref) => currentDb),
            playerEngineTestDoubleProvider.overrideWithValue(fake),
            transcriptRepositoryProvider.overrideWithValue(
              TranscriptRepository(bystanderDb),
            ),
          ],
        );
        var db1Closed = false;
        addTearDown(() async {
          await pumpEventQueue();
          container.dispose();
          if (!db1Closed) await db1.close();
          await db2.close();
          await bystanderDb.close();
          await fake.dispose();
        });

        final file = File(
          p.join(
            Directory.systemTemp.path,
            'enjoy_open_db_switch_${DateTime.now().microsecondsSinceEpoch}.mp3',
          ),
        );
        await file.writeAsBytes([1]);
        addTearDown(() async {
          if (await file.exists()) await file.delete();
        });
        final now = DateTime.now();
        Future<void> insertHangRow(AppDatabase db) => db.audioDao.insertRow(
          AudioRow(
            id: 'hang-1',
            aid: 'x',
            provider: 'user',
            title: 't',
            description: null,
            thumbnailUrl: null,
            durationSeconds: 600,
            language: 'en',
            translationKey: null,
            sourceText: null,
            voice: null,
            source: null,
            localUri: Uri.file(file.path).toString(),
            md5: null,
            size: 1,
            mediaUrl: null,
            syncStatus: null,
            serverUpdatedAt: null,
            createdAt: now,
            updatedAt: now,
          ),
        );
        await insertHangRow(db1);
        await insertHangRow(db2);

        final controller = container.read(playerControllerProvider.notifier);
        await runPlayerOpen(controller, 'hang-1');
        expect(db1.countingDao.getLatestCalls, 1);

        currentDb = db2;
        container.invalidate(appDatabaseProvider);
        await db1.close();
        db1Closed = true;

        await runPlayerOpen(controller, 'hang-1');
        expect(
          db2.countingDao.getLatestCalls,
          1,
          reason: 'the second open must read the switched-in database',
        );
        expect(
          db1.countingDao.getLatestCalls,
          1,
          reason: 'the closed database must not be touched again',
        );
      },
    );
  });

  group('runPlayerOpen stale poster capture', () {
    late AppDatabase db;
    late FakePlayerEngine fake;
    late ProviderContainer container;
    late PathProviderPlatform originalPathProvider;
    late _StubPosterCaptureService poster;

    setUp(() async {
      originalPathProvider = PathProviderPlatform.instance;
      PathProviderPlatform.instance = TestPathProvider(
        Directory.systemTemp.createTempSync('enjoy_player_open_poster').path,
      );
      db = AppDatabase(executor: NativeDatabase.memory());
      fake = FakePlayerEngine();
      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          playerEngineTestDoubleProvider.overrideWithValue(fake),
          transcriptRepositoryProvider.overrideWithValue(
            TranscriptRepository(db),
          ),
          videoPosterCaptureServiceProvider.overrideWith(
            (ref) => poster = _StubPosterCaptureService(ref),
          ),
        ],
      );

      final now = DateTime.now();
      for (final id in const ['media-a', 'media-b']) {
        final file = File(
          p.join(
            Directory.systemTemp.path,
            'enjoy_poster_${id}_${DateTime.now().microsecondsSinceEpoch}.mp4',
          ),
        );
        await file.writeAsBytes([1]);
        addTearDown(() async {
          if (await file.exists()) await file.delete();
        });
        await db.videoDao.insertRow(
          VideoRow(
            id: id,
            vid: 'vid-$id',
            provider: 'user',
            title: id,
            description: null,
            thumbnailUrl: null,
            durationSeconds: 600,
            language: 'en',
            source: null,
            localUri: Uri.file(file.path).toString(),
            size: 1,
            mediaUrl: null,
            syncStatus: null,
            serverUpdatedAt: null,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }
    });

    tearDown(() async {
      PathProviderPlatform.instance = originalPathProvider;
      await pumpEventQueue();
      container.dispose();
      await db.close();
      await fake.dispose();
    });

    test(
      'a capture landing after a newer open cannot stomp the new session',
      () async {
        final controller = container.read(playerControllerProvider.notifier);

        await runPlayerOpen(controller, 'media-a');
        expect(poster.requests.keys, ['media-a']);
        await runPlayerOpen(controller, 'media-b');
        expect(poster.requests.keys, unorderedEquals(['media-a', 'media-b']));

        poster.requests['media-a']!('/stale-a.jpg');
        final sessionAfterStale = controller.session;
        expect(sessionAfterStale, isNotNull);
        expect(sessionAfterStale!.mediaId, 'media-b');
        expect(
          sessionAfterStale.thumbnailUrl,
          isNull,
          reason: "media A's late capture must not stomp media B's session",
        );

        poster.requests['media-b']!('/fresh-b.jpg');
        final sessionAfterFresh = controller.session;
        expect(sessionAfterFresh, isNotNull);
        expect(sessionAfterFresh!.mediaId, 'media-b');
        expect(sessionAfterFresh.thumbnailUrl, '/fresh-b.jpg');
      },
    );
  });
}
