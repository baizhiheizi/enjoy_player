import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:cross_file/cross_file.dart';
import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/files/file_storage.dart';
import 'package:enjoy_player/features/library/data/library_repository.dart';
import 'package:enjoy_player/features/library/domain/media.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:uuid/uuid.dart';

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
      await db.mediaDao.insertRow(
        MediaRow(
          id: id,
          kind: 'video',
          title: 'Clip',
          sourceUri: 'file:///x.mp4',
          thumbnailPath: '/thumb.png',
          durationMs: 12_000,
          language: 'ja',
          fileHash: 'hh',
          fileSize: 99,
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
      final expectedId = const Uuid().v5(
        Namespace.url.value,
        'enjoy:media:$hash',
      );

      final src = File(p.join(root.path, 'in.txt'));
      await src.writeAsBytes(bytes);

      final id = await repo.importMedia(XFile(src.path, name: 'lesson.mp3'));
      expect(id, expectedId);

      final media = await repo.getById(id);
      expect(media, isNotNull);
      expect(media!.fileHash, hash);
      expect(media.kind, MediaKind.audio);
    });

    test('deleteMedia removes row', () async {
      final now = DateTime.now();
      const id = 'gone';
      await db.mediaDao.insertRow(
        MediaRow(
          id: id,
          kind: 'audio',
          title: 'x',
          sourceUri: 'file:///x.mp3',
          thumbnailPath: null,
          durationMs: 0,
          language: 'und',
          fileHash: 'f',
          fileSize: 1,
          createdAt: now,
          updatedAt: now,
        ),
      );

      await repo.deleteMedia(id);
      expect(await repo.getById(id), isNull);
    });
  });
}
