/// Safe cleanup for shared app-managed media files under `documents/media/`.
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/media_registry.dart';
import 'package:enjoy_player/data/files/file_storage.dart';
import 'package:enjoy_player/data/files/lasting_local_access.dart';

/// The `videos` / `audios` tables the *cross-file* raw-SQL probe searches in
/// other per-user SQLite files, plus [crossFileProbeLocalUriColumn] — the
/// single source for every query string the probe runs (issue #753).
///
/// This cross-file probe is a named, documented exception to the
/// MediaRegistry reads-and-writes mandate: ADR-0050 §5 requires consulting
/// **other accounts'** per-user DB files before deleting a shared
/// app-managed copy, and a registry bound to one [AppDatabase] cannot open
/// foreign database files. The schema-drift test in
/// `test/data/files/app_managed_media_gc_test.dart` fails if any of these
/// tables or the column drift from the Drift schema. The *current* DB half
/// of the same check routes through `MediaRegistry.existsByLocalUri`.
const crossFileProbeLibraryTables = <String>['audios', 'videos'];

/// The column the cross-file probe matches — see
/// [crossFileProbeLibraryTables].
const crossFileProbeLocalUriColumn = 'local_uri';

/// The one existence query the cross-file probe runs per table in
/// [crossFileProbeLibraryTables].
///
/// Table names cannot be bound as parameters in SQLite, so [table] is
/// interpolated — it must come from that const list (checked below with a
/// runtime [ArgumentError] guard rather than an `assert`, which release /
/// AOT builds strip), which is what keeps the raw SQL single-sourced and
/// drift-testable.
String crossFileProbeLocalUriSql(String table) {
  if (!crossFileProbeLibraryTables.contains(table)) {
    throw ArgumentError.value(
      table,
      'table',
      'must come from crossFileProbeLibraryTables',
    );
  }
  return 'SELECT 1 FROM $table WHERE $crossFileProbeLocalUriColumn = ? '
      'LIMIT 1';
}

/// Whether [fileUri] is still referenced by any library row that should keep
/// the on-disk app-managed copy alive.
///
/// Two halves (issue #753): the current [db] is probed through
/// [MediaRegistry]; other per-user SQLite files under the app documents
/// directory (`enjoy_player_<userId>.sqlite`) are probed with the
/// single-sourced raw SQL above, because copy-fallback imports share
/// `{documents}/media/{hash}{ext}` across accounts and a single-
/// [AppDatabase] registry cannot reach foreign DB files (ADR-0050 §5).
Future<bool> isAppManagedMediaStillReferenced({
  required AppDatabase db,
  required String fileUri,
}) async {
  if (fileUri.isEmpty) return false;
  if (!await isAppManagedMediaPath(fileUri)) return false;

  if (await MediaRegistry(db).existsByLocalUri(fileUri)) return true;

  return _otherPerUserDbReferencesLocalUri(
    currentDbBaseName: db.databaseFileBaseName,
    fileUri: fileUri,
  );
}

/// Deletes [fileUri] only when it is app-managed and unreferenced.
Future<void> deleteAppManagedMediaIfUnreferenced({
  required AppDatabase db,
  required FileStorage storage,
  required String? fileUri,
}) async {
  if (fileUri == null || fileUri.isEmpty) return;
  if (!await isAppManagedMediaPath(fileUri)) return;
  if (await isAppManagedMediaStillReferenced(db: db, fileUri: fileUri)) {
    return;
  }
  await storage.deleteAppManagedMedia(fileUri);
}

Future<bool> _otherPerUserDbReferencesLocalUri({
  required String currentDbBaseName,
  required String fileUri,
}) async {
  try {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(docs.path);
    if (!await dir.exists()) return false;

    final currentFileName = '$currentDbBaseName.sqlite';
    await for (final entity in dir.list(followLinks: false)) {
      if (entity is! File) continue;
      final name = p.basename(entity.path);
      if (!_isPerUserLibraryDbFileName(name)) continue;
      if (name == currentFileName) continue;
      if (_sqliteFileReferencesLocalUri(entity.path, fileUri)) {
        return true;
      }
    }
  } on Object {
    // Best-effort — if we cannot scan, keep the file (safer than deleting).
    return true;
  }
  return false;
}

bool _isPerUserLibraryDbFileName(String name) {
  // Per-user: enjoy_player_<sanitizedUserId>.sqlite
  // Skip device-global enjoy_player.sqlite and sidecar -wal/-shm files.
  if (!name.startsWith('${AppDatabase.deviceGlobalDatabaseName}_')) {
    return false;
  }
  return name.endsWith('.sqlite');
}

bool _sqliteFileReferencesLocalUri(String dbPath, String fileUri) {
  Database? raw;
  try {
    raw = sqlite3.open(dbPath, mode: OpenMode.readOnly);
    for (final table in crossFileProbeLibraryTables) {
      final rows = raw.select(crossFileProbeLocalUriSql(table), [fileUri]);
      if (rows.isNotEmpty) return true;
    }
    return false;
  } on Object {
    // Missing tables / locked DB — treat as referenced to avoid data loss.
    return true;
  } finally {
    raw?.close();
  }
}
