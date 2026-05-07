/// Providers for the currently selected primary and secondary transcript ids.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/db/app_database_provider.dart';

part 'active_transcript_provider.g.dart';

@riverpod
Stream<String?> activeTranscriptId(Ref ref, String mediaId) {
  final db = ref.watch(appDatabaseProvider);
  return db.sessionDao
      .watchForMedia(mediaId)
      .map((row) => row?.primaryTranscriptId);
}

@riverpod
Stream<String?> secondaryTranscriptId(Ref ref, String mediaId) {
  final db = ref.watch(appDatabaseProvider);
  return db.sessionDao
      .watchForMedia(mediaId)
      .map((row) => row?.secondaryTranscriptId);
}
