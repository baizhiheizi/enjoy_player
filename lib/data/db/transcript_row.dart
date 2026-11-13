/// Hand-written construction helper for the generated [TranscriptRow]:
/// one home for the structural defaults every transcript upsert site shares
/// (`referenceId` / `trackIndex` / `serverUpdatedAt` null, `label` '',
/// `syncStatus` 'local', `updatedAt` = [createdAt]) so a schema change
/// threads through one literal instead of nine.
library;

import 'app_database.dart';

TranscriptRow buildTranscriptRow({
  required String id,
  required String targetType,
  required String targetId,
  required String language,
  required String source,
  required String timelineJson,
  String? referenceId,
  String label = '',
  int? trackIndex,
  String? syncStatus = 'local',
  DateTime? serverUpdatedAt,
  required DateTime createdAt,
  DateTime? updatedAt,
}) {
  return TranscriptRow(
    id: id,
    targetType: targetType,
    targetId: targetId,
    language: language,
    source: source,
    timelineJson: timelineJson,
    referenceId: referenceId,
    label: label,
    trackIndex: trackIndex,
    syncStatus: syncStatus,
    serverUpdatedAt: serverUpdatedAt,
    createdAt: createdAt,
    updatedAt: updatedAt ?? createdAt,
  );
}
