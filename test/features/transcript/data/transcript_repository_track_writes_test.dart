/// Read-your-writes tests for the transcript track write paths.
///
/// Every track write (subtitle import, ASR generation, auto-translate
/// skeleton, YouTube direct fetch, YouTube worker cache) goes through
/// `_upsertTranscriptTrack`. The decoded-timeline memo is keyed on the row's
/// `(updatedAt, jsonLength)` revision, so a write must never leave a reader
/// on the previous timeline — these tests pin that per write path.
library;

import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:drift/native.dart';
import 'package:enjoy_player/core/ids/enjoy_ids.dart';
import 'package:enjoy_player/data/api/services/ai/youtube_transcripts_api.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/transcript_row.dart';
import 'package:enjoy_player/data/subtitle/transcript_line.dart';
import 'package:enjoy_player/features/transcript/data/client_profile.dart';
import 'package:enjoy_player/features/transcript/data/transcript_repository.dart';
import 'package:enjoy_player/features/transcript/data/youtube_caption_fetcher.dart';
import 'package:enjoy_player/features/transcript/domain/auto_translate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

class _FakeTranscriptsApi implements YoutubeTranscriptsClient {
  _FakeTranscriptsApi(this.cached);

  final Map<String, Map<String, dynamic>> cached;

  @override
  Future<Map<String, dynamic>?> getCachedTranscript({
    required String videoId,
    required String language,
  }) async => cached['$videoId/$language'];

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

class _StubYoutubeCaptionFetcher extends YoutubeCaptionFetcher {
  _StubYoutubeCaptionFetcher(this._results)
    : super(httpClient: http.Client(), profiles: kBuiltInClientProfiles);

  final List<AllCaptionsResult> _results;
  int _index = 0;

