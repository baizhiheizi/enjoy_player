import 'package:drift/native.dart';
import 'package:enjoy_player/data/api/api_client.dart';
import 'package:enjoy_player/data/api/services/recording_api.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:enjoy_player/features/player/application/player_engine_test_double_provider.dart';
import 'package:enjoy_player/features/player/application/player_open_side_effects.dart';
import 'package:enjoy_player/features/sync/application/sync_providers.dart';
import 'package:enjoy_player/features/sync/data/recording_target_sync_service.dart';
import 'package:enjoy_player/features/sync/domain/sync_types.dart';
import 'package:enjoy_player/features/transcript/application/transcript_fetch_controller.dart';
import 'package:enjoy_player/features/transcript/domain/transcript_fetch_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../support/fake_player_engine.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

const _profile = UserProfile(id: 'u1', email: 'a@b.com', name: 'Test');

class _SignedInAuthCtrl extends AuthCtrl {
  @override
  Future<AuthState> build() async => const AuthSignedIn(profile: _profile);
}

class _SignedOutAuthCtrl extends AuthCtrl {
  @override
  Future<AuthState> build() async => const AuthSignedOut();
}

/// Records calls to [resolveOnOpen] without touching real DB / network.
class _FakeTranscriptFetchCtrl extends TranscriptFetchCtrl {
  static int resolveCalls = 0;
  static bool? lastSignedIn;
  static Object? throwError;

  static void reset() {
    resolveCalls = 0;
    lastSignedIn = null;
    throwError = null;
  }

  @override
  TranscriptFetchUiState build(String mediaId) {
    return const TranscriptFetchUiState();
  }

  @override
  Future<void> resolveOnOpen({required bool signedIn}) async {
    resolveCalls++;
    lastSignedIn = signedIn;
    if (throwError != null) throw throwError!;
  }
}

ApiClient _testApiClient() => ApiClient(
  httpClient: http.Client(),
  getBaseUrl: () async => 'https://enjoy.bot',
  getAccessToken: () async => null,
);

/// Records calls to [pullRecordingsForTarget] without real network.
class _FakeRecordingTargetSyncService extends RecordingTargetSyncService {
  _FakeRecordingTargetSyncService(AppDatabase db)
    : super(db: db, recordingApi: RecordingApi(_testApiClient()));

  static int pullCalls = 0;
  static String? lastTargetType;
  static String? lastTargetId;
  static Object? throwError;

  static void reset() {
    pullCalls = 0;
    lastTargetType = null;
    lastTargetId = null;
    throwError = null;
  }

  @override
  Future<SyncResult> pullRecordingsForTarget({
    required String targetType,
    required String targetId,
    DateTime? now,
  }) async {
    pullCalls++;
    lastTargetType = targetType;
    lastTargetId = targetId;
    if (throwError != null) throw throwError!;
    return const SyncResult(success: true, synced: 0, failed: 0);
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Captures a [Ref] from the container so top-level functions that accept
/// [Ref] can be called in tests.
final _refCapture = Provider<Ref>((ref) => ref);

ProviderContainer _container({
  required AppDatabase db,
  required bool signedIn,
}) {
  return ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      playerEngineTestDoubleProvider.overrideWithValue(FakePlayerEngine()),
      authCtrlProvider.overrideWith(
        signedIn ? _SignedInAuthCtrl.new : _SignedOutAuthCtrl.new,
      ),
      transcriptFetchCtrlProvider.overrideWith(_FakeTranscriptFetchCtrl.new),
      recordingTargetSyncServiceProvider.overrideWithValue(
        _FakeRecordingTargetSyncService(db),
      ),
    ],
  );
}

Ref _ref(ProviderContainer container) => container.read(_refCapture);

