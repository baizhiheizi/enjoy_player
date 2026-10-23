/// One seam over the `videos` / `audios` table split (issues #593, #723).
///
/// The library persists media in two sibling tables, but callers think in
/// terms of a single `Media`. [MediaRegistry] hides the video-then-audio
/// probe, the row→[Media] mapping, and the per-table write dispatch so each
/// branch exists once — callers and tests cross the same interface instead
/// of re-probing or writing both DAOs (ADR-0002 keeps the queries in the
/// data layer).
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:enjoy_player/core/utils/stream_combine_latest.dart';
import 'package:enjoy_player/core/utils/stream_distinct.dart';
import 'package:enjoy_player/features/library/domain/media.dart';
import 'package:enjoy_player/features/sync/domain/sync_types.dart';

import 'app_database.dart';
import 'media_library_row.dart';

part 'media_registry_mapping.dart';
part 'media_registry_reads.dart';
part 'media_registry_streams.dart';
part 'media_registry_writes.dart';

/// Unified read + write seam over the `videos` / `audios` split.
///
/// Video wins when the same id exists in both tables (defensive; production
/// never inserts one id into both — see `media_target_resolver_test.dart`).
///
/// Writes are thin dispatch choke points: callers hand over a row or a field
/// patch and get back the [MediaKind] they touched (so they can enqueue the
/// matching [SyncEntityType]) instead of branching per table themselves.
/// Transaction, GC, and enqueue policy stay with the callers.
class MediaRegistry
    with MediaRegistryReads, MediaRegistryStreams, MediaRegistryWrites {
  const MediaRegistry(this._db);

  @override
  final AppDatabase _db;

  /// The cloud-sync entity matching [kind] — the one mapping enqueue sites
  /// need after a registry write returns the touched kind.
  ///
  /// [SyncEntityType] lives in the sync feature's domain layer; importing it
  /// here follows the existing `data → features/*/domain` direction (this
  /// file already imports `features/library/domain/media.dart`, and
  /// `sync_types.dart` itself has no imports, so no cycle can form).
  static SyncEntityType syncEntityTypeOf(MediaKind kind) => switch (kind) {
    MediaKind.video => SyncEntityType.video,
    MediaKind.audio => SyncEntityType.audio,
  };
}
