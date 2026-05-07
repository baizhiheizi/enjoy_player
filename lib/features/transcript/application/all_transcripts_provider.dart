/// All subtitle tracks stored for a media item (embedded + imported).
///
/// Uses manual StreamProvider to avoid a riverpod_generator + Drift edge case
/// where generated row types cannot be converted to code (see library_media_provider.dart).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/app_database.dart';
import '../../../data/db/app_database_provider.dart';

final allTranscriptsForMediaProvider =
    StreamProvider.family<List<TranscriptRow>, String>((ref, mediaId) {
      final db = ref.watch(appDatabaseProvider);
      return db.transcriptDao.watchAllForMedia(mediaId);
    });
