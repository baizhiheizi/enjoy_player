import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:cross_file/cross_file.dart';
import 'package:drift/native.dart';
import 'package:enjoy_player/core/errors/app_failure.dart';
import 'package:enjoy_player/core/ids/enjoy_ids.dart';
import 'package:enjoy_player/core/utils/youtube_video_identity.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/files/file_storage.dart';
import 'package:enjoy_player/features/library/data/library_repository.dart';
import 'package:enjoy_player/features/library/domain/media.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import '../../support/test_path_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MediaLibraryRepository', () {
    late PathProviderPlatform original;
    late Directory root;
    late AppDatabase db;
    late MediaLibraryRepository repo;

    setUp(() {
      original = PathProviderPlatform.instance;
      root = Directory.systemTemp.createTempSync('enjoy_lib_repo_test');
      PathProviderPlatform.instance = TestPathProvider(root.path);
      db = AppDatabase(executor: NativeDatabase.memory());
      repo = MediaLibraryRepository(db, FileStorage());
    });

    tearDown(() async {
      PathProviderPlatform.instance = original;
      await db.close();
      if (root.existsSync()) {
        root.deleteSync(recursive: true);
      }
    });

    test('getById maps row to Media domain', () async {
      final now = DateTime.now();
      const id = 'id-1';
      await db.videoDao.insertRow(
        VideoRow(
          id: id,
          vid: 'hh',
          provider: 'user',
          title: 'Clip',
          description: null,
          thumbnailUrl: '/thumb.png',
          durationSeconds: 12,
          language: 'ja',
          source: null,
          localUri: 'file:///x.mp4',
          md5: null,
          size: 99,
          mediaUrl: null,
          syncStatus: null,
          serverUpdatedAt: null,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final media = await repo.getById(id);
      expect(media, isNotNull);
      expect(media!.kind, MediaKind.video);
      expect(media.title, 'Clip');
      expect(media.durationMs, 12_000);
    });

    test('importMedia stores file and returns deterministic id', () async {
      final bytes = utf8.encode('hello-import');
      final hash = sha256.convert(bytes).toString();
      final expectedId = enjoyAudioId(aid: hash);

      final src = File(p.join(root.path, 'lesson.mp3'));
      await src.writeAsBytes(bytes);

      final id = await repo.importMedia(XFile(src.path));
      expect(id, expectedId);

      final media = await repo.getById(id);
      expect(media, isNotNull);
      expect(media!.contentHash, hash);
      expect(media.kind, MediaKind.audio);
    });

    test('importMedia rejects unsupported image extension', () async {
      final src = File(p.join(root.path, 'photo.jpg'));
      await src.writeAsBytes([1, 2, 3]);

      await expectLater(
        repo.importMedia(XFile(src.path, name: 'photo.jpg')),
        throwsA(isA<UnsupportedImportFileFailure>()),
      );

      expect(await db.videoDao.watchAll().first, isEmpty);
      expect(await db.audioDao.watchAll().first, isEmpty);
    });

    test('deleteMedia removes row', () async {
      final now = DateTime.now();
      const id = 'gone';
      await db.audioDao.insertRow(
        AudioRow(
          id: id,
          aid: 'f',
          provider: 'user',
          title: 'x',
          description: null,
          thumbnailUrl: null,
          durationSeconds: 0,
          language: 'und',
          translationKey: null,
          sourceText: null,
          voice: null,
          source: null,
          localUri: 'file:///x.mp3',
          md5: null,
          size: 1,
          mediaUrl: null,
          syncStatus: null,
          serverUpdatedAt: null,
          createdAt: now,
          updatedAt: now,
        ),
      );

      await repo.deleteMedia(id);
      expect(await repo.getById(id), isNull);
    });

    test(
      'relocateLocalFile sets localUri when picked file hash matches',
      () async {
        final bytes = utf8.encode('relocate-body');
        final hash = sha256.convert(bytes).toString();
        final id = enjoyVideoId(vid: hash);
        final src = File(p.join(root.path, 'clip.mp4'));
        await src.writeAsBytes(bytes);

        final now = DateTime.now();
        await db.videoDao.insertRow(
          VideoRow(
            id: id,
            vid: hash,
            provider: 'user',
            title: 'Synced',
            description: null,
            thumbnailUrl: null,
            durationSeconds: 0,
            language: 'und',
            source: null,
            localUri: null,
            md5: hash,
            size: bytes.length,
            mediaUrl: null,
            syncStatus: 'synced',
            serverUpdatedAt: null,
            createdAt: now,
            updatedAt: now,
          ),
        );

        await repo.relocateLocalFile(
          mediaId: id,
          picked: XFile(src.path, name: 'clip.mp4'),
        );

        final row = await db.videoDao.getById(id);
        expect(row, isNotNull);
        expect(row!.localUri, isNotNull);
        expect(row.localUri, contains(hash));
        expect(row.size, bytes.length);
      },
    );

    test(
      'relocateLocalFile throws and keeps localUri when hash mismatches',
      () async {
        final goodBytes = utf8.encode('good');
        final hash = sha256.convert(goodBytes).toString();
        final id = enjoyAudioId(aid: hash);
        final wrong = File(p.join(root.path, 'wrong.mp3'));
        await wrong.writeAsBytes(utf8.encode('other-bytes'));

        final now = DateTime.now();
        await db.audioDao.insertRow(
          AudioRow(
            id: id,
            aid: hash,
            provider: 'user',
            title: 'Remote',
            description: null,
            thumbnailUrl: null,
            durationSeconds: 0,
            language: 'und',
            translationKey: null,
            sourceText: null,
            voice: null,
            source: null,
            localUri: null,
            md5: hash,
            size: goodBytes.length,
            mediaUrl: null,
            syncStatus: null,
            serverUpdatedAt: null,
            createdAt: now,
            updatedAt: now,
          ),
        );

        await expectLater(
          repo.relocateLocalFile(
            mediaId: id,
            picked: XFile(wrong.path, name: 'wrong.mp3'),
          ),
          throwsA(isA<FileFailure>()),
        );

        final row = await db.audioDao.getById(id);
        expect(row!.localUri, isNull);
      },
    );

    test(
      'ensureVideoPosterAfterMetadataInsert does not set thumbnail_url',
      () async {
        final now = DateTime.now();
        const id = 'v-poster-hook';
        await db.videoDao.insertRow(
          VideoRow(
            id: id,
            vid: 'x',
            provider: 'user',
            title: 't',
            description: null,
            thumbnailUrl: null,
            durationSeconds: 0,
            language: 'und',
            source: null,
            localUri: null,
            md5: List.generate(64, (_) => 'a').join(),
            size: 1,
            mediaUrl: 'https://example.com/video.mp4',
            syncStatus: null,
            serverUpdatedAt: null,
            createdAt: now,
            updatedAt: now,
          ),
        );
        final row = await db.videoDao.getById(id);
        await repo.ensureVideoPosterAfterMetadataInsert(row!);
        final after = await db.videoDao.getById(id);
        expect(after!.thumbnailUrl, isNull);
      },
    );

    test('importYoutubeVideo uses prefetched title without oEmbed', () async {
      const vid = 'dQw4w9WgXcQ';
      final oembedClient = MockClient((_) async => http.Response('', 500));

      final ytRepo = MediaLibraryRepository(
        db,
        FileStorage(),
        oembedClient: oembedClient,
      );

      final id = await ytRepo.importYoutubeVideo(
        vid,
        prefetchedTitle: 'RSS Title',
        prefetchedThumbnailUrl: 'https://i.ytimg.com/vi/$vid/hqdefault.jpg',
      );

      final row = await db.videoDao.getById(id);
      expect(row!.title, 'RSS Title');
      expect(row.thumbnailUrl, 'https://i.ytimg.com/vi/$vid/hqdefault.jpg');
    });

    test('refreshYoutubeMetadataIfNeeded patches placeholder title', () async {
      const vid = 'dQw4w9WgXcQ';
      final mediaId = enjoyVideoId(provider: 'youtube', vid: vid);
      final now = DateTime.now();

      await db.videoDao.insertRow(
        VideoRow(
          id: mediaId,
          vid: vid,
          provider: 'youtube',
          title: youtubeImportPlaceholderTitle(vid),
          description: null,
          thumbnailUrl: null,
          durationSeconds: 0,
          language: 'und',
          source: 'youtube',
          localUri: null,
          md5: null,
          size: null,
          mediaUrl: 'https://www.youtube.com/watch?v=$vid',
          syncStatus: 'pending',
          serverUpdatedAt: null,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final oembedClient = MockClient((request) async {
        expect(request.url.host, 'www.youtube.com');
        return http.Response(
          '{"title":"Real Title","thumbnail_url":"https://i.ytimg.com/vi/$vid/hqdefault.jpg"}',
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final ytRepo = MediaLibraryRepository(
        db,
        FileStorage(),
        oembedClient: oembedClient,
      );

      final patch = await ytRepo.refreshYoutubeMetadataIfNeeded(mediaId);
      expect(patch?.title, 'Real Title');
      expect(patch?.thumbnailUrl, 'https://i.ytimg.com/vi/$vid/hqdefault.jpg');

      final row = await db.videoDao.getById(mediaId);
      expect(row!.title, 'Real Title');
      expect(row.thumbnailUrl, 'https://i.ytimg.com/vi/$vid/hqdefault.jpg');
    });

    test('refreshYoutubeMetadataIfNeeded skips complete metadata', () async {
      const vid = 'dQw4w9WgXcQ';
      final mediaId = enjoyVideoId(provider: 'youtube', vid: vid);
      final now = DateTime.now();

      await db.videoDao.insertRow(
        VideoRow(
          id: mediaId,
          vid: vid,
          provider: 'youtube',
          title: 'Already Good',
          description: null,
          thumbnailUrl: 'https://i.ytimg.com/vi/$vid/hqdefault.jpg',
          durationSeconds: 120,
          language: 'und',
          source: 'youtube',
          localUri: null,
          md5: null,
          size: null,
          mediaUrl: 'https://www.youtube.com/watch?v=$vid',
          syncStatus: 'synced',
          serverUpdatedAt: null,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final oembedClient = MockClient((_) async {
        fail('oEmbed should not be called');
      });

      final ytRepo = MediaLibraryRepository(
        db,
        FileStorage(),
        oembedClient: oembedClient,
      );

      final patch = await ytRepo.refreshYoutubeMetadataIfNeeded(mediaId);
      expect(patch, isNull);
    });

    test('watchAll deduplicates identical emissions', () async {
      final now = DateTime.now();
      const id = 'dup-1';
      await db.audioDao.insertRow(
        AudioRow(
          id: id,
          aid: 'f',
          provider: 'user',
          title: 'x',
          description: null,
          thumbnailUrl: null,
          durationSeconds: 0,
          language: 'und',
          translationKey: null,
          sourceText: null,
          voice: null,
          source: null,
          localUri: 'file:///x.mp3',
          md5: null,
          size: 1,
          mediaUrl: null,
          syncStatus: null,
          serverUpdatedAt: null,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final emissions = <List<Media>>[];
      final sub = repo.watchAll().listen(emissions.add);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(emissions, hasLength(1));
      expect(emissions.first, hasLength(1));

      // No-op write: same row, same fields. Drift re-queries both tables and
      // pushes the unchanged merged list back through watchAll. The repo
      // should suppress the duplicate so home/library providers don't re-sort.
      await db.audioDao.insertRow(
        AudioRow(
          id: id,
          aid: 'f',
          provider: 'user',
          title: 'x',
          description: null,
          thumbnailUrl: null,
          durationSeconds: 0,
          language: 'und',
          translationKey: null,
          sourceText: null,
          voice: null,
          source: null,
          localUri: 'file:///x.mp3',
          md5: null,
          size: 1,
          mediaUrl: null,
          syncStatus: null,
          serverUpdatedAt: null,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(emissions, hasLength(1));

      // A real change must still emit.
      await db.audioDao.insertRow(
        AudioRow(
          id: id,
          aid: 'f',
          provider: 'user',
          title: 'renamed',
          description: null,
          thumbnailUrl: null,
          durationSeconds: 0,
          language: 'und',
          translationKey: null,
          sourceText: null,
          voice: null,
          source: null,
          localUri: 'file:///x.mp3',
          md5: null,
          size: 1,
          mediaUrl: null,
          syncStatus: null,
          serverUpdatedAt: null,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(emissions, hasLength(2));
      expect(emissions.last.single.title, 'renamed');

      await sub.cancel();
    });
  });
}
