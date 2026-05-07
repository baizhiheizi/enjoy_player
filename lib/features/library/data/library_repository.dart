/// Imports media files into Drift + local storage.
library;

import 'package:cross_file/cross_file.dart';
import 'package:uuid/uuid.dart';

import '../../../core/errors/app_failure.dart';
import '../../../data/db/app_database.dart';
import '../../../data/files/file_storage.dart';
import '../../../data/files/media_resolver.dart';
import '../domain/media.dart';

Media _mediaFromRow(MediaRow row) {
  return Media(
    id: row.id,
    kind: MediaKindX.fromStorage(row.kind),
    title: row.title,
    sourceUri: row.sourceUri,
    thumbnailPath: row.thumbnailPath,
    durationMs: row.durationMs,
    language: row.language,
    fileHash: row.fileHash,
    fileSize: row.fileSize,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );
}

class MediaLibraryRepository {
  MediaLibraryRepository(this._db, this._storage);

  // ignore: prefer_const_constructors
  static final Uuid _uuid = Uuid();

  final AppDatabase _db;
  final FileStorage _storage;

  Stream<List<Media>> watchAll() =>
      _db.mediaDao.watchAll().map((rows) => rows.map(_mediaFromRow).toList());

  Future<String> importMedia(XFile file) async {
    try {
      final result = await _storage.importPickedFile(file);
      final id = _uuid.v5(
        Namespace.url.value,
        'enjoy:media:${result.fileHash}',
      );
      final kind =
          isVideoFileName(file.name) ? MediaKind.video : MediaKind.audio;
      final now = DateTime.now();
      await _db.mediaDao.insertRow(
        MediaRow(
          id: id,
          kind: kind.storageValue,
          title: result.title,
          sourceUri: result.fileUri,
          thumbnailPath: null,
          durationMs: 0,
          language: 'und',
          fileHash: result.fileHash,
          fileSize: result.fileSize,
          createdAt: now,
          updatedAt: now,
        ),
      );
      return id;
    } on AppFailure {
      rethrow;
    } catch (e, st) {
      Error.throwWithStackTrace(FileFailure('Import failed: $e'), st);
    }
  }

  Future<void> deleteMedia(String id) async {
    await _db.mediaDao.deleteId(id);
  }

  Future<Media?> getById(String id) async {
    final row = await _db.mediaDao.getById(id);
    return row == null ? null : _mediaFromRow(row);
  }
}
