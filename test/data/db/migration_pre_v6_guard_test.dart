/// Pre-v6 destructive upgrade guard (issue #818).
///
/// `onUpgrade` runs on the Drift background isolate, where the legacy JSON
/// backup's `path_provider` call used to throw and the whole backup was
/// skipped. The messenger is now installed for that isolate, but the upgrade
/// must still refuse to destroy the legacy schema if the backup does not land
/// — otherwise a full disk or an unwritable support directory silently costs
/// the user their library.
library;

import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

import '../../support/test_path_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempRoot;
  late File dbFile;
  late PathProviderPlatform originalPathProvider;

  setUp(() {
    tempRoot = Directory.systemTemp.createTempSync('pre_v6_upgrade_test_');
    dbFile = File(p.join(tempRoot.path, 'enjoy_player.sqlite'));
    originalPathProvider = PathProviderPlatform.instance;
  });

  tearDown(() {
    PathProviderPlatform.instance = originalPathProvider;
    if (tempRoot.existsSync()) tempRoot.deleteSync(recursive: true);
  });

  /// Seeds a file-backed database shaped like a real v5 install: one legacy
  /// `videos` table and nothing else.
  ///
  /// The current schema is created first and then dropped wholesale, because
  /// every table it brings (and their covering indexes, e.g.
  /// `idx_vocabulary_items_word_language`) only arrives after v5 — leaving any
  /// behind would make `m.createAll()` collide with artifacts a genuine v5
  /// database never had.
  Future<void> seedLegacyDatabase(int version) async {
    final seed = AppDatabase(executor: NativeDatabase(dbFile));
    final existing = await seed
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
        .get();
    for (final row in existing) {
      final name = row.read<String>('name');
      if (name.startsWith('sqlite_')) continue;
      await seed.customStatement('DROP TABLE IF EXISTS "$name"');
    }
    await seed.customStatement(
      'CREATE TABLE videos (id TEXT PRIMARY KEY, vid TEXT NOT NULL)',
    );
    await seed.customStatement(
      "INSERT INTO videos (id, vid) VALUES ('v-1','1')",
    );
    await seed.customStatement('PRAGMA user_version = $version');
    await seed.close();
  }

  Future<Set<String>> openAndReadTableNames(AppDatabase db) async {
    await db.customSelect('SELECT 1').get();
    final rows = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
        .get();
    return rows.map((row) => row.read<String>('name')).toSet();
  }

  test(
    'a failed backup aborts the upgrade instead of dropping legacy data',
    () async {
      await seedLegacyDatabase(5);
      PathProviderPlatform.instance = _BrokenPathProvider();

      final failing = AppDatabase(executor: NativeDatabase(dbFile));

      Object? caught;
      try {
        await failing.customSelect('SELECT 1').get();
      } on Object catch (e) {
        caught = e;
      }

      expect(caught, isA<StateError>());
      final message = (caught! as StateError).message;
      expect(message, contains('Aborting the pre-v6'));
      expect(message, contains('recoverable snapshot'));
      expect(message, contains('relaunch'));

      // Read the file directly: another `AppDatabase` would re-run the same
      // failing migration instead of letting the assertion see the stored state.
      final raw = sqlite3.sqlite3.open(dbFile.path);
      addTearDown(raw.close);
      final rows = raw.select('SELECT * FROM videos');
      expect(rows, hasLength(1), reason: 'the legacy row must survive');
      expect(rows.single['id'], 'v-1');
    },
  );

  test(
    'a successful backup still upgrades and drops the legacy tables',
    () async {
      await seedLegacyDatabase(5);
      final supportDir = Directory(p.join(tempRoot.path, 'support'))
        ..createSync(recursive: true);
      PathProviderPlatform.instance = TestPathProvider(supportDir.path);

      final db = AppDatabase(executor: NativeDatabase(dbFile));
      addTearDown(db.close);

      final names = await openAndReadTableNames(db);

      expect(names, containsAll(<String>['ai_cache', 'vocabulary_items']));
      final version = await db.customSelect('PRAGMA user_version').getSingle();
      expect(version.data.values.single, db.schemaVersion);

      final backups = Directory(
        p.join(supportDir.path, 'migrations'),
      ).listSync().map((e) => p.basename(e.path)).toList();
      expect(backups, isNotEmpty, reason: 'the snapshot must be on disk');
      final payload =
          jsonDecode(
                File(
                  p.join(supportDir.path, 'migrations', backups.single),
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      final tables = payload['tables'] as Map<String, dynamic>;
      expect(
        (tables['videos']! as Map<String, dynamic>)['rows'],
        hasLength(1),
        reason: 'the snapshot must contain the legacy row before the drop',
      );
    },
  );
}

class _BrokenPathProvider extends TestPathProvider {
  _BrokenPathProvider() : super('/this/does/not/matter');
  @override
  Future<String?> getApplicationSupportPath() async {
    throw const FileSystemException('synthetic failure for test');
  }
}
