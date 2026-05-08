import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:cross_file/cross_file.dart';
import 'package:drift/native.dart';
import 'package:enjoy_player/core/ids/enjoy_ids.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/files/file_storage.dart';
import 'package:enjoy_player/features/library/data/library_repository.dart';
import 'package:enjoy_player/features/library/domain/media.dart';
import 'package:flutter_test/flutter_test.dart';
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
      db = AppDatabase(NativeDatabase.memory());
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

      final src = File(p.join(root.path, 'in.txt'));
      await src.writeAsBytes(bytes);

      final id = await repo.importMedia(XFile(src.path, name: 'lesson.mp3'));
      expect(id, expectedId);

      final media = await repo.getById(id);
      expect(media, isNotNull);
      expect(media!.contentHash, hash);
      expect(media.kind, MediaKind.audio);
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
  });
}
