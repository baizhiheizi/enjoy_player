/// Upload local entities to Enjoy API (metadata only).
library;

import 'package:drift/drift.dart';

import 'package:enjoy_player/data/api/api_exception.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/api/services/audio_api.dart';
import 'package:enjoy_player/data/api/services/recording_api.dart';
import 'package:enjoy_player/data/api/services/video_api.dart';
import 'package:enjoy_player/features/sync/data/sync_serializers.dart';

class SyncUploadService {
  SyncUploadService({
    required AppDatabase db,
    required AudioApi audioApi,
    required VideoApi videoApi,
    required RecordingApi recordingApi,
  })  : _db = db,
        _audioApi = audioApi,
        _videoApi = videoApi,
        _recordingApi = recordingApi;

  final AppDatabase _db;
  final AudioApi _audioApi;
  final VideoApi _videoApi;
  final RecordingApi _recordingApi;

  Future<void> uploadAudio(AudioRow row) async {
    final response = await _audioApi.uploadAudio(prepareForSyncAudioMap(row));
    final inner = unwrapEntity(response, 'audio');
    final serverUpdated =
        parseIsoDate(inner['updatedAt']) ?? DateTime.now().toUtc();
    await _db.audioDao.insertRow(
      row.copyWith(
        syncStatus: const Value('synced'),
        serverUpdatedAt: Value(serverUpdated),
        mediaUrl: Value(inner['mediaUrl'] as String? ?? row.mediaUrl),
        updatedAt: parseIsoDate(inner['updatedAt']) ?? row.updatedAt,
      ),
    );
  }

  Future<void> uploadVideo(VideoRow row) async {
    final response = await _videoApi.uploadVideo(prepareForSyncVideoMap(row));
    final inner = unwrapEntity(response, 'video');
    final serverUpdated =
        parseIsoDate(inner['updatedAt']) ?? DateTime.now().toUtc();
    await _db.videoDao.insertRow(
      row.copyWith(
        syncStatus: const Value('synced'),
        serverUpdatedAt: Value(serverUpdated),
        mediaUrl: Value(inner['mediaUrl'] as String? ?? row.mediaUrl),
        updatedAt: parseIsoDate(inner['updatedAt']) ?? row.updatedAt,
      ),
    );
  }

  Future<void> uploadRecording(RecordingRow row) async {
    final response =
        await _recordingApi.uploadRecording(prepareForSyncRecordingMap(row));
    final inner = unwrapEntity(response, 'recording');
    final serverUpdated =
        parseIsoDate(inner['updatedAt']) ?? DateTime.now().toUtc();
    await _db.recordingDao.insertRow(
      row.copyWith(
        syncStatus: const Value('synced'),
        serverUpdatedAt: Value(serverUpdated),
        audioUrl: Value(inner['audioUrl'] as String? ?? row.audioUrl),
        updatedAt: parseIsoDate(inner['updatedAt']) ?? row.updatedAt,
      ),
    );
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
