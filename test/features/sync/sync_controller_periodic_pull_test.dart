import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:enjoy_player/data/api/api_client.dart';
import 'package:enjoy_player/data/api/services/ai/youtube_transcripts_api.dart';
import 'package:enjoy_player/data/api/services/audio_api.dart';
import 'package:enjoy_player/data/api/services/recording_api.dart';
import 'package:enjoy_player/data/api/services/video_api.dart';
import 'package:enjoy_player/data/api/services/vocabulary_api.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/data/db/settings_keys.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:enjoy_player/features/sync/application/sync_controller.dart';
import 'package:enjoy_player/features/sync/application/sync_engine.dart';
import 'package:enjoy_player/features/sync/application/sync_providers.dart';
import 'package:enjoy_player/features/sync/data/sync_download_service.dart';
import 'package:enjoy_player/features/sync/data/sync_queue_repository.dart';
import 'package:enjoy_player/features/sync/data/sync_upload_service.dart';
import 'package:enjoy_player/features/sync/domain/sync_types.dart';

const _profile = UserProfile(id: 'u1', email: 'a@b.com', name: 'Test');

class _SignedInAuthCtrl extends AuthCtrl {
  @override
  Future<AuthState> build() async => const AuthSignedIn(profile: _profile);
}

class _SignedOutAuthCtrl extends AuthCtrl {
  @override
  Future<AuthState> build() async => const AuthSignedOut();
}

class _FakeTranscriptsApi implements YoutubeTranscriptsClient {
  @override
  Future<Map<String, dynamic>?> getCachedTranscript({
    required String videoId,
    required String language,
  }) async => null;

  @override
  Future<bool> uploadTranscript({
    required String videoId,
    required String language,
    required String source,
    required List<Map<String, dynamic>> timeline,
    Map<String, dynamic>? metadata,
  }) async => true;

  @override
  Future<List<Map<String, dynamic>>> fetchClientProfiles() async =>
      <Map<String, dynamic>>[];
}

class _CountingEngine extends SyncEngine {
  _CountingEngine(AppDatabase db)
    : super(
        db: db,
        queue: SyncQueueRepository(db),
        upload: SyncUploadService(
          db: db,
          audioApi: AudioApi(_idleClient()),
          videoApi: VideoApi(_idleClient()),
          recordingApi: RecordingApi(_idleClient()),
          vocabularyApi: VocabularyApi(_idleClient()),
        ),
        download: SyncDownloadService(
          db: db,
          audioApi: AudioApi(_idleClient()),
          videoApi: VideoApi(_idleClient()),
          recordingApi: RecordingApi(_idleClient()),
          vocabularyApi: VocabularyApi(_idleClient()),
        ),
        youtubeTranscripts: _FakeTranscriptsApi(),
      );

  static ApiClient _idleClient() => ApiClient(
    httpClient: MockClient((request) async => http.Response('[]', 200)),
    getBaseUrl: () async => 'https://enjoy.example.com',
    getAccessToken: () async => 'tok',
  );

  int fullSyncCalls = 0;
  int pullCalls = 0;
  int pullFreshCalls = 0;
  int processQueueCalls = 0;
  bool throwOnPull = false;

  @override
  Future<SyncResult> fullSync(SyncOptions options) async {
    fullSyncCalls++;
    return const SyncResult(success: true, synced: 0, failed: 0);
  }

  @override
  Future<SyncResult> pullVocabulary() async {
    pullCalls++;
    if (throwOnPull) {
      throw StateError('pull failed');
    }
    return const SyncResult(success: true, synced: 0, failed: 0);
  }

  @override
  Future<SyncResult> pullVocabularyFresh() async {
    pullFreshCalls++;
    if (throwOnPull) {
      throw StateError('pull failed');
    }
    return const SyncResult(success: true, synced: 0, failed: 0);
  }

