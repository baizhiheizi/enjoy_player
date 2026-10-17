import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/media_registry.dart';
import 'package:enjoy_player/features/library/domain/media.dart';
import 'package:flutter_test/flutter_test.dart';

VideoRow _video({
  required String id,
  String provider = 'user',
  String? vid,
  required DateTime updatedAt,
}) {
  return VideoRow(
    id: id,
    vid: vid ?? 'vid-$id',
    provider: provider,
    title: 'Video $id',
    durationSeconds: 0,
    language: 'und',
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: updatedAt,
  );
}

AudioRow _audio({
  required String id,
  String provider = 'user',
  required DateTime updatedAt,
}) {
  return AudioRow(
    id: id,
    aid: 'aid-$id',
    provider: provider,
    title: 'Audio $id',
    durationSeconds: 0,
    language: 'und',
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: updatedAt,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late MediaRegistry registry;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    registry = MediaRegistry(db);
  });

  tearDown(() => db.close());

  test('watchByKind returns one table in updatedAt order', () async {
    await db.videoDao.insertRow(
      _video(id: 'v-old', updatedAt: DateTime.utc(2026, 1, 1)),
    );
    await db.videoDao.insertRow(
      _video(id: 'v-new', updatedAt: DateTime.utc(2026, 6, 1)),
    );
    await db.audioDao.insertRow(
      _audio(id: 'a-1', updatedAt: DateTime.utc(2026, 3, 1)),
    );

    final videos = await registry
        .watchByKind(MediaKind.video)
        .first
        .timeout(const Duration(seconds: 2));
    final audios = await registry
        .watchByKind(MediaKind.audio)
        .first
        .timeout(const Duration(seconds: 2));

    expect(videos.map((m) => m.id).toList(), ['v-new', 'v-old']);
    expect(audios.map((m) => m.id).toList(), ['a-1']);
  });

  test('watchByIds returns only the requested ids', () async {
    await db.videoDao.insertRow(
      _video(id: 'wanted-v', updatedAt: DateTime.utc(2026, 1, 1)),
    );
    await db.audioDao.insertRow(
      _audio(id: 'wanted-a', updatedAt: DateTime.utc(2026, 2, 1)),
    );
    await db.audioDao.insertRow(
      _audio(id: 'other', updatedAt: DateTime.utc(2026, 3, 1)),
    );

    final emissions = <List<Media>>[];
    final sub = registry
        .watchByIds({'wanted-v', 'wanted-a'})
        .listen(emissions.add);
    addTearDown(sub.cancel);
    await Future<void>.delayed(const Duration(milliseconds: 80));

    expect(emissions.last.map((m) => m.id).toSet(), {'wanted-v', 'wanted-a'});
  });

  test('watchByIds ignores unrelated library writes', () async {
    await db.videoDao.insertRow(
      _video(id: 'wanted', updatedAt: DateTime.utc(2026, 1, 1)),
    );
    final emissions = <List<Media>>[];
    final sub = registry.watchByIds({'wanted'}).listen(emissions.add);
    addTearDown(sub.cancel);
    await Future<void>.delayed(const Duration(milliseconds: 80));
    final before = emissions.length;
    expect(emissions.last.single.id, 'wanted');

    await db.batch((b) {
      for (var i = 0; i < 500; i++) {
        b.insert(
          db.audios,
          _audio(id: 'noise-$i', updatedAt: DateTime.utc(2026, 5, 1)),
        );
      }
    });
    await Future<void>.delayed(const Duration(milliseconds: 80));

    expect(emissions, hasLength(before));
    expect(emissions.last.single.id, 'wanted');
  });

  test('watchByProvider returns only that provider', () async {
    await db.audioDao.insertRow(
      _audio(
        id: 'craft-old',
        provider: 'craft',
        updatedAt: DateTime.utc(2026, 1, 1),
      ),
    );
    await db.audioDao.insertRow(
      _audio(
        id: 'craft-new',
        provider: 'craft',
        updatedAt: DateTime.utc(2026, 4, 1),
      ),
    );
    await db.audioDao.insertRow(
      _audio(id: 'user-1', updatedAt: DateTime.utc(2026, 5, 1)),
    );
    await db.videoDao.insertRow(
      _video(id: 'video-user', updatedAt: DateTime.utc(2026, 6, 1)),
    );

    final emissions = <List<Media>>[];
    final sub = registry.watchByProvider('craft').listen(emissions.add);
    addTearDown(sub.cancel);
    await Future<void>.delayed(const Duration(milliseconds: 80));

    expect(emissions.last.map((m) => m.id).toList(), [
      'craft-new',
      'craft-old',
    ]);
  });

  test('watchKindCounts counts without materializing rows', () async {
    await db.videoDao.insertRow(
      _video(id: 'v1', updatedAt: DateTime.utc(2026, 1, 1)),
    );
    await db.videoDao.insertRow(
      _video(id: 'v2', updatedAt: DateTime.utc(2026, 1, 2)),
    );
    await db.audioDao.insertRow(
      _audio(id: 'a1', updatedAt: DateTime.utc(2026, 1, 3)),
    );

    final counts = await registry.watchKindCounts().first.timeout(
      const Duration(seconds: 2),
    );

    expect(counts.video, 2);
    expect(counts.audio, 1);
  });

  test('watchYoutubeVideoIds ignores non-YouTube vids', () async {
    await db.videoDao.insertRow(
      _video(
        id: 'youtube',
        provider: 'youtube',
        vid: 'yt-1',
        updatedAt: DateTime.utc(2026, 1, 1),
      ),
    );
    await db.videoDao.insertRow(
      _video(
        id: 'local',
        provider: 'user',
        vid: 'local-vid',
        updatedAt: DateTime.utc(2026, 1, 2),
      ),
    );

    final ids = await registry.watchYoutubeVideoIds().first.timeout(
      const Duration(seconds: 2),
    );

    expect(ids, {'yt-1'});
  });
}
