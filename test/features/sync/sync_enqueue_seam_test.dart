/// Issue #749: when signed in, a failed YouTube worker upload schedules a
/// queue drain without waiting for `SyncCtrl`'s 5-minute timer.
///
/// Mirrors how `queue_for_sync.dart`'s kick is tested
/// (`sync_queue_drain_test.dart`): the drain is observed through real
/// `SyncEngine.processQueue` activity that happens on its own after the
/// enqueue. This test never calls `processQueue`,
/// `scheduleSyncQueueDrain`, or `SyncCtrl` — if the seam's signed-in tail
/// is missing, the loop below times out and the row sits forever (the
/// pre-fix behavior: waiting for the periodic timer).
library;

import 'package:drift/native.dart';
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
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:enjoy_player/features/sync/application/sync_engine.dart';
import 'package:enjoy_player/features/sync/application/sync_providers.dart';
import 'package:enjoy_player/features/sync/data/sync_download_service.dart';
import 'package:enjoy_player/features/sync/data/sync_queue_repository.dart';
import 'package:enjoy_player/features/sync/data/sync_upload_service.dart';
import 'package:enjoy_player/features/transcript/data/client_profile.dart';
import 'package:enjoy_player/features/transcript/data/transcript_repository.dart';
import 'package:enjoy_player/features/transcript/data/youtube_caption_fetcher.dart';

class _FakeTranscriptsApi implements YoutubeTranscriptsClient {
  _FakeTranscriptsApi({this.uploadShouldFail = false});

  bool uploadShouldFail;

  final List<({String videoId, String language, String source, int lineCount})>
  uploads = [];

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
  }) async {
    uploads.add((
      videoId: videoId,
      language: language,
      source: source,
      lineCount: timeline.length,
    ));
    return !uploadShouldFail;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchClientProfiles() async =>
      <Map<String, dynamic>>[];
}

class _StubYoutubeCaptionFetcher extends YoutubeCaptionFetcher {
  _StubYoutubeCaptionFetcher({required AllCaptionsResult result})
    : _nextResult = result,
      super(httpClient: http.Client(), profiles: kBuiltInClientProfiles);

  final AllCaptionsResult _nextResult;

  @override
  Future<AllCaptionsResult> fetchAllSubtitles({
    required String videoId,
    String preferredLang = 'en',
  }) async => _nextResult;
}

class _SignedInAuthCtrl extends AuthCtrl {
  @override
  Future<AuthState> build() async => const AuthSignedIn(
    profile: UserProfile(id: 'user-42', email: 'u@test.com', name: 'Test'),
  );
}

VideoRow _video({required String id}) {
  final now = DateTime.utc(2026, 9, 24);
  return VideoRow(
    id: id,
    vid: 'tIgO_Sjh3tQ',
    provider: 'youtube',
    title: 't',
    description: null,
    thumbnailUrl: null,
    durationSeconds: 0,
    language: 'en-US',
    source: 'youtube',
    localUri: null,
    md5: null,
    size: 0,
    mediaUrl: 'https://www.youtube.com/watch?v=tIgO_Sjh3tQ',
    syncStatus: null,
    serverUpdatedAt: null,
    createdAt: now,
    updatedAt: now,
  );
}

CaptionFetchResult _track({required String language}) {
  return CaptionFetchResult(
    subtitles: const [
      TranscriptLine(text: 'hello', startMs: 0, durationMs: 1000),
    ],
    source: 'official',
    language: language,
    fetchProfile: 'ios',
  );
}

SyncEngine _buildEngine(
  AppDatabase db,
  SyncQueueRepository queue,
  YoutubeTranscriptsClient youtubeTranscripts,
) {
  final client = ApiClient(
    httpClient: MockClient((request) async {
      // Never exercised: the queue only holds the youtube_upload retry row,
      // which the engine dispatches to [youtubeTranscripts], not the
      // /api/v1/mine upload services.
      return http.Response('unexpected ${request.method}', 500);
    }),
    getBaseUrl: () async => 'https://enjoy.example.com',
    getAccessToken: () async => 'tok',
  );
  return SyncEngine(
    db: db,
    queue: queue,
    upload: SyncUploadService(
      db: db,
      audioApi: AudioApi(client),
      videoApi: VideoApi(client),
      recordingApi: RecordingApi(client),
      vocabularyApi: VocabularyApi(client),
    ),
    download: SyncDownloadService(
      db: db,
      audioApi: AudioApi(client),
      videoApi: VideoApi(client),
      recordingApi: RecordingApi(client),
      vocabularyApi: VocabularyApi(client),
    ),
    youtubeTranscripts: youtubeTranscripts,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('signed-in failed worker upload schedules a drain without the '
      '5-minute timer', () async {
    const mediaId = 'v-seam-kick';
    const videoId = 'tIgO_Sjh3tQ';

    final db = AppDatabase(executor: NativeDatabase.memory());
    addTearDown(db.close);
    final queue = SyncQueueRepository(db);

    // Producer-side client: the direct fire-and-forget upload fails, so
    // the repository enqueues the durable SyncYoutubeUploadRetry.
    final producerApi = _FakeTranscriptsApi(uploadShouldFail: true);
    // Drain-side client (SyncEngine's): the scheduled drain re-uploads
    // the retry row successfully. A separate instance makes "the drain
    // ran" observable independent of the producer's failure — the retry
    // only reaches [drainApi] if processQueue decoded the wire row.
    final drainApi = _FakeTranscriptsApi();
    final engine = _buildEngine(db, queue, drainApi);

    final container = ProviderContainer(
      overrides: [
        authCtrlProvider.overrideWith(_SignedInAuthCtrl.new),
        syncQueueRepositoryProvider.overrideWithValue(queue),
        syncEngineProvider.overrideWithValue(engine),
      ],
    );
    addTearDown(container.dispose);
    await container.read(authCtrlProvider.future);

    await db.videoDao.insertRow(_video(id: mediaId));
    final fetcher = _StubYoutubeCaptionFetcher(
      result: AllCaptionsResult(results: [_track(language: 'en')]),
    );
    // Production wiring: the repository holds the REAL job-shaped seam
    // entry (syncEnqueueJobProvider), never a hand-built repository.
    final repo = TranscriptRepository(
      db,
      null,
      producerApi,
      fetcher,
      container.read(syncEnqueueJobProvider),
    );

    await repo.fetchCloudTranscripts(mediaId, force: true);

    // No explicit drain call below — the enqueue's signed-in tail must
    // schedule processQueue itself.
    final deadline = DateTime.now().add(const Duration(seconds: 3));
    while (DateTime.now().isBefore(deadline)) {
      final pending = await queue.pendingItems();
      if (drainApi.uploads.isNotEmpty && pending.isEmpty) break;
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }

    expect(producerApi.uploads, hasLength(1));
    expect(
      drainApi.uploads,
      hasLength(1),
      reason:
          'the scheduled drain re-uploaded the retry row without an '
          'explicit processQueue/scheduleSyncQueueDrain call',
    );
    expect(drainApi.uploads.single.videoId, videoId);
    expect(drainApi.uploads.single.language, 'en');
    expect(drainApi.uploads.single.lineCount, 1);
    expect(
      await queue.pendingItems(),
      isEmpty,
      reason: 'the scheduled drain cleared the retry row',
    );
  });
}
