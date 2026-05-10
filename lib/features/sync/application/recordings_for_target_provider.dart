/// Local recordings for a library media target (shadow-reading / transcript UI).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';

/// `targetType` is Dexie style: `Audio` | `Video`.
final recordingsForTargetProvider = StreamProvider.autoDispose
    .family<List<RecordingRow>, ({String targetType, String targetId})>(
  (ref, key) {
    return ref
        .watch(appDatabaseProvider)
        .recordingDao
        .watchByTarget(key.targetType, key.targetId);
  },
);
