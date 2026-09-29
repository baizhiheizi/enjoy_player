import 'dart:io';

import 'package:drift/drift.dart' show TableInfo, Variable;
import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/files/app_managed_media_gc.dart';
import 'package:enjoy_player/data/files/file_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../support/test_path_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PathProviderPlatform original;
  late Directory root;
  late AppDatabase db;

  setUp(() {
    original = PathProviderPlatform.instance;
    root = Directory.systemTemp.createTempSync('enjoy_media_gc');
    PathProviderPlatform.instance = TestPathProvider(root.path);
    db = AppDatabase(
      executor: NativeDatabase.memory(),
      name: 'enjoy_player_current',
    );
  });

  tearDown(() async {
    PathProviderPlatform.instance = original;
    await db.close();
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  });

  test(
    'keeps shared media when another per-user DB still references it',
    () async {
      final mediaDir = Directory(p.join(root.path, 'media'))
        ..createSync(recursive: true);
      final managed = File(p.join(mediaDir.path, 'shared.bin'));
      await managed.writeAsBytes([1, 2, 3]);
      final uri = Uri.file(managed.path).toString();

      final otherPath = p.join(root.path, 'enjoy_player_otheruser.sqlite');
      final other = sqlite3.open(otherPath);
      other.execute('''
      CREATE TABLE audios (
        id TEXT NOT NULL PRIMARY KEY,
        aid TEXT NOT NULL,
        provider TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        thumbnail_url TEXT,
        duration_seconds INTEGER NOT NULL,
        language TEXT NOT NULL,
        translation_key TEXT,
        source_text TEXT,
        voice TEXT,
        source TEXT,
        local_uri TEXT,
        md5 TEXT,
        size INTEGER,
        local_mtime_ms INTEGER,
        media_url TEXT,
        sync_status TEXT,
        server_updated_at INTEGER,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      );
      CREATE TABLE videos (
        id TEXT NOT NULL PRIMARY KEY,
        vid TEXT NOT NULL,
        provider TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        thumbnail_url TEXT,
        duration_seconds INTEGER NOT NULL,
        language TEXT NOT NULL,
        source TEXT,
        local_uri TEXT,
        md5 TEXT,
        size INTEGER,
        local_mtime_ms INTEGER,
        media_url TEXT,
        sync_status TEXT,
        server_updated_at INTEGER,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      );
    ''');
      other.execute(
        'INSERT INTO audios (id, aid, provider, title, duration_seconds, language, local_uri, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
        ['a1', 'aid', 'user', 't', 0, 'und', uri, 0, 0],
      );
      other.close();

      expect(
        await isAppManagedMediaStillReferenced(db: db, fileUri: uri),
        isTrue,
      );

      await deleteAppManagedMediaIfUnreferenced(
        db: db,
        storage: FileStorage(),
        fileUri: uri,
      );
      expect(managed.existsSync(), isTrue);
    },
  );

  test('deletes unreferenced app-managed media', () async {
    final mediaDir = Directory(p.join(root.path, 'media'))
      ..createSync(recursive: true);
    final managed = File(p.join(mediaDir.path, 'orphan.bin'));
    await managed.writeAsBytes([9]);
    final uri = Uri.file(managed.path).toString();

    expect(
      await isAppManagedMediaStillReferenced(db: db, fileUri: uri),
      isFalse,
    );
    await deleteAppManagedMediaIfUnreferenced(
      db: db,
      storage: FileStorage(),
      fileUri: uri,
    );
    expect(managed.existsSync(), isFalse);
  });

  test('keeps media still referenced by a row in the current DB', () async {
    final mediaDir = Directory(p.join(root.path, 'media'))
      ..createSync(recursive: true);
    final managed = File(p.join(mediaDir.path, 'current.bin'));
    await managed.writeAsBytes([4, 5, 6]);
    final uri = Uri.file(managed.path).toString();

    await db.videoDao.insertRow(
      VideoRow(
        id: 'v-current',
        vid: 'vid-current',
        provider: 'user',
        title: 'Current ref',
        durationSeconds: 0,
        language: 'und',
        localUri: uri,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
    );

    expect(
      await isAppManagedMediaStillReferenced(db: db, fileUri: uri),
      isTrue,
    );
    await deleteAppManagedMediaIfUnreferenced(
      db: db,
      storage: FileStorage(),
      fileUri: uri,
    );
    expect(managed.existsSync(), isTrue);
  });

  test(
    'cross-file probe SQL matches the Drift schema (schema-drift guard)',
    () async {
      final tableInfos = <String, TableInfo>{
        for (final entity in db.allSchemaEntities.whereType<TableInfo>())
          entity.actualTableName: entity,
      };

      expect(
        crossFileProbeLibraryTables,
        unorderedEquals(<String>['audios', 'videos']),
      );

      expect(
        () => crossFileProbeLocalUriSql('sqlite_master'),
        throwsArgumentError,
        reason:
            'crossFileProbeLocalUriSql must throw ArgumentError for a '
            'table outside crossFileProbeLibraryTables in every build mode',
      );

      for (final table in crossFileProbeLibraryTables) {
        final info = tableInfos[table];
        expect(
          info,
          isNotNull,
          reason: 'probe table `$table` is not registered on AppDatabase',
        );
        expect(
          info!.$columns.map((c) => c.name),
          contains(crossFileProbeLocalUriColumn),
          reason:
              'probe column `$crossFileProbeLocalUriColumn` missing from `$table`',
        );

        await db
            .customSelect(
              crossFileProbeLocalUriSql(table),
              variables: [Variable.withString('file:///drift-guard')],
            )
            .get();
      }
    },
  );
}
