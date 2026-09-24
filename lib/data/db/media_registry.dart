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
import 'package:enjoy_player/features/library/domain/media.dart';
import 'package:enjoy_player/features/sync/domain/sync_types.dart';

import 'app_database.dart';

/// Maps a [VideoRow] to the UI-facing domain [Media].
Media mediaFromVideo(VideoRow row) => mediaFromLibraryRow(
  id: row.id,
  kind: MediaKind.video,
  title: row.title,
  localUri: row.localUri,
  mediaUrl: row.mediaUrl,
  thumbnailUrl: row.thumbnailUrl,
  durationSeconds: row.durationSeconds,
  language: row.language,
  contentHash: row.vid,
  size: row.size,
  source: row.source,
  provider: row.provider,
  syncStatus: row.syncStatus,
  createdAt: row.createdAt,
  updatedAt: row.updatedAt,
);

/// Maps an [AudioRow] to the UI-facing domain [Media].
Media mediaFromAudio(AudioRow row) => mediaFromLibraryRow(
  id: row.id,
  kind: MediaKind.audio,
  title: row.title,
  localUri: row.localUri,
  mediaUrl: row.mediaUrl,
  thumbnailUrl: row.thumbnailUrl,
  durationSeconds: row.durationSeconds,
  language: row.language,
  contentHash: row.aid,
  size: row.size,
  source: row.source,
  provider: row.provider,
  syncStatus: row.syncStatus,
  createdAt: row.createdAt,
  updatedAt: row.updatedAt,
);