  @override
  Future<SyncResult> processQueue(SyncOptions options) async {
    processQueueCalls++;
    return const SyncResult(success: true, synced: 0, failed: 0);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late _CountingEngine engine;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    engine = _CountingEngine(db);
  });

  tearDown(() async {
    await db.close();
  });

  ProviderContainer container({required bool signedIn}) {
    return ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        authCtrlProvider.overrideWith(
          signedIn ? _SignedInAuthCtrl.new : _SignedOutAuthCtrl.new,
        ),
        syncEngineProvider.overrideWith((ref) => engine),
      ],
    );
  }

  Future<void> mountSyncWatcher(
    WidgetTester tester,
    ProviderContainer c,
  ) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: Consumer(
          builder: (context, ref, _) {
            ref.watch(syncCtrlProvider);
            return const SizedBox();
          },
        ),
      ),
    );
  }

  Future<void> mountAuthWatcher(
    WidgetTester tester,
    ProviderContainer c,
  ) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: Consumer(
          builder: (context, ref, _) {
            ref.watch(authCtrlProvider);
            return const SizedBox();
          },
        ),
      ),
    );
  }

  testWidgets('periodic tick performs a full sync, not upload-only', (
    tester,
  ) async {
    final c = container(signedIn: true);

    await mountSyncWatcher(tester, c);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
    expect(engine.fullSyncCalls, 1);

    await tester.pump(const Duration(minutes: 5));
    await tester.pump(const Duration(milliseconds: 1));
    expect(engine.fullSyncCalls, 2);

    await tester.pump(const Duration(minutes: 5));
    await tester.pump(const Duration(milliseconds: 1));
    expect(engine.fullSyncCalls, 3);

    expect(
      await db.settingsDao.readSetting(SettingsKeys.syncLastFullSyncAt),
      isNotNull,
    );

    c.dispose();
  });

  testWidgets('controller instantiated after auth settled still syncs once', (
    tester,
  ) async {
    final c = container(signedIn: true);

    await mountAuthWatcher(tester, c);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));

    c.read(syncCtrlProvider);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
    expect(engine.fullSyncCalls, 1);

    c.dispose();
  });

  testWidgets('signed-out controller neither syncs nor schedules', (
    tester,
  ) async {
    final c = container(signedIn: false);

    await mountSyncWatcher(tester, c);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(minutes: 10));
    await tester.pump(const Duration(milliseconds: 1));

    expect(engine.fullSyncCalls, 0);
    expect(engine.processQueueCalls, 0);
    expect(engine.pullCalls, 0);

    c.dispose();
  });

  test('pullVocabulary delegates to the engine when signed in', () async {
    final c = container(signedIn: true);
    addTearDown(c.dispose);
    await c.read(authCtrlProvider.future);

    final result = await c.read(syncCtrlProvider.notifier).pullVocabulary();
    expect(result.success, isTrue);
    expect(engine.pullCalls, 1);
    expect(engine.processQueueCalls, 0);
  });

  test('pullVocabulary returns failed result when signed out', () async {
    final c = container(signedIn: false);
    addTearDown(c.dispose);
    await c.read(authCtrlProvider.future);

    final result = await c.read(syncCtrlProvider.notifier).pullVocabulary();
    expect(result.success, isFalse);
    expect(result.errors, contains('Signed out'));
    expect(engine.pullCalls, 0);
  });

  test('pullVocabulary reports one failed unit when the pull throws', () async {
    final c = container(signedIn: true);
    addTearDown(c.dispose);
    await c.read(authCtrlProvider.future);

    engine.throwOnPull = true;
    final result = await c.read(syncCtrlProvider.notifier).pullVocabulary();
    expect(result.success, isFalse);
    expect(result.failed, 1);
    expect(result.synced, 0);
    expect(engine.pullCalls, 1);
  });

  test('pullVocabularyFresh delegates to the engine when signed in', () async {
    final c = container(signedIn: true);
    addTearDown(c.dispose);
    await c.read(authCtrlProvider.future);

    final result = await c
        .read(syncCtrlProvider.notifier)
        .pullVocabularyFresh();
    expect(result.success, isTrue);
    expect(engine.pullFreshCalls, 1);
    expect(engine.processQueueCalls, 0);
  });

  test('pullVocabularyFresh returns failed result when signed out', () async {
    final c = container(signedIn: false);
    addTearDown(c.dispose);
    await c.read(authCtrlProvider.future);

    final result = await c
        .read(syncCtrlProvider.notifier)
        .pullVocabularyFresh();
    expect(result.success, isFalse);
    expect(result.errors, contains('Signed out'));
    expect(engine.pullFreshCalls, 0);
  });
}
