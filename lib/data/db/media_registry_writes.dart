part of 'media_registry.dart';

mixin MediaRegistryWrites {
  AppDatabase get _db;

  Future<({VideoRow? video, AudioRow? audio})> _probe(String id);

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
  Future<MediaKind?> updateLanguage(
    String id,
    String language, {
    ({VideoRow? video, AudioRow? audio})? probed,
  }) async {
    final hit = probed ?? await _probe(id);
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

  /// Writes the display title on whichever table holds [id] (video first),
  /// bumping `updatedAt`.
  ///
  /// Like [updateLanguage], [title] is written verbatim — trimming and the
  /// "already that title, skip the write + sync" guard are caller policy.
  /// Returns the kind updated, or `null` when neither table holds [id].
  Future<MediaKind?> updateTitle(
    String id,
    String title, {
    ({VideoRow? video, AudioRow? audio})? probed,
  }) async {
    final hit = probed ?? await _probe(id);
    if (hit.video != null) {
      await _db.videoDao.updateTitle(id: id, title: title);
      return MediaKind.video;
    }
    if (hit.audio != null) {
      await _db.audioDao.updateTitle(id: id, title: title);
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
}
