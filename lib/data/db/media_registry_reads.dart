part of 'media_registry.dart';

mixin MediaRegistryReads {
  AppDatabase get _db;

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
}
