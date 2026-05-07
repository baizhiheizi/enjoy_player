/// Imports media files into Drift + local storage.
library;

import 'package:cross_file/cross_file.dart';
import 'package:uuid/uuid.dart';

import '../../../core/errors/app_failure.dart';
import '../../../data/db/app_database.dart';
import '../../../data/files/file_storage.dart';
import '../../../data/files/media_resolver.dart';

class MediaLibraryRepository {
  MediaLibraryRepository(this._db, this._storage);

  // ignore: prefer_const_constructors
  static final Uuid _uuid = Uuid();

  final AppDatabase _db;
  final FileStorage _storage;

  Stream<List<MediaRow>> watchAll() => _db.mediaDao.watchAll();

  Future<String> importMedia(XFile file) async {
    try {
      final result = await _storage.importPickedFile(file);
      final id = _uuid.v5(
        Namespace.url.value,
        'enjoy:media:${result.fileHash}',
      );
      final kind = isVideoFileName(file.name) ? 'video' : 'audio';
      final now = DateTime.now();
      await _db.mediaDao.insertRow(
        MediaRow(
          id: id,
          kind: kind,
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

  Future<MediaRow?> getById(String id) => _db.mediaDao.getById(id);
}
