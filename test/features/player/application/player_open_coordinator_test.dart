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

// These tests drive [runPlayerOpen] against the REAL `PlayerController` as
// the [PlayerOpenScope] — production wiring (deps channel, engine-swap
// delegation, scheduler closures) with nothing hand-built or re-wired here
// (issue #750). End-to-end coverage of the [PlayerController.openMedia]
// entry (generation bump, open-in-flight latch, completion-loop arming)
// lives in `test/features/player/player_controller_test.dart`.

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
      // The zombie open's continuation must be stale at its next check.
      expect(controller.openGeneration, greaterThan(genBefore));

      // Releasing the wedged open later must not publish a session.
      hang.complete();
      await pumpEventQueue();
      expect(controller.session, isNull);
    });

    test(
      'a wedged first engine.open retries and still publishes the session',
      () async {
        // Field report 2026-08-30: the hang is engine.open after a YouTube
        // session (WebView teardown racing mk.Player), not post-open
        // commands. Back + reopen recovered because the second open ran
        // after the native side settled. Retry that automatically.
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
        // Field report 2026-08-30: local audio opened right after a YouTube
        // session stuck on the loading skeleton (back + reopen recovered).
        // engine.open is bounded, but the mpv-command steps after it were
        // not — a wedged event pump held the open forever because the
        // session (which dismisses the skeleton) publishes only after them.
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

      // Unplayable row: the local file is gone, there is no remote fallback,
      // and no md5 fingerprint — so the resolver returns null (no relocate).
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
        // Falsifiability: a silent success would leave ExpandedPlayerScreen on
        // the loading skeleton forever — open completes, session never
        // publishes (the exact bug the StateError contract exists for).
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

      // Media B has a persisted echo window different from A's live one.
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

        // Media A is playing with an active echo window + transcript blur.
        container
            .read(echoModeProvider.notifier)
            .activate(
              startLineIndex: 2,
              endLineIndex: 4,
              startTimeSeconds: 10,
              endTimeSeconds: 20,
            );
        container.read(transcriptBlurModeProvider.notifier).activate();

        // Position-tracker cadence: one debounced write pending for media A.
        persister.schedule(
          mediaId: 'media-a',
          dexieTargetType: 'Audio',
          session: sessionA(),
        );

        controller.publishSession(sessionA());

        // Opening B restores B's echo/blur into the live providers.
        await runPlayerOpen(controller, 'media-b');
        final echo = container.read(echoModeProvider);
        expect(echo.active, isTrue);
        expect(
          echo.startTimeSeconds,
          30,
          reason: 'B restored echo must own the providers now',
        );
        expect(container.read(transcriptBlurModeProvider), isFalse);

        // Advance past the debounce. Falsifiability (docs/perf-measurement.md
        // Pattern 3): reverting the flush at the head of the open
        // (lib/features/player/application/player_open_coordinator.dart)
        // turns this test red — B's restored providers then write line `7`
        // (echoStartMs 30_000 + blurActive=false) into media-a's row instead
        // of lines 2–4 above. Verified against pre-fix code.
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
      // The open also schedules a fire-and-forget transcript resolve that
      // reads the echo session through the same DAO. Point it at its own DB
      // so the counter below can only ever be the coordinator's read.
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
        // Holding engine.open means the only way the read can already be
        // pending is if the coordinator issued it first — the structural
        // proxy for "the DB read no longer sits on the open's critical path"
        // (docs/perf-measurement.md Pattern 3).
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

        // Wait on an explicit entry signal instead of polling: the resolve
        // path performs real file IO (`localUriTrusted`), so a bounded
        // zero-duration-timer poll can starve before `engine.open` is
        // entered on a loaded runner.
        await fake.openEntered.future.timeout(const Duration(seconds: 10));
        expect(fake.openUris, isNotEmpty, reason: 'engine.open was entered');
        expect(
          db.countingDao.getLatestCalls,
          1,
          reason:
              'the echo-session read must start before engine.open resolves',
        );

        // Releasing both proves the open still consumes the overlapped read
        // instead of dropping it.
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
    late PathProviderPlatform originalPathProvider;

    setUp(() {
      originalPathProvider = PathProviderPlatform.instance;
      PathProviderPlatform.instance = TestPathProvider(
        Directory.systemTemp.createTempSync('enjoy_player_open_db_switch').path,
      );
    });

    tearDown(() {
      PathProviderPlatform.instance = originalPathProvider;
    });

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

        // The first open binds `deps` — and, before the fix, the database
        // instance with it.
        final controller = container.read(playerControllerProvider.notifier);
        await runPlayerOpen(controller, 'hang-1');
        expect(db1.countingDao.getLatestCalls, 1);

        // Session switch: `appDatabaseProvider`'s onDispose closes the old
        // per-user database on sign-out / sign-in as another user, while the
        // keepAlive PlayerController survives.
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

        // Media A's poster capture resolves while media B's session is live.
        // Falsifiability: dropping the `live.mediaId != mediaId` gate in
        // `runPlayerOpen`'s `onSessionThumbnail` turns this red — A's path
        // lands on B's live session.
        poster.requests['media-a']!('/stale-a.jpg');
        final sessionAfterStale = controller.session;
        expect(sessionAfterStale, isNotNull);
        expect(sessionAfterStale!.mediaId, 'media-b');
        expect(
          sessionAfterStale.thumbnailUrl,
          isNull,
          reason: "media A's late capture must not stomp media B's session",
        );

        // The live media's own capture still applies.
        poster.requests['media-b']!('/fresh-b.jpg');
        final sessionAfterFresh = controller.session;
        expect(sessionAfterFresh, isNotNull);
        expect(sessionAfterFresh!.mediaId, 'media-b');
        expect(sessionAfterFresh.thumbnailUrl, '/fresh-b.jpg');
      },
    );
  });
}
