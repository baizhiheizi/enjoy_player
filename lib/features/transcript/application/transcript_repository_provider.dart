library;

import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/api/services/ai/ai_api_providers.dart';
import '../../../data/api/services/api_providers.dart';
import '../../../data/db/app_database_provider.dart';
import '../../sync/application/sync_providers.dart';
import '../data/youtube_caption_fetcher.dart';
import '../data/client_profile.dart';
import '../data/transcript_repository.dart';
import '../data/youtube_profiles_provider.dart';

export '../data/transcript_repository.dart';

part 'transcript_repository_provider.g.dart';

@Riverpod(keepAlive: true)
TranscriptRepository transcriptRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  final api = ref.watch(transcriptApiProvider);
  final yt = ref.watch(youtubeTranscriptsClientProvider);
  final profilesAsync = ref.watch(youtubeProfilesProvider);
  final profiles = profilesAsync.maybeWhen(
    data: (p) => p,
    orElse: () => resolveCaptionClientProfiles(const []),
  );
  final httpClient = http.Client();
  ref.onDispose(httpClient.close);
  final fetcher = YoutubeCaptionFetcher(
    httpClient: httpClient,
    profiles: profiles,
  );
  return TranscriptRepository(
    db,
    transcriptApi: api,
    youtubeTranscripts: yt,
    youtubeFetcher: fetcher,
    // Job-shaped sync enqueue seam (issue #749): durable YouTube upload
    // retries go through the shared provider path (dedup + signed-in
    // drain kick) instead of a hand-built SyncQueueRepository.
    enqueueJob: ref.watch(syncEnqueueJobProvider),
  );
}