  @override
  Future<AllCaptionsResult> fetchAllSubtitles({
    required String videoId,
    String preferredLang = 'en',
  }) async => _results[_index++];
}

VideoRow _video({required String id, String language = 'en-US'}) {
  final now = DateTime.utc(2026, 11, 17);
  return VideoRow(
    id: id,
    vid: 'tIgO_Sjh3tQ',
    provider: 'youtube',
    title: 't',
    description: null,
    thumbnailUrl: null,
    durationSeconds: 0,
    language: language,
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

AudioRow _audio({required String id}) {
  final now = DateTime.utc(2026, 11, 17);
  return AudioRow(
    id: id,
    aid: 'aid-$id',
    provider: 'user',
    title: 'Test Audio',
    description: null,
    thumbnailUrl: null,
    durationSeconds: 60,
    language: 'en',
    translationKey: null,
    sourceText: null,
    voice: null,
    source: null,
    localUri: 'file:///tmp/$id.mp3',
    md5: null,
    size: 100,
    mediaUrl: null,
    syncStatus: null,
    serverUpdatedAt: null,
    createdAt: now,
    updatedAt: now,
  );
}

CaptionFetchResult _track({required String language, required String text}) {
  return CaptionFetchResult(
    subtitles: [TranscriptLine(text: text, startMs: 0, durationMs: 1000)],
    source: 'official',
    language: language,
    fetchProfile: 'ios',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<String> readFirstLineText(
    TranscriptRepository repo,
    String transcriptId,
  ) async {
    final row = await db.transcriptDao.getById(transcriptId);
    expect(row, isNotNull);
    return repo.linesForRow(row!).first.text;
  }

  test('subtitle import read reflects the imported timeline', () async {
    final repo = TranscriptRepository(db);
    await db.audioDao.insertRow(_audio(id: 'sub-1'));
    final dir = Directory.systemTemp.createTempSync('enjoy_track_writes');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/sample.srt');

    file.writeAsStringSync('1\n00:00:00,000 --> 00:00:01,000\nfirst cue\n');
    await repo.importSubtitle(
      mediaId: 'sub-1',
      file: XFile(file.path, name: 'sample.srt'),
      language: 'en',
    );
    final id = enjoyTranscriptId(
      targetType: 'Audio',
      targetId: 'sub-1',
      language: 'en',
      source: 'user',
    );
    expect(await readFirstLineText(repo, id), 'first cue');

    file.writeAsStringSync('1\n00:00:00,000 --> 00:00:01,000\nother cue\n');
    await repo.importSubtitle(
      mediaId: 'sub-1',
      file: XFile(file.path, name: 'sample.srt'),
      language: 'en',
    );
    expect(await readFirstLineText(repo, id), 'other cue');
  });

  test('ASR-generated track read reflects the regenerated timeline', () async {
    final repo = TranscriptRepository(db);
    await db.audioDao.insertRow(_audio(id: 'asr-1'));

    final id = await repo.upsertAsrGeneratedTrack(
      mediaId: 'asr-1',
      language: 'en',
      lines: const [TranscriptLine(text: 'v1', startMs: 0, durationMs: 100)],
    );
    expect(await readFirstLineText(repo, id!), 'v1');

    await repo.upsertAsrGeneratedTrack(
      mediaId: 'asr-1',
      language: 'en',
      lines: const [TranscriptLine(text: 'v2', startMs: 0, durationMs: 200)],
    );
    expect(await readFirstLineText(repo, id), 'v2');
  });

  test('auto-translate skeleton read reflects the rebuilt skeleton', () async {
    final repo = TranscriptRepository(db);
    await db.audioDao.insertRow(_audio(id: 'auto-1'));
    final primaryId = 'primary-auto-1';
    await db.transcriptDao.upsert(
      buildTranscriptRow(
        id: primaryId,
        targetType: 'Audio',
        targetId: 'auto-1',
        language: 'en',
        source: 'official',
        timelineJson:
            '[{"text":"one","start":0,"duration":1000},'
            '{"text":"two","start":1000,"duration":1000}]',
        createdAt: DateTime.utc(2026, 11, 17),
      ),
    );

    final id = await repo.ensureAutoTranslateTrack(
      mediaId: 'auto-1',
      primaryTranscriptId: primaryId,
      targetLanguage: 'zh',
      primaryLines: const [
        TranscriptLine(text: 'one', startMs: 0, durationMs: 1000),
        TranscriptLine(text: 'two', startMs: 1000, durationMs: 1000),
      ],
    );
    expect(id, isNotNull);
    final rows = await db.transcriptDao.getById(id!);
    expect(repo.linesForRow(rows!).length, 2);

    await repo.ensureAutoTranslateTrack(
      mediaId: 'auto-1',
      primaryTranscriptId: primaryId,
      targetLanguage: 'zh',
      primaryLines: const [
        TranscriptLine(text: 'one', startMs: 0, durationMs: 1000),
      ],
    );
    final rebuilt = await db.transcriptDao.getById(id);
    expect(repo.linesForRow(rebuilt!).length, 1);
  });

  test('YouTube direct fetch read reflects the stored captions', () async {
    const mediaId = 'yt-fetch-1';
    await db.videoDao.insertRow(_video(id: mediaId));
    final fetcher = _StubYoutubeCaptionFetcher([
      AllCaptionsResult(
        results: [_track(language: 'en', text: 'alpha')],
      ),
      AllCaptionsResult(
        results: [_track(language: 'en', text: 'bravo')],
      ),
    ]);
    final repo = TranscriptRepository(
      db,
      youtubeTranscripts: _FakeTranscriptsApi({}),
      youtubeFetcher: fetcher,
    );

    await repo.fetchCloudTranscripts(mediaId, force: true);
    final id = enjoyTranscriptId(
      targetType: 'Video',
      targetId: mediaId,
      language: 'en',
      source: 'official',
    );
    expect(await readFirstLineText(repo, id), 'alpha');

    await repo.fetchCloudTranscripts(mediaId, force: true);
    expect(await readFirstLineText(repo, id), 'bravo');
  });

  test('YouTube worker cache read reflects the cached captions', () async {
    const mediaId = 'yt-cache-1';
    await db.videoDao.insertRow(_video(id: mediaId));
    final api = _FakeTranscriptsApi({
      'tIgO_Sjh3tQ/en': {
        'language': 'en',
        'source': 'official',
        'timeline': [
          {'text': 'cached one', 'start': 0, 'duration': 1000},
        ],
      },
    });
    final repo = TranscriptRepository(db, youtubeTranscripts: api);

    await repo.fetchCloudTranscripts(mediaId);
    final id = enjoyTranscriptId(
      targetType: 'Video',
      targetId: mediaId,
      language: 'en',
      source: 'official',
    );
    expect(await readFirstLineText(repo, id), 'cached one');

    api.cached['tIgO_Sjh3tQ/en'] = {
      'language': 'en',
      'source': 'official',
      'timeline': [
        {'text': 'cached b', 'start': 0, 'duration': 1000},
      ],
    };
    await repo.fetchCloudTranscripts(mediaId);
    expect(await readFirstLineText(repo, id), 'cached b');
  });

  test('auto-translate track id is derived from the primary pair', () async {
    expect(
      autoTranslateAiTrackId(
        targetType: 'Audio',
        mediaId: 'auto-1',
        targetLanguage: 'zh',
      ),
      enjoyTranscriptId(
        targetType: 'Audio',
        targetId: 'auto-1',
        language: 'zh',
        source: 'ai',
      ),
    );
  });
}
