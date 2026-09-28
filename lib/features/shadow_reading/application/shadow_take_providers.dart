/// Application-layer wiring for shadow-reading takes (issue #764 candidate 8).
///
/// Three seams the panel used to reach past:
///
/// * it constructed [ShadowTakeStore] itself, handing it a raw
///   [AppDatabase] and the sync-enqueue callback;
/// * it read `appDatabaseProvider` and drove `recordingDao.watchByEchoRegion`
///   straight from `build`;
/// * it repeated `recordingDao.listByEchoRegion` in both hotkey handlers.
///
/// All of it now comes from this module, so presentation never names a
/// database handle. Tests override one provider each.
///
/// Hand-written providers, not `@riverpod` annotations, for the same reason
/// `sync_providers.dart` and `cloud_providers.dart` are: `riverpod_generator`
/// raises `InvalidTypeException` on a Drift row type and on the
/// function-typed `SyncEnqueueFn`.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/sync/application/sync_providers.dart';

import 'shadow_take_store.dart';

/// Builds [ShadowTakeStore]s bound to the app's database and sync seam.
///
/// A factory rather than a store provider on purpose. [ShadowTakeStore] owns a
/// [MicRecorder] that is recreated after every stop (`record` on Windows keeps
/// stale Media Foundation state otherwise) and a private `_active` flag, and
/// the panel is embedded more than once — in the transcript echo card and in
/// vocabulary practice, and the transcript card is a list item, so several
/// panels can be mounted at the same time. A single shared store would let one
/// panel's capture mark another panel as recording and would hand two panels
/// the same recorder. The panel keeps owning its store (and disposing it in its
/// own `dispose`) while the *wiring* moves here.
final shadowTakeStoreFactoryProvider = Provider<ShadowTakeStoreFactory>((ref) {
  return ShadowTakeStoreFactory(
    db: ref.watch(appDatabaseProvider),
    enqueueSync: ref.read(syncEnqueueProvider),
  );
});

/// Identity of one echo region's recording window.
///
/// Stream/Future family arguments are compared with `==`, so the five query
/// fields are spelled out rather than passed positionally — without this,
/// every rebuild would open a fresh query.
@immutable
class EchoRegionRecordingsQuery {
  const EchoRegionRecordingsQuery({
    required this.targetType,
    required this.targetId,
    required this.language,
    required this.echoStartMs,
    required this.echoEndMs,
  });

  final String targetType;
  final String targetId;
  final String language;
  final int echoStartMs;
  final int echoEndMs;

  @override
  bool operator ==(Object other) =>
      other is EchoRegionRecordingsQuery &&
      other.targetType == targetType &&
      other.targetId == targetId &&
      other.language == language &&
      other.echoStartMs == echoStartMs &&
      other.echoEndMs == echoEndMs;

  @override
  int get hashCode =>
      Object.hash(targetType, targetId, language, echoStartMs, echoEndMs);
}

/// Take rows overlapping one echo region, newest first.
///
/// Yields the stream rather than a `StreamProvider` so the panel's existing
/// `StreamBuilder` keeps owning subscribe/cancel and one drift query is shared
/// per window (drift's `.watch()` streams are broadcast).
final echoRegionRecordingsProvider =
    Provider.family<Stream<List<RecordingRow>>, EchoRegionRecordingsQuery>((
      ref,
      query,
    ) {
      return ref
          .watch(appDatabaseProvider)
          .recordingDao
          .watchByEchoRegion(
            targetType: query.targetType,
            targetId: query.targetId,
            language: query.language,
            echoStartMs: query.echoStartMs,
            echoEndMs: query.echoEndMs,
          );
    });

/// One-shot read of the same window, for the hotkey handlers: they act on a
/// single take and must not open a subscription per keypress.
final echoRegionRecordingsOnceProvider =
    FutureProvider.family<List<RecordingRow>, EchoRegionRecordingsQuery>((
      ref,
      query,
    ) {
      return ref
          .watch(appDatabaseProvider)
          .recordingDao
          .listByEchoRegion(
            targetType: query.targetType,
            targetId: query.targetId,
            language: query.language,
            echoStartMs: query.echoStartMs,
            echoEndMs: query.echoEndMs,
          );
    });
