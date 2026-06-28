/// Upload local entities to Enjoy API (metadata only).
library;

import 'package:drift/drift.dart';

import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/data/api/api_exception.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/api/services/audio_api.dart';
import 'package:enjoy_player/data/api/services/recording_api.dart';
import 'package:enjoy_player/data/api/services/video_api.dart';
import 'package:enjoy_player/features/sync/data/sync_serializers.dart';

final _log = logNamed('sync.upload');

/// Thrown when a server upload response omits the required `updatedAt` field.
///
/// Without `updatedAt` we cannot trust [serverUpdatedAt] — defaulting to
/// `DateTime.now()` would silently make the local row appear newer than the
/// server and trigger spurious re-uploads that could clobber concurrent
/// server-side edits. The row is left untouched and the sync queue will retry.
class SyncMissingUpdatedAtError extends Error {
  SyncMissingUpdatedAtError(this.entity, this.id);

  final String entity;
  final String id;

  @override
  String toString() =>
      'SyncMissingUpdatedAtError($entity $id): server response missing updatedAt';
}

class SyncUploadService {
  SyncUploadService({
    required this._db,
    required this._audioApi,
    required this._videoApi,
    required this._recordingApi,
  });

  final AppDatabase _db;
  final AudioApi _audioApi;
  final VideoApi _videoApi;
  final RecordingApi _recordingApi;

  Future<void> uploadAudio(AudioRow row) async {
    Map<String, dynamic> inner;
    try {
      final response = await _audioApi.uploadAudio(prepareForSyncAudioMap(row));
      inner = unwrapEntity(response, 'audio');
    } on ApiException catch (e) {
      if (!e.isDuplicateEntity) rethrow;
      _log.fine('audio ${row.id} already on server; fetching existing row');
      final response = await _audioApi.audio(row.id);
      inner = unwrapEntity(response, 'audio');
    }
    final serverUpdated = _requireServerUpdated(
      inner,
      entity: 'audio',
      id: row.id,
    );
    await _db.audioDao.insertRow(
      row.copyWith(
        syncStatus: const Value('synced'),
        serverUpdatedAt: Value(serverUpdated),
        mediaUrl: Value(inner['mediaUrl'] as String? ?? row.mediaUrl),
        updatedAt: serverUpdated,
      ),
    );
  }

  Future<void> uploadVideo(VideoRow row) async {
    final inner = await _uploadVideoPayload(row);
    await _persistSyncedVideo(row, inner);
  }

  Future<Map<String, dynamic>> _uploadVideoPayload(VideoRow row) async {
    try {
      final response = await _videoApi.uploadVideo(prepareForSyncVideoMap(row));
      return unwrapEntity(response, 'video');
    } on ApiException catch (e) {
      if (!e.isDuplicateEntity) rethrow;
      _log.fine('video ${row.id} already on server; fetching existing row');
      final response = await _videoApi.video(row.id);
      return unwrapEntity(response, 'video');
    }
  }

  Future<void> _persistSyncedVideo(
    VideoRow row,
    Map<String, dynamic> inner,
  ) async {
    final serverUpdated = _requireServerUpdated(
      inner,
      entity: 'video',
      id: row.id,
    );
    await _db.videoDao.insertRow(
      row.copyWith(
        syncStatus: const Value('synced'),
        serverUpdatedAt: Value(serverUpdated),
        mediaUrl: Value(inner['mediaUrl'] as String? ?? row.mediaUrl),
        updatedAt: serverUpdated,
      ),
    );
  }

  Future<void> uploadRecording(RecordingRow row) async {
    final response = await _recordingApi.uploadRecording(
      prepareForSyncRecordingMap(row),
    );
    final inner = unwrapEntity(response, 'recording');
    final serverUpdated = _requireServerUpdated(
      inner,
      entity: 'recording',
      id: row.id,
    );
    await _db.recordingDao.insertRow(
      row.copyWith(
        syncStatus: const Value('synced'),
        serverUpdatedAt: Value(serverUpdated),
        audioUrl: Value(inner['audioUrl'] as String? ?? row.audioUrl),
        updatedAt: serverUpdated,
      ),
    );
  }

  DateTime _requireServerUpdated(
    Map<String, dynamic> inner, {
    required String entity,
    required String id,
  }) {
    final parsed = parseIsoDate(inner['updatedAt']);
    if (parsed == null) {
      _log.warning(
        'server response missing updatedAt for $entity $id; refusing to write',
      );
      throw SyncMissingUpdatedAtError(entity, id);
    }
    return parsed;
  }

  Future<void> deleteAudio(String id) async {
    try {
      await _audioApi.deleteAudio(id);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return;
      rethrow;
    }
  }

  Future<void> deleteVideo(String id) async {
    try {
      await _videoApi.deleteVideo(id);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return;
      rethrow;
    }
  }

  Future<void> deleteRecording(String id) async {
    try {
      await _recordingApi.deleteRecording(id);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return;
      rethrow;
    }
  }
}
