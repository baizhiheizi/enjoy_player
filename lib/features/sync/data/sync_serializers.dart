/// JSON preparation + server merge helpers for sync.
library;

import 'package:drift/drift.dart';

import 'package:enjoy_player/core/utils/remote_thumbnail_url.dart';
import 'package:enjoy_player/core/utils/youtube_video_identity.dart';
import 'package:enjoy_player/data/db/app_database.dart';

export 'package:enjoy_player/core/utils/remote_thumbnail_url.dart'
    show isRemoteThumbnailUrl, remoteThumbnailForCard;

DateTime? parseIsoDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

DateTime requireIsoDate(dynamic value, DateTime fallback) =>
    parseIsoDate(value) ?? fallback;

int durationSecondsFromJson(Map<String, dynamic> json) {
  final v = json['durationSeconds'] ?? json['duration'];
  if (v is int) return v;
  if (v is num) return v.round();
  return 0;
}

/// Recording API `duration` / `referenceStart` / `referenceDuration` are ms (web/extension contract).
int _recordingWireMsFromJson(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return 0;
}

/// Payload for [AudioApi.uploadAudio] body (`audio` key added by API).
Map<String, dynamic> prepareForSyncAudioMap(AudioRow row) {
  return <String, dynamic>{
    'id': row.id,
    'aid': row.aid,
    'provider': row.provider,
    'title': row.title,
    if (row.description != null) 'description': row.description,
    if (isRemoteThumbnailUrl(row.thumbnailUrl)) 'thumbnailUrl': row.thumbnailUrl!,
    'duration': row.durationSeconds,
    'language': row.language,
    if (row.translationKey != null) 'translationKey': row.translationKey,
    if (row.sourceText != null) 'sourceText': row.sourceText,
    if (row.voice != null) 'voice': row.voice,
    if (row.source != null) 'source': row.source,
    if (row.md5 != null) 'md5': row.md5,
    if (row.size != null) 'size': row.size,
    if (row.mediaUrl != null) 'mediaUrl': row.mediaUrl,
    'createdAt': row.createdAt.toUtc().toIso8601String(),
    'updatedAt': row.updatedAt.toUtc().toIso8601String(),
  };
}

Map<String, dynamic> prepareForSyncVideoMap(VideoRow row) {
  return <String, dynamic>{
    'id': row.id,
    'vid': row.vid,
    'provider': row.provider,
    'title': row.title,
    if (row.description != null) 'description': row.description,
    if (isRemoteThumbnailUrl(row.thumbnailUrl)) 'thumbnailUrl': row.thumbnailUrl!,
    'duration': row.durationSeconds,
    'language': row.language,
    if (row.source != null) 'source': row.source,
    if (row.md5 != null) 'md5': row.md5,
    if (row.size != null) 'size': row.size,
    if (row.mediaUrl != null) 'mediaUrl': row.mediaUrl,
    'createdAt': row.createdAt.toUtc().toIso8601String(),
    'updatedAt': row.updatedAt.toUtc().toIso8601String(),
  };
}

Map<String, dynamic> prepareForSyncRecordingMap(RecordingRow row) {
  return <String, dynamic>{
    'id': row.id,
    'targetId': row.targetId,
    'targetType': row.targetType,
    'duration': row.duration,
    if (row.md5 != null) 'md5': row.md5,
    'referenceText': row.referenceText,
    'referenceStart': row.referenceStart,
    'referenceDuration': row.referenceDuration,
    'language': row.language,
    if (row.audioUrl != null) 'audioUrl': row.audioUrl,
    if (row.pronunciationScore != null) 'pronunciationScore': row.pronunciationScore,
    if (row.assessmentJson != null) 'assessmentJson': row.assessmentJson,
    'createdAt': row.createdAt.toUtc().toIso8601String(),
    'updatedAt': row.updatedAt.toUtc().toIso8601String(),
  };
}