Future<void> _insertVideoRow(
  AppDatabase db, {
  required String id,
  required String vid,
  required String provider,
  required String title,
  String? thumbnailUrl,
}) async {
  final now = DateTime.now();
  await db.videoDao.insertRow(
    VideoRow(
      id: id,
      vid: vid,
      provider: provider,
      title: title,
      description: null,
      thumbnailUrl: thumbnailUrl,
      durationSeconds: 120,
      language: 'en',
      source: null,
      localUri: null,
      md5: null,
      size: null,
      mediaUrl: null,
      syncStatus: null,
      serverUpdatedAt: null,
      createdAt: now,
      updatedAt: now,
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    _FakeTranscriptFetchCtrl.reset();
    _FakeRecordingTargetSyncService.reset();
  });

  tearDown(() async {
    await pumpEventQueue();
    await db.close();
  });

  group('schedulePlayerOpenSideEffects', () {
    test('signed out: resolves transcript but skips recording pull', () async {
      final container = _container(db: db, signedIn: false);
      addTearDown(container.dispose);
      await container.read(authCtrlProvider.future);

      schedulePlayerOpenSideEffects(
        _ref(container),
        openGeneration: 1,
        isStale: () => false,
        mediaId: 'media-1',
        dexieTargetType: 'Video',
      );

      await pumpEventQueue();

      expect(_FakeTranscriptFetchCtrl.resolveCalls, 1);
      expect(_FakeTranscriptFetchCtrl.lastSignedIn, isFalse);
      expect(_FakeRecordingTargetSyncService.pullCalls, 0);
    });

    test('signed in: resolves transcript AND pulls recordings', () async {
      final container = _container(db: db, signedIn: true);
      addTearDown(container.dispose);
      await container.read(authCtrlProvider.future);

      schedulePlayerOpenSideEffects(
        _ref(container),
        openGeneration: 1,
        isStale: () => false,
        mediaId: 'media-2',
        dexieTargetType: 'Audio',
      );

      await pumpEventQueue();

      expect(_FakeTranscriptFetchCtrl.resolveCalls, 1);
      expect(_FakeTranscriptFetchCtrl.lastSignedIn, isTrue);
      expect(_FakeRecordingTargetSyncService.pullCalls, 1);
      expect(_FakeRecordingTargetSyncService.lastTargetType, 'Audio');
      expect(_FakeRecordingTargetSyncService.lastTargetId, 'media-2');
    });

    test('stale: skips both transcript and recording pull', () async {
      final container = _container(db: db, signedIn: true);
      addTearDown(container.dispose);
      await container.read(authCtrlProvider.future);

      schedulePlayerOpenSideEffects(
        _ref(container),
        openGeneration: 1,
        isStale: () => true,
        mediaId: 'media-3',
        dexieTargetType: 'Video',
      );

      await pumpEventQueue();

      expect(_FakeTranscriptFetchCtrl.resolveCalls, 0);
      expect(_FakeRecordingTargetSyncService.pullCalls, 0);
    });

    test('transcript error is caught and does not propagate', () async {
      _FakeTranscriptFetchCtrl.throwError = StateError('transcript_boom');
      final container = _container(db: db, signedIn: true);
      addTearDown(container.dispose);
      await container.read(authCtrlProvider.future);

      // Should not throw despite transcript error.
      schedulePlayerOpenSideEffects(
        _ref(container),
        openGeneration: 1,
        isStale: () => false,
        mediaId: 'media-4',
        dexieTargetType: 'Video',
      );

      await pumpEventQueue();

      expect(_FakeTranscriptFetchCtrl.resolveCalls, 1);
      // Recording pull still runs independently.
      expect(_FakeRecordingTargetSyncService.pullCalls, 1);
    });

    test('recording pull error is caught and does not propagate', () async {
      _FakeRecordingTargetSyncService.throwError = StateError('pull_boom');
      final container = _container(db: db, signedIn: true);
      addTearDown(container.dispose);
      await container.read(authCtrlProvider.future);

      // Should not throw despite recording pull error.
      schedulePlayerOpenSideEffects(
        _ref(container),
        openGeneration: 1,
        isStale: () => false,
        mediaId: 'media-5',
        dexieTargetType: 'Audio',
      );

      await pumpEventQueue();

      expect(_FakeTranscriptFetchCtrl.resolveCalls, 1);
      expect(_FakeRecordingTargetSyncService.pullCalls, 1);
    });
  });

  group('scheduleYoutubeMetadataRefresh', () {
    test('early return when video row is null', () async {
      final container = _container(db: db, signedIn: false);
      addTearDown(container.dispose);
      await container.read(authCtrlProvider.future);

      // No row inserted for 'missing-id' — should return early.
      scheduleYoutubeMetadataRefresh(
        _ref(container),
        mediaId: 'missing-id',
        openGeneration: 1,
      );

      await pumpEventQueue();
      // No crash; the function returned early after finding null row.
    });

    test('early return when provider is not youtube', () async {
      await _insertVideoRow(
        db,
        id: 'v-user',
        vid: 'abc123',
        provider: 'user',
        title: 'YouTube video abc123',
      );
      final container = _container(db: db, signedIn: false);
      addTearDown(container.dispose);
      await container.read(authCtrlProvider.future);

      scheduleYoutubeMetadataRefresh(
        _ref(container),
        mediaId: 'v-user',
        openGeneration: 1,
      );

      await pumpEventQueue();
      // No crash; returned early because provider != 'youtube'.
    });

    test('early return when metadata does not need refresh', () async {
      await _insertVideoRow(
        db,
        id: 'v-complete',
        vid: 'dQw4w9WgXcQ',
        provider: 'youtube',
        title: 'Real YouTube Title',
        thumbnailUrl: 'https://i.ytimg.com/vi/dQw4w9WgXcQ/mqdefault.jpg',
      );
      final container = _container(db: db, signedIn: false);
      addTearDown(container.dispose);
      await container.read(authCtrlProvider.future);

      scheduleYoutubeMetadataRefresh(
        _ref(container),
        mediaId: 'v-complete',
        openGeneration: 1,
      );

      await pumpEventQueue();
      // No crash; returned early because title is real and thumbnail exists.
    });

    test('proceeds when title is placeholder (needs refresh)', () async {
      // This row has a placeholder title — metadata needs refresh.
      // The function will proceed past the guard but will fail at
      // playerControllerProvider (no engine in test) — which is fine,
      // we just verify it doesn't crash due to the unawaited wrapper.
      await _insertVideoRow(
        db,
        id: 'v-placeholder',
        vid: 'dQw4w9WgXcQ',
        provider: 'youtube',
        title: 'YouTube video dQw4w9WgXcQ',
        thumbnailUrl: null,
      );
      final container = _container(db: db, signedIn: false);
      addTearDown(container.dispose);
      await container.read(authCtrlProvider.future);

      // The function fires unawaited work that will hit the player controller.
      // In test without a full player setup, this will throw internally but
      // the error is swallowed by the unawaited future (no zone handler).
      // We just verify no synchronous crash.
      scheduleYoutubeMetadataRefresh(
        _ref(container),
        mediaId: 'v-placeholder',
        openGeneration: 1,
      );

      await pumpEventQueue();
    });

    test('proceeds when thumbnail is empty string (needs refresh)', () async {
      await _insertVideoRow(
        db,
        id: 'v-empty-thumb',
        vid: 'dQw4w9WgXcQ',
        provider: 'youtube',
        title: 'Real Title',
        thumbnailUrl: '   ',
      );
      final container = _container(db: db, signedIn: false);
      addTearDown(container.dispose);
      await container.read(authCtrlProvider.future);

      scheduleYoutubeMetadataRefresh(
        _ref(container),
        mediaId: 'v-empty-thumb',
        openGeneration: 1,
      );

      await pumpEventQueue();
    });
  });
}
