import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/media_registry.dart';
import 'package:enjoy_player/features/player/application/media_analysis_input_provider.dart';
import 'package:enjoy_player/features/shadow_reading/data/echo_segment_pcm_extractor.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 10, 1);

AudioRow _audio({String? localUri, String? mediaUrl}) => AudioRow(
  id: 'a-1',
  aid: 'aid-1',
  provider: 'user',
  title: 'Audio',
  durationSeconds: 30,
  language: 'en',
  localUri: localUri,
  mediaUrl: mediaUrl,
  createdAt: _now,
  updatedAt: _now,
);

VideoRow _video({
  String provider = 'user',
  String vid = 'vid-1',
  String? localUri,
  String? mediaUrl,
}) => VideoRow(
  id: 'v-1',
  vid: vid,
  provider: provider,
  title: 'Video',
  durationSeconds: 60,
  language: 'en',
  localUri: localUri,
  mediaUrl: mediaUrl,
  createdAt: _now,
  updatedAt: _now,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late MediaRegistry registry;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    registry = MediaRegistry(db);
  });

  tearDown(() => db.close());

  test('prefers the local file path', () async {
    await db.audioDao.insertRow(
      _audio(
        localUri: Uri.file('/tmp/take.mp3').toString(),
        mediaUrl: 'https://assets.example/take',
      ),
    );
    expect(await resolveMediaAnalysisInput(registry, 'a-1'), '/tmp/take.mp3');
  });

  test('falls back to the https media url for cloud-only rows', () async {
    await db.audioDao.insertRow(
      _audio(mediaUrl: 'https://assets.example/gvjq'),
    );
    expect(
      await resolveMediaAnalysisInput(registry, 'a-1'),
      'https://assets.example/gvjq',
    );
  });

  test('ignores non-http media urls', () async {
    await db.audioDao.insertRow(_audio(mediaUrl: 'enjoy://asset/1'));
    expect(await resolveMediaAnalysisInput(registry, 'a-1'), isNull);
  });

  test('YouTube rows have no analysis input', () async {
    await db.videoDao.insertRow(
      _video(
        provider: 'youtube',
        vid: 'dQw4w9WgXcQ',
        mediaUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      ),
    );
    expect(await resolveMediaAnalysisInput(registry, 'v-1'), isNull);
  });

  test('unknown ids resolve to null', () async {
    expect(await resolveMediaAnalysisInput(registry, 'missing'), isNull);
  });

  test('isNetworkMediaInput recognises http(s) URLs only', () {
    expect(isNetworkMediaInput('https://assets.example/a'), isTrue);
    expect(isNetworkMediaInput('HTTP://assets.example/a'), isTrue);
    expect(isNetworkMediaInput('/home/user/a.mp3'), isFalse);
  });
}