AudioRow audioRowFromServerJson(Map<String, dynamic> json) {
  final now = DateTime.now();
  final updatedAt = requireIsoDate(json['updatedAt'], now);
  final createdAt = requireIsoDate(json['createdAt'], updatedAt);
  return AudioRow(
    id: json['id'] as String,
    aid: json['aid'] as String? ?? json['id'] as String,
    provider: json['provider'] as String? ?? 'user',
    title: json['title'] as String? ?? '',
    description: json['description'] as String?,
    thumbnailUrl: json['thumbnailUrl'] as String?,
    durationSeconds: durationSecondsFromJson(json),
    language: json['language'] as String? ?? 'und',
    translationKey: json['translationKey'] as String?,
    sourceText: json['sourceText'] as String?,
    voice: json['voice'] as String?,
    source: json['source'] as String?,
    localUri: null,
    md5: json['md5'] as String?,
    size: json['size'] as int?,
    mediaUrl: json['mediaUrl'] as String?,
    syncStatus: json['syncStatus'] as String? ?? 'synced',
    serverUpdatedAt: parseIsoDate(json['serverUpdatedAt']),
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

VideoRow videoRowFromServerJson(Map<String, dynamic> json) {
  final now = DateTime.now();
  final updatedAt = requireIsoDate(json['updatedAt'], now);
  final createdAt = requireIsoDate(json['createdAt'], updatedAt);
  final vid = json['vid'] as String? ?? json['id'] as String;
  final mediaUrl = json['mediaUrl'] as String?;
  final source = json['source'] as String?;
  final provider = normalizeServerVideoProviderFields(
    rawProvider: json['provider'] as String?,
    vid: vid,
    mediaUrl: mediaUrl,
    source: source,
  );
  return VideoRow(
    id: json['id'] as String,
    vid: vid,
    provider: provider,
    title: json['title'] as String? ?? '',
    description: json['description'] as String?,
    thumbnailUrl: json['thumbnailUrl'] as String?,
    durationSeconds: durationSecondsFromJson(json),
    language: json['language'] as String? ?? 'und',
    source: json['source'] as String?,
    localUri: null,
    md5: json['md5'] as String?,
    size: json['size'] as int?,
    mediaUrl: json['mediaUrl'] as String?,
    syncStatus: json['syncStatus'] as String? ?? 'synced',
    serverUpdatedAt: parseIsoDate(json['serverUpdatedAt']),
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

RecordingRow recordingRowFromServerJson(Map<String, dynamic> json) {
  final now = DateTime.now();
  final updatedAt = requireIsoDate(json['updatedAt'], now);
  final createdAt = requireIsoDate(json['createdAt'], updatedAt);

  return RecordingRow(
    id: json['id'] as String,
    targetType: json['targetType'] as String? ?? 'Audio',
    targetId: json['targetId'] as String? ?? '',
    referenceStart: _recordingWireMsFromJson(json['referenceStart']),
    referenceDuration: _recordingWireMsFromJson(json['referenceDuration']),
    referenceText: json['referenceText'] as String? ?? '',
    language: json['language'] as String? ?? 'und',
    duration: _recordingWireMsFromJson(json['duration']),
    md5: json['md5'] as String?,
    audioUrl: json['audioUrl'] as String?,
    pronunciationScore: json['pronunciationScore'] as int?,
    assessmentJson: json['assessmentJson'] as String?,
    localPath: null,
    syncStatus: json['syncStatus'] as String? ?? 'synced',
    serverUpdatedAt: parseIsoDate(json['serverUpdatedAt']),
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

/// Server wins on ties (`>=`), matching web `resolveConflict`.
AudioRow mergeAudioLastWriteWins({
  required AudioRow? local,
  required Map<String, dynamic> server,
}) {
  final serverRow = audioRowFromServerJson(server);
  if (local == null) return serverRow;
  if (local.updatedAt.isAfter(serverRow.updatedAt)) return local;
  return serverRow.copyWith(
    localUri: Value(local.localUri),
  );
}

VideoRow mergeVideoLastWriteWins({
  required VideoRow? local,
  required Map<String, dynamic> server,
}) {
  final serverRow = videoRowFromServerJson(server);
  if (local == null) return serverRow;
  if (local.updatedAt.isAfter(serverRow.updatedAt)) return local;
  return serverRow.copyWith(
    localUri: Value(local.localUri),
  );
}

RecordingRow mergeRecordingLastWriteWins({
  required RecordingRow? local,
  required Map<String, dynamic> server,
}) {
  final serverRow = recordingRowFromServerJson(server);
  if (local == null) return serverRow;
  if (local.updatedAt.isAfter(serverRow.updatedAt)) return local;
  return serverRow.copyWith(
    localPath: Value(local.localPath),
  );
}

Map<String, dynamic> unwrapEntity(Map<String, dynamic> response, String key) {
  final inner = response[key];
  if (inner is Map<String, dynamic>) return inner;
  if (inner is Map) return Map<String, dynamic>.from(inner);
  return response;
}
