/// Providers for the currently selected primary and secondary transcript ids.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/db/app_database_provider.dart';
import '../../../data/db/media_target_resolver.dart';

part 'active_transcript_provider.g.dart';

@riverpod
Stream<String?> activeTranscriptId(Ref ref, String mediaId) {
  final db = ref.watch(appDatabaseProvider);
  return Stream.fromFuture(dexieTargetTypeForId(db, mediaId)).asyncExpand((tt) {
    if (tt == null) return Stream<String?>.value(null);
    return db.echoSessionDao
        .watchLatestForTarget(tt, mediaId)
        .map((row) => row?.transcriptId);
  });
}

@riverpod
Stream<String?> secondaryTranscriptId(Ref ref, String mediaId) {
  final db = ref.watch(appDatabaseProvider);
  return Stream.fromFuture(dexieTargetTypeForId(db, mediaId)).asyncExpand((tt) {
    if (tt == null) return Stream<String?>.value(null);
    return db.echoSessionDao
        .watchLatestForTarget(tt, mediaId)
        .map((row) => row?.secondaryTranscriptId);
  });
}
