/// Imports media files into Drift + local storage.
library;

import 'dart:async';

import 'package:cross_file/cross_file.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/ids/enjoy_ids.dart';
import '../../../data/db/app_database.dart';
import '../../../data/files/file_storage.dart';
import '../../../data/files/media_resolver.dart';
import '../domain/media.dart';

Media _mediaFromVideo(VideoRow row) {
  return Media(
    id: row.id,
    kind: MediaKind.video,
    title: row.title,
    sourceUri: row.localUri ?? '',
    thumbnailPath: row.thumbnailUrl,
    durationMs: row.durationSeconds * 1000,
    language: row.language,
    contentHash: row.vid,
    fileSize: row.size ?? 0,
    mediaUrl: row.mediaUrl,
    source: row.source,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );
}

Media _mediaFromAudio(AudioRow row) {
  return Media(
    id: row.id,
    kind: MediaKind.audio,
    title: row.title,
    sourceUri: row.localUri ?? '',
    thumbnailPath: row.thumbnailUrl,
    durationMs: row.durationSeconds * 1000,
    language: row.language,
    contentHash: row.aid,
    fileSize: row.size ?? 0,
    mediaUrl: row.mediaUrl,
    source: row.source,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );
}

class MediaLibraryRepository {
  MediaLibraryRepository(this._db, this._storage);

  final AppDatabase _db;
  final FileStorage _storage;

  Stream<List<Media>> watchAll() {
    late StreamSubscription<List<VideoRow>> subV;
    late StreamSubscription<List<AudioRow>> subA;
    var videos = <VideoRow>[];
    var audios = <AudioRow>[];

    void emit(StreamController<List<Media>> c) {
      final merged = <Media>[
        ...videos.map(_mediaFromVideo),
        ...audios.map(_mediaFromAudio),
      ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      c.add(merged);
    }

    return Stream<List<Media>>.multi((controller) {
      subV = _db.videoDao.watchAll().listen(
        (rows) {
          videos = rows;
          emit(controller);
        },
        onError: controller.addError,
      );
      subA = _db.audioDao.watchAll().listen(
        (rows) {
          audios = rows;
          emit(controller);
        },
        onError: controller.addError,
      );
      controller.onCancel = () {
        subV.cancel();
        subA.cancel();
      };
    });
  }

  Future<String> importMedia(XFile file) async {
    try {
      final result = await _storage.importPickedFile(file);
      final kind =
          isVideoFileName(file.name) ? MediaKind.video : MediaKind.audio;
      final now = DateTime.now();
      if (kind == MediaKind.video) {
        final id = enjoyVideoId(vid: result.fileHash);
        await _db.videoDao.insertRow(
          VideoRow(
            id: id,
            vid: result.fileHash,
            provider: 'user',
            title: result.title,
            description: null,
            thumbnailUrl: null,
            durationSeconds: 0,
            language: 'und',
            source: null,
            localUri: result.fileUri,
            md5: result.fileHash,
            size: result.fileSize,
            mediaUrl: null,
            syncStatus: 'local',
            serverUpdatedAt: null,
            createdAt: now,
            updatedAt: now,
          ),
        );
        return id;
      }
      final id = enjoyAudioId(aid: result.fileHash);
      await _db.audioDao.insertRow(
        AudioRow(
          id: id,
          aid: result.fileHash,
          provider: 'user',
          title: result.title,
          description: null,
          thumbnailUrl: null,
          durationSeconds: 0,
          language: 'und',
          translationKey: null,
          sourceText: null,
          voice: null,
          source: null,
          localUri: result.fileUri,
          md5: result.fileHash,
          size: result.fileSize,
          mediaUrl: null,
          syncStatus: 'local',
          serverUpdatedAt: null,
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
    final v = await _db.videoDao.getById(id);
    if (v != null) {
      await _db.videoDao.deleteId(id);
      return;
    }
    await _db.audioDao.deleteId(id);
  }

  Future<Media?> getById(String id) async {
    final v = await _db.videoDao.getById(id);
    if (v != null) return _mediaFromVideo(v);
    final a = await _db.audioDao.getById(id);
    if (a != null) return _mediaFromAudio(a);
    return null;
  }
}
