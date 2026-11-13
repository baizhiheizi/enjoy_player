import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:enjoy_player/core/theme/app_theme.dart';
import 'package:enjoy_player/data/api/api_client.dart';
import 'package:enjoy_player/data/api/services/ai/youtube_transcripts_api.dart';
import 'package:enjoy_player/data/api/services/audio_api.dart';
import 'package:enjoy_player/data/api/services/recording_api.dart';
import 'package:enjoy_player/data/api/services/video_api.dart';
import 'package:enjoy_player/data/api/services/vocabulary_api.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:enjoy_player/features/sync/application/sync_engine.dart';
import 'package:enjoy_player/features/sync/application/sync_providers.dart';
import 'package:enjoy_player/features/sync/data/sync_download_service.dart';
import 'package:enjoy_player/features/sync/data/sync_queue_repository.dart';
import 'package:enjoy_player/features/sync/data/sync_upload_service.dart';
import 'package:enjoy_player/features/sync/domain/sync_types.dart';
import 'package:enjoy_player/features/vocabulary/data/vocabulary_repository.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_models.dart';
import 'package:enjoy_player/features/vocabulary/presentation/vocabulary_screen.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

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

class _FakeSyncEngine extends SyncEngine {
  _FakeSyncEngine(AppDatabase db)
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

  int pullCalls = 0;
  SyncResult pullResult = const SyncResult(success: true, synced: 0, failed: 0);

  @override
  Future<SyncResult> pullVocabulary() async {
    pullCalls++;
    return pullResult;
  }

  @override
  Future<SyncResult> fullSync(SyncOptions options) async =>
      const SyncResult(success: true, synced: 0, failed: 0);
}

void main() {
  late AppDatabase db;
  late _FakeSyncEngine engine;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    engine = _FakeSyncEngine(db);
  });

  tearDown(() async {
    await db.close();
  });

  Widget harness({required bool signedIn}) {
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        authCtrlProvider.overrideWith(
          signedIn ? _SignedInAuthCtrl.new : _SignedOutAuthCtrl.new,
        ),
        syncEngineProvider.overrideWith((ref) => engine),
      ],
      child: MaterialApp(
        theme: buildAppTheme(Brightness.light),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Consumer(
          builder: (context, ref, _) {
            ref.watch(authCtrlProvider);
            return const VocabularyScreen();
          },
        ),
      ),
    );
  }

  Future<void> pumpScreen(WidgetTester tester, {bool signedIn = false}) async {
    await tester.pumpWidget(harness(signedIn: signedIn));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  Future<void> disposeHarness(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 50));
  }

  Future<void> pullToRefresh(WidgetTester tester) async {
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(CustomScrollView)),
    );
    await gesture.moveBy(const Offset(0, 300));
    await gesture.moveBy(const Offset(0, 150));
    await tester.pump();
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> addHello(DateTime nextReviewAt) async {
    final repo = VocabularyRepository(db);
    final created = await repo.addWithContext(
      word: 'hello',
      language: 'en',
      targetLanguage: 'zh',
      text: 'Hello world',
      sourceType: VocabularySourceType.video,
      sourceId: 'v1',
      mediaLocator: const MediaLocator(start: 0, duration: 1000),
    );
    await (db.update(db.vocabularyItems)
          ..where((t) => t.id.equals(created.item.id)))
        .write(VocabularyItemsCompanion(nextReviewAt: Value(nextReviewAt)));
  }

  testWidgets('empty book shows the no-words state under the header', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpScreen(tester);

    expect(find.text('YOUR WORD BOOK'), findsOneWidget);
    expect(find.text('Vocabulary'), findsOneWidget);
    expect(find.text('No words yet'), findsOneWidget);
    expect(find.text('All Words'), findsNothing);

    await disposeHarness(tester);
  });

  testWidgets('a due word shows the due card, status card and Review action', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await addHello(DateTime.utc(2000));
    await pumpScreen(tester);

    expect(
      find.textContaining('due today', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('Review 1 due'), findsOneWidget);
    expect(find.text('by status'), findsOneWidget);
    expect(find.text('hello'), findsOneWidget);
    expect(find.text('Hello world'), findsOneWidget);

    await tester.tap(find.text('Review'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('1 word is waiting'), findsOneWidget);
    expect(find.text('Custom review'), findsOneWidget);

    await disposeHarness(tester);
  });

  testWidgets('nothing due drops the Review action and says so', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await addHello(DateTime.utc(2099));
    await pumpScreen(tester);

    expect(find.textContaining('Review 0'), findsNothing);

    await tester.tap(find.text('Review'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Nothing due right now'), findsOneWidget);
    expect(find.text('Custom review'), findsOneWidget);

    await disposeHarness(tester);
  });

  testWidgets('pull to refresh triggers a vocabulary pull when signed in', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpScreen(tester, signedIn: true);

    expect(find.byTooltip('Refresh'), findsNothing);

    await pullToRefresh(tester);
    expect(engine.pullCalls, 1);

    await disposeHarness(tester);
  });

  testWidgets('pull to refresh is a silent no-op when signed out', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpScreen(tester, signedIn: false);

    await pullToRefresh(tester);
    expect(engine.pullCalls, 0);

    await disposeHarness(tester);
  });

  testWidgets('failed pull surfaces the sync issues notice', (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    engine.pullResult = const SyncResult(success: false, synced: 0, failed: 2);
    await pumpScreen(tester, signedIn: true);

    await pullToRefresh(tester);
    expect(engine.pullCalls, 1);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('2 failed'), findsOneWidget);

    await disposeHarness(tester);
  });

  testWidgets('desktop header refresh button triggers the vocabulary pull', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpScreen(tester, signedIn: true);

    final refreshButton = find.byTooltip('Refresh');
    expect(refreshButton, findsOneWidget);
    await tester.tap(refreshButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(seconds: 1));
    expect(engine.pullCalls, 1);

    debugDefaultTargetPlatformOverride = null;
    await disposeHarness(tester);
  });
}