Media mediaFromLibraryRow({
  required String id,
  required MediaKind kind,
  required String title,
  required String? localUri,
  required String? mediaUrl,
  required String? thumbnailUrl,
  required int durationSeconds,
  required String language,
  required String contentHash,
  required int? size,
  required String? source,
  required String provider,
  String? syncStatus,
  required DateTime createdAt,
  required DateTime updatedAt,
}) {
  return Media(
    id: id,
    kind: kind,
    title: title,
    sourceUri: localUri ?? mediaUrl ?? '',
    thumbnailPath: thumbnailUrl,
    durationMs: durationSeconds * 1000,
    language: language,
    contentHash: contentHash,
    fileSize: size ?? 0,
    mediaUrl: mediaUrl,
    source: source,
    provider: provider,
    syncStatus: syncStatus,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

/// Unified read + write seam over the `videos` / `audios` split.
///
/// Video wins when the same id exists in both tables (defensive; production
/// never inserts one id into both — see `media_target_resolver_test.dart`).
///
/// Writes are thin dispatch choke points: callers hand over a row or a field
/// patch and get back the [MediaKind] they touched (so they can enqueue the
/// matching [SyncEntityType]) instead of branching per table themselves.
/// Transaction, GC, and enqueue policy stay with the callers.
class MediaRegistry {
  const MediaRegistry(this._db);

  final AppDatabase _db;

  Future<({VideoRow? video, AudioRow? audio})> _probe(String id) async {
    final video = await _db.videoDao.getById(id);
    final audio = video == null ? await _db.audioDao.getById(id) : null;
    return (video: video, audio: audio);
  }

  /// The video-then-audio probe as a public read for callers that need the
  /// full Drift rows (not the mapped [Media]) — e.g. playback resolution.
  ///
  /// Short-circuits like every registry read: the `audios` table is only
  /// queried when no video matched, so `audio` is `null` whenever `video`
  /// is not (video-first precedence).
  Future<({VideoRow? video, AudioRow? audio})> probeBoth(String id) =>
      _probe(id);

  /// The media with [id] as a domain [Media], or `null` when neither table
  /// holds it.
  Future<Media?> getById(String id) async {
    final hit = await _probe(id);
    final video = hit.video;
    if (video != null) return mediaFromVideo(video);
    final audio = hit.audio;
    if (audio != null) return mediaFromAudio(audio);
    return null;
  }

  /// Which table holds [id], or `null` when neither does.
  Future<MediaKind?> kindOf(String id) async {
    final hit = await _probe(id);
    if (hit.video != null) return MediaKind.video;
    if (hit.audio != null) return MediaKind.audio;
    return null;
  }

  /// Weapp / Dexie `TargetType` for [id] (`'Video'` | `'Audio'`), or `null`.
  Future<String?> dexieTargetTypeForId(String id) async =>
      (await kindOf(id))?.dexieTargetType;

  /// The on-disk `localUri` of the row holding [id], or `null` when the row
  /// is missing or has no local file reference.
  Future<String?> localUriOf(String id) async {
    final hit = await _probe(id);
    return hit.video?.localUri ?? hit.audio?.localUri;
  }

  /// Kind-known single-table read: the raw [VideoRow] with [id], or `null`.
  ///
  /// Callers that already know the row is a video (YouTube paths, poster
  /// capture, video-only transcript fetch, sync upload of a
  /// [SyncEntityType.video] entity) get one indexed `videos` lookup instead
  /// of a probe — and an audio-only id reads as `null`, exactly as a direct
  /// `videoDao.getById` would.
  Future<VideoRow?> getVideoById(String id) => _db.videoDao.getById(id);

  /// Kind-known single-table read: the raw [AudioRow] with [id], or `null`.
  ///
  /// The audio sibling of [getVideoById] — a video-only id reads as `null`
  /// (direct-`audioDao.getById` semantics preserved).
  Future<AudioRow?> getAudioById(String id) => _db.audioDao.getById(id);

  /// Kind-known single-table read: the raw [AudioRow] whose content hash
  /// equals [md5], or `null`.
  ///
  /// Audio-scoped deliberately (issue #753): Craft's dedupe key identifies
  /// synthesized audio, so it must NOT fall through to a `videos` row that
  /// happens to share an md5 — this stays the `audios`-only lookup
  /// `CraftLibraryRepository` had, just behind the seam.
  Future<AudioRow?> getAudioByMd5(String md5) => _db.audioDao.getByMd5(md5);

  /// Kind-known single-table read: the raw YouTube video row whose platform
  /// id (`vid`) equals [youtubeVid], or `null`.
  ///
  /// YouTube rows live only in `videos`, so this is a single-table lookup
  /// (provider + vid index) — used by Discover's add-to-library bridge and
  /// the library's re-import dedupe.
  Future<VideoRow?> getYoutubeVideoByVid(String youtubeVid) =>
      _db.videoDao.getYoutubeByVid(youtubeVid);

  /// Whether any library row references [localUri] as its local file — the
  /// current-DB half of the app-managed media GC's keep-or-delete probe
  /// (issue #753).
  ///
  /// The two per-table probes run concurrently (`Future.wait`, PR #756):
  /// both sides are indexed and the result is a plain OR, so there is no
  /// probe ordering to preserve. The *cross-file* half of that probe —
  /// scanning other per-user SQLite files the single-`AppDatabase`
  /// registry cannot reach — stays a documented raw-SQL exception in
  /// `app_managed_media_gc.dart` (ADR-0050 §5).
  Future<bool> existsByLocalUri(String localUri) async {
    final hits = await Future.wait([
      _db.videoDao.existsByLocalUri(localUri),
      _db.audioDao.existsByLocalUri(localUri),
    ]);
    return hits[0] || hits[1];
  }

  /// The merged `videos` + `audios` library as one stream of [Media],
  /// `createdAt`-descending (issue #753).
  ///
  /// The single data-layer owner of the glue that used to live in
  /// `MediaLibraryRepository.watchAll`: it subscribes both DAOs' `watchAll`
  /// streams, merges, sorts, and re-emits only when the merged list actually
  /// changes. The comments below pin the behaviors the merge layer must
  /// keep, plus the same-turn coalescing added for the PR #756 review:
  ///
  /// * **Dedupe.** A re-query that pushes unchanged rows back (a
  ///   `playbackSessionPersister` write bumping `updatedAt`, a duration
  ///   probe flipping one row, a no-op `insertOrReplace`) must not
  ///   re-emit the entire library — forcing
  ///   `libraryHomeRecentsProvider` to re-sort and
  ///   `libraryFilteredListsProvider` to re-filter + re-sort both lists.
  /// * **Empty first emission.** `lastEmitted` is nullable (rather than
  ///   starting as `const <Media>[]`) so an empty library still produces its
  ///   first emission: when both DAOs' initial snapshots are empty,
  ///   `merged` is `[]`, which used to compare equal to the empty starting
  ///   value and get swallowed by the dedupe check — leaving `watchAll()`
  ///   never emitting and every `StreamProvider` built on it stuck in
  ///   `AsyncLoading` forever whenever the local library has zero rows
  ///   (fixed in `a12634c3`, pinned by `library_repository_test.dart`).
  /// * **Same-turn coalescing** (PR #756). The two DAO listeners below
  ///   only buffer their snapshot and schedule ONE `emit` on a microtask,
  ///   so a both-tables change that re-delivers on both streams within
  ///   the same event-loop turn is merged into a single emission instead
  ///   of a partial-then-full pair (characterized in
  ///   `media_registry_test.dart`'s "characterizes Drift delivery" test:
  ///   Drift's watch streams are per-table — a single-table write
  ///   re-delivers only on that table's stream, and both-tables writes
  ///   re-deliver in one turn). A microtask always runs before its turn
  ///   ends, so single-table writes still emit immediately; waiting for
  ///   the sibling stream "to have produced since the last emit" (the
  ///   reviewer's literal suggestion) would deadlock single-table
  ///   updates, whose sibling stream legitimately never re-emits. When
  ///   deliveries do straddle microtask hops the old partial-then-full
  ///   fallback stands — a redundant rebuild, which is strictly better
  ///   than a stalled one.
  Stream<List<Media>> watchAll() {
    late StreamSubscription<List<VideoRow>> subV;
    late StreamSubscription<List<AudioRow>> subA;
    var videos = <VideoRow>[];
    var audios = <AudioRow>[];
    List<Media>? lastEmitted;
    // Previous merge inputs (PR #756): content-compared before any
    // allocation so an unchanged-input re-query skips merge+sort outright.
    List<VideoRow>? lastVideos;
    List<AudioRow>? lastAudios;
    var emitScheduled = false;

    void emit(StreamController<List<Media>> c) {
      // Input pre-check (PR #756): neither table's snapshot changed
      // content-wise since the last processed event (the common re-query
      // after a no-op write) — the merged+sorted output would be
      // identical, so skip the allocation and O(n log n) sort before they
      // even happen; the output-level dedupe below stays as the final
      // gate for changed inputs that map to an equal `Media` list.
      if (lastVideos != null &&
          _listEquals(lastVideos!, videos) &&
          _listEquals(lastAudios!, audios)) {
        return;
      }
      lastVideos = videos;
      lastAudios = audios;
      final merged = <Media>[
        ...videos.map(mediaFromVideo),
        ...audios.map(mediaFromAudio),
      ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (lastEmitted != null && _listEquals(lastEmitted!, merged)) {
        return;
      }
      lastEmitted = merged;
      c.add(merged);
    }

    // Buffer-and-schedule: at most one emit is pending per event-loop
    // turn; the first DAO delivery of a turn schedules it, any second
    // delivery that lands before the microtask runs just refreshes its
    // input buffer (see the same-turn coalescing note above).
    void scheduleEmit(StreamController<List<Media>> c) {
      if (emitScheduled) return;
      emitScheduled = true;
      scheduleMicrotask(() {
        emitScheduled = false;
        emit(c);
      });
    }

    return Stream<List<Media>>.multi((controller) {
      subV = _db.videoDao.watchAll().listen((rows) {
        videos = rows;
        scheduleEmit(controller);
      }, onError: controller.addError);
      subA = _db.audioDao.watchAll().listen((rows) {
        audios = rows;
        scheduleEmit(controller);
      }, onError: controller.addError);
      controller.onCancel = () {
        unawaited(subV.cancel());
        unawaited(subA.cancel());
      };
    });
  }

  /// Insert-or-replace write choke points. Row construction stays with the
  /// caller (the two tables have different columns); only the write crosses
  /// here so every `videos` / `audios` mutation has one owner.
  Future<void> upsertVideo(VideoRow row) => _db.videoDao.insertRow(row);

  /// See [upsertVideo].
  Future<void> upsertAudio(AudioRow row) => _db.audioDao.insertRow(row);

  /// Deletes [id] from whichever table holds it (video first).
  ///
  /// Returns the kind deleted so the caller can enqueue the matching sync
  /// entity, or `null` when neither table holds [id].
  Future<MediaKind?> deleteById(String id) async {
    final hit = await _probe(id);
    if (hit.video != null) {
      await _db.videoDao.deleteId(id);
      return MediaKind.video;
    }
    if (hit.audio != null) {
      await _db.audioDao.deleteId(id);
      return MediaKind.audio;
    }
    return null;
  }

  /// Bumps `updatedAt` on whichever table holds [id] so Home "Recent media"
  /// can resurface the row. No-op when [id] is unknown; no sync enqueue.
  Future<void> touchUpdatedAt(String id) async {
    final hit = await _probe(id);
    if (hit.video != null) {
      await _db.videoDao.touchUpdatedAt(id);
    } else if (hit.audio != null) {
      await _db.audioDao.touchUpdatedAt(id);
    }
  }

  /// Sets the content language on whichever table holds [id] (video first).
  ///
  /// Writes [language] verbatim — canonicalization and the "already that
  /// language, skip the write + sync" guard are caller policy. Returns the
  /// kind updated, or `null` when neither table holds [id]. Transcript
  /// fetch-state clearing deliberately stays outside the registry: it touches
  /// the `transcript_fetch_states` table, and the registry spans only
  /// `videos` / `audios`.
  Future<MediaKind?> updateLanguage(String id, String language) async {
    final hit = await _probe(id);
    if (hit.video != null) {
      await _db.videoDao.updateLanguage(id: id, language: language);
      return MediaKind.video;
    }
    if (hit.audio != null) {
      await _db.audioDao.updateLanguage(id: id, language: language);
      return MediaKind.audio;
    }
    return null;
  }

  /// Persists a (re)located local file — `localUri` plus its trust metadata
  /// ([bookmarkData], [size], [mtimeMs]) — onto the row holding [id] (video
  /// first), bumping `updatedAt`.
  ///
  /// All four fields are applied, `null` included (a relocate without a
  /// security-scoped bookmark must clear a stale one). Returns the kind
  /// updated, or `null` when neither table holds [id].
  Future<MediaKind?> updateLocalFile(
    String id, {
    required String localUri,
    required Uint8List? bookmarkData,
    required int? size,
    required int? mtimeMs,
  }) async {
    final hit = await _probe(id);
    final video = hit.video;
    if (video != null) {
      await _db.videoDao.insertRow(
        video.copyWith(
          localUri: Value(localUri),
          bookmarkData: Value(bookmarkData),
          size: Value(size),
          localMtimeMs: Value(mtimeMs),
          updatedAt: DateTime.now(),
        ),
      );
      return MediaKind.video;
    }
    final audio = hit.audio;
    if (audio != null) {
      await _db.audioDao.insertRow(
        audio.copyWith(
          localUri: Value(localUri),
          bookmarkData: Value(bookmarkData),
          size: Value(size),
          localMtimeMs: Value(mtimeMs),
          updatedAt: DateTime.now(),
        ),
      );
      return MediaKind.audio;
    }
    return null;
  }

  /// One-off duration backfill: patches `durationSeconds` (bumping
  /// `updatedAt`) on whichever table holds [id] **when the stored duration is
  /// still zero** — the shared write-after-read of the ffmpeg probe
  /// (`media_duration_probe.dart`) and the engine duration listener
  /// (`player_position_tracker.dart`).
  ///
  /// Returns the kind patched, or `null` when the row is missing or already
  /// has a non-zero duration (first writer wins).
  ///
  /// Dispatches to the per-table `setDurationIfZero` DAO methods so the
  /// "still zero?" guard is a `WHERE duration_seconds = 0` clause — the
  /// conditional update is race-free (two concurrent callers cannot
  /// double-write each other's snapshots) and preserves any unrelated
  /// fields a parallel writer may have changed.
  Future<MediaKind?> patchDurationIfZero(String id, int durationSeconds) async {
    final hit = await _probe(id);
    final video = hit.video;
    if (video != null) {
      return await _db.videoDao.setDurationIfZero(id, durationSeconds)
          ? MediaKind.video
          : null;
    }
    final audio = hit.audio;
    if (audio != null) {
      return await _db.audioDao.setDurationIfZero(id, durationSeconds)
          ? MediaKind.audio
          : null;
    }
    return null;
  }

  /// Writes a captured poster thumbnail onto a video row (video-only write —
  /// poster capture has no audio counterpart). Bumps `updatedAt`.
  Future<void> updateVideoThumbnail(String id, String absoluteThumbPath) =>
      _db.videoDao.updateLocalThumbnail(id, absoluteThumbPath);

  /// Patches oEmbed-resolved YouTube `title` / `thumbnailUrl` onto the video
  /// row (video-only write — YouTube rows live only in `videos`, so there is
  /// no audio counterpart to dispatch). Bumps `updatedAt`.
  ///
  /// A `null` [thumbnailUrl] leaves the stored thumbnail untouched (only the
  /// title is refreshed) — matching `VideoDao.updateYoutubeMetadata`.
  Future<void> updateYoutubeMetadata({
    required String id,
    required String title,
    String? thumbnailUrl,
  }) => _db.videoDao.updateYoutubeMetadata(
    id: id,
    title: title,
    thumbnailUrl: thumbnailUrl,
  );

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

/// Element-wise list equality with `==` semantics (identical reference,
/// then length, then per-index), mirroring `flutter/foundation`'s
/// `listEquals`.
///
/// Lives here so `lib/data/db/` keeps no `package:flutter/` dependency
/// (PR #756): the registry was the only consumer of the foundation import
/// in this file. [VideoRow] / [AudioRow] / [Media] all implement value
/// `==`, so the comparison is by content, not by instance.
bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
