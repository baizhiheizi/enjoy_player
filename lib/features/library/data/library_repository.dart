/// Imports media files into Drift + local storage.
library;

import 'dart:async';

import 'package:cross_file/cross_file.dart';
import 'package:drift/drift.dart';

import 'package:enjoy_player/core/errors/app_failure.dart';
import 'package:enjoy_player/core/ids/enjoy_ids.dart';
import 'package:enjoy_player/core/utils/youtube_video_identity.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/files/ffmpeg_media_probe.dart';
import 'package:enjoy_player/data/files/file_storage.dart';
import 'package:enjoy_player/data/files/media_resolver.dart';
import 'package:enjoy_player/features/library/domain/media.dart';
import 'package:enjoy_player/features/library/data/youtube_oembed_api.dart';
import 'package:enjoy_player/features/sync/domain/sync_types.dart';
import 'package:http/http.dart' as http;

typedef YoutubeMetadataPatch = ({String title, String? thumbnailUrl});

Media _mediaFromVideo(VideoRow row) {
  return Media(
    id: row.id,
    kind: MediaKind.video,
    title: row.title,
    sourceUri: row.localUri ?? row.mediaUrl ?? '',
    thumbnailPath: row.thumbnailUrl,
    durationMs: row.durationSeconds * 1000,
    language: row.language,
    contentHash: row.vid,
    fileSize: row.size ?? 0,
    mediaUrl: row.mediaUrl,
    source: row.source,
    provider: row.provider,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );
}

Media _mediaFromAudio(AudioRow row) {
  return Media(
    id: row.id,
    kind: MediaKind.audio,
    title: row.title,
    sourceUri: row.localUri ?? row.mediaUrl ?? '',
    thumbnailPath: row.thumbnailUrl,
    durationMs: row.durationSeconds * 1000,
    language: row.language,
    contentHash: row.aid,
    fileSize: row.size ?? 0,
    mediaUrl: row.mediaUrl,
    source: row.source,
    provider: row.provider,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );
}

class MediaLibraryRepository {
  MediaLibraryRepository(
    this._db,
    this._storage, {
    this._enqueueSync,
    this._oembedClient,
  });

  final AppDatabase _db;
  final FileStorage _storage;
  final SyncEnqueueFn? _enqueueSync;
  final http.Client? _oembedClient;

  Stream<List<Media>> watchAll() {
    late StreamSubscription<List<VideoRow>> subV;
    late StreamSubscription<List<AudioRow>> subA;
    var videos = <VideoRow>[];
    var audios = <AudioRow>[];

    // Cache the last emitted merged list so we can skip identical re-emissions.
    // Both Drift `watchAll` streams re-query on ANY table change; without this,
    // a single row update (e.g. a `playbackSessionPersister` write that bumps
    // `updatedAt`, or a duration probe that flips one row) currently re-emits
    // the entire library — forcing `libraryHomeRecentsProvider` to re-sort and
    // `libraryFilteredListsProvider` to re-filter + re-sort both lists.
    var lastEmitted = const <Media>[];

    void emit(StreamController<List<Media>> c) {
      final merged = <Media>[
        ...videos.map(_mediaFromVideo),
        ...audios.map(_mediaFromAudio),
      ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (_listEqualsMedia(lastEmitted, merged)) return;
      lastEmitted = merged;
      c.add(merged);
    }

    return Stream<List<Media>>.multi((controller) {
      subV = _db.videoDao.watchAll().listen((rows) {
        videos = rows;
        emit(controller);
      }, onError: controller.addError);
      subA = _db.audioDao.watchAll().listen((rows) {
        audios = rows;
        emit(controller);
      }, onError: controller.addError);
      controller.onCancel = () {
        subV.cancel();
        subA.cancel();
      };
    });
  }

  /// [signedInUserId] when non-null enables web-aligned `aid`/`vid` + outbound sync.
  Future<String> importMedia(XFile file, {String? signedInUserId}) async {
    try {
      if (!isImportableLocalMediaFileName(file.name)) {
        throw const UnsupportedImportFileFailure();
      }
      final result = await _storage.importPickedFile(file);
      final kind = isVideoFileName(file.name)
          ? MediaKind.video
          : MediaKind.audio;
      final now = DateTime.now();
      final contentHash = result.contentHashHex;
      final signedIn = signedInUserId != null && signedInUserId.isNotEmpty;

      if (kind == MediaKind.video) {
        late final String id;
        late final String vid;
        late final String syncStatus;
        if (signedIn) {
          vid = enjoyLocalVideoVid(
            contentHashHex: contentHash,
            userId: signedInUserId,
          );
          id = enjoyVideoId(vid: vid);
          syncStatus = 'pending';
        } else {
          vid = contentHash;
          id = enjoyVideoId(vid: vid);
          syncStatus = 'local-pending-rekey';
        }
        final row = VideoRow(
          id: id,
          vid: vid,
          provider: 'user',
          title: result.title,
          description: null,
          thumbnailUrl: null,
          durationSeconds: 0,
          language: 'und',
          source: null,
          localUri: result.fileUri,
          md5: contentHash,
          size: result.fileSize,
          mediaUrl: null,
          syncStatus: syncStatus,
          serverUpdatedAt: null,
          createdAt: now,
          updatedAt: now,
        );
        await _db.videoDao.insertRow(row);
        unawaited(_probeAndPatchDuration(id, result.fileUri, video: true));
        if (signedIn) {
          await _enqueueSync?.call(SyncEntityType.video, id, SyncAction.create);
        }
        return id;
      }

      late final String id;
      late final String aid;
      late final String syncStatus;
      if (signedIn) {
        aid = enjoyLocalAudioAid(
          contentHashHex: contentHash,
          userId: signedInUserId,
        );
        id = enjoyAudioId(aid: aid);
        syncStatus = 'pending';
      } else {
        aid = contentHash;
        id = enjoyAudioId(aid: aid);
        syncStatus = 'local-pending-rekey';
      }
      final audioRow = AudioRow(
        id: id,
        aid: aid,
        provider: 'user',
        title: result.title,
        description: null,
        thumbnailUrl: null,
        durationSeconds: 0,
        language: 'und',
        translationKey: null,
        sourceText: null,
        voice: null,
        source: null,
        localUri: result.fileUri,
        md5: contentHash,
        size: result.fileSize,
        mediaUrl: null,
        syncStatus: syncStatus,
        serverUpdatedAt: null,
        createdAt: now,
        updatedAt: now,
      );
      await _db.audioDao.insertRow(audioRow);
      unawaited(_probeAndPatchDuration(id, result.fileUri, video: false));
      if (signedIn) {
        await _enqueueSync?.call(SyncEntityType.audio, id, SyncAction.create);
      }
      return id;
    } on AppFailure {
      rethrow;
    } catch (e, st) {
      Error.throwWithStackTrace(FileFailure('Import failed: $e'), st);
    }
  }

  /// Imports a YouTube video by pasted URL or bare video id.
  Future<String> importYoutubeVideo(
    String rawInput, {
    String? signedInUserId,
    String? prefetchedTitle,
    String? prefetchedThumbnailUrl,
  }) async {
    final id = parseYoutubeVideoId(rawInput);
    if (id == null) {
      throw const FileFailure('Invalid YouTube URL or video ID.');
    }
    final dup = await _db.videoDao.getYoutubeByVid(id);
    if (dup != null) {
      await _maybePatchYoutubeMetadata(
        dup,
        prefetchedTitle: prefetchedTitle,
        prefetchedThumbnailUrl: prefetchedThumbnailUrl,
      );
      return dup.id;
    }

    final oembed = await fetchYoutubeOembed(id, client: _oembedClient);
    final title = _resolveYoutubeTitle(
      id,
      prefetchedTitle: prefetchedTitle,
      oembed: oembed,
    );
    final thumb = _resolveYoutubeThumbnail(
      prefetchedThumbnailUrl: prefetchedThumbnailUrl,
      oembed: oembed,
    );

    final rowId = enjoyVideoId(provider: 'youtube', vid: id);
    final now = DateTime.now();
    final signedIn = signedInUserId != null && signedInUserId.isNotEmpty;

    final row = VideoRow(
      id: rowId,
      vid: id,
      provider: 'youtube',
      title: title,
      description: null,
      thumbnailUrl: thumb,
      durationSeconds: 0,
      language: 'und',
      source: 'youtube',
      localUri: null,
      md5: null,
      size: null,
      mediaUrl: 'https://www.youtube.com/watch?v=$id',
      syncStatus: signedIn ? 'pending' : 'local-pending-rekey',
      serverUpdatedAt: null,
      createdAt: now,
      updatedAt: now,
    );
    await _db.videoDao.insertRow(row);
    if (signedIn) {
      await _enqueueSync?.call(SyncEntityType.video, rowId, SyncAction.create);
    }
    return rowId;
  }

  /// Re-fetches oEmbed when title/thumbnail are still import placeholders.
  Future<YoutubeMetadataPatch?> refreshYoutubeMetadataIfNeeded(
    String mediaId,
  ) async {
    final row = await _db.videoDao.getById(mediaId);
    if (row == null || row.provider.toLowerCase() != 'youtube') return null;
    if (!_youtubeMetadataNeedsRefresh(row)) return null;

    final meta = await fetchYoutubeOembed(row.vid, client: _oembedClient);
    if (meta == null) return null;

    final title = meta.title;
    final thumb = meta.thumbnailUrl ?? row.thumbnailUrl;
    await _db.videoDao.updateYoutubeMetadata(
      id: mediaId,
      title: title,
      thumbnailUrl: thumb,
    );
    await _enqueueYoutubeMetadataSync(row);
    return (title: title, thumbnailUrl: thumb);
  }

  bool _youtubeMetadataNeedsRefresh(VideoRow row) {
    return isYoutubeImportPlaceholderTitle(row.title, row.vid) ||
        row.thumbnailUrl == null ||
        row.thumbnailUrl!.trim().isEmpty;
  }

  String _resolveYoutubeTitle(
    String vid, {
    String? prefetchedTitle,
    YoutubeOembedMetadata? oembed,
  }) {
    final pref = prefetchedTitle?.trim();
    if (pref != null &&
        pref.isNotEmpty &&
        !isYoutubeImportPlaceholderTitle(pref, vid)) {
      return pref;
    }
    return oembed?.title ?? youtubeImportPlaceholderTitle(vid);
  }

  String? _resolveYoutubeThumbnail({
    String? prefetchedThumbnailUrl,
    YoutubeOembedMetadata? oembed,
  }) {
    final pref = prefetchedThumbnailUrl?.trim();
    if (pref != null && pref.isNotEmpty) return pref;
    return oembed?.thumbnailUrl;
  }

  Future<void> _maybePatchYoutubeMetadata(
    VideoRow row, {
    String? prefetchedTitle,
    String? prefetchedThumbnailUrl,
  }) async {
    if (!_youtubeMetadataNeedsRefresh(row)) return;

    final oembed = await fetchYoutubeOembed(row.vid, client: _oembedClient);
    final title = _resolveYoutubeTitle(
      row.vid,
      prefetchedTitle: prefetchedTitle,
      oembed: oembed,
    );
    final needsTitle =
        isYoutubeImportPlaceholderTitle(row.title, row.vid) &&
        !isYoutubeImportPlaceholderTitle(title, row.vid);
    final thumb = _resolveYoutubeThumbnail(
      prefetchedThumbnailUrl: prefetchedThumbnailUrl,
      oembed: oembed,
    );
    final needsThumb =
        (row.thumbnailUrl == null || row.thumbnailUrl!.trim().isEmpty) &&
        thumb != null &&
        thumb.isNotEmpty;
    if (!needsTitle && !needsThumb) return;

    final resolvedTitle = needsTitle ? title : row.title;
    final resolvedThumb = needsThumb ? thumb : row.thumbnailUrl;
    await _db.videoDao.updateYoutubeMetadata(
      id: row.id,
      title: resolvedTitle,
      thumbnailUrl: resolvedThumb,
    );
    await _enqueueYoutubeMetadataSync(row);
  }

  Future<void> _enqueueYoutubeMetadataSync(VideoRow row) async {
    final status = row.syncStatus?.trim();
    if (status == null || status.isEmpty) return;
    await _enqueueSync?.call(SyncEntityType.video, row.id, SyncAction.update);
  }

  /// Fills `duration_seconds` when still zero after import, using `ffmpeg -i`.
  Future<void> _probeAndPatchDuration(
    String mediaId,
    String fileUri, {
    required bool video,
  }) async {
    final ffmpeg = await FfmpegMediaProbe.resolveFfmpegExecutable();
    if (ffmpeg == null) return;
    final input = FfmpegMediaProbe.mediaInputForFfmpeg(fileUri);
    final stderr = await FfmpegMediaProbe.loadIdentifyStderr(ffmpeg, input);
    if (stderr == null || stderr.isEmpty) return;
    final sec = FfmpegMediaProbe.parseDurationSeconds(stderr);
    if (sec == null || sec <= 0) return;

    if (video) {
      final row = await _db.videoDao.getById(mediaId);
      if (row == null || row.durationSeconds != 0) return;
      await _db.videoDao.insertRow(
        row.copyWith(durationSeconds: sec, updatedAt: DateTime.now()),
      );
    } else {
      final row = await _db.audioDao.getById(mediaId);
      if (row == null || row.durationSeconds != 0) return;
      await _db.audioDao.insertRow(
        row.copyWith(durationSeconds: sec, updatedAt: DateTime.now()),
      );
    }
  }

  /// Video posters are captured from the active [PlayerController] via media_kit
  /// screenshot; FFmpeg background extraction was removed.
  ///
  /// Kept as a stable hook for call sites (e.g. cloud add-to-library) — no-op.
  Future<void> ensureVideoPosterAfterMetadataInsert(VideoRow _) async {}

  Future<void> deleteMedia(String id) async {
    final v = await _db.videoDao.getById(id);
    if (v != null) {
      await _enqueueSync?.call(SyncEntityType.video, id, SyncAction.delete);
      await _db.videoDao.deleteId(id);
      return;
    }
    final a = await _db.audioDao.getById(id);
    if (a != null) {
      await _enqueueSync?.call(SyncEntityType.audio, id, SyncAction.delete);
    }
    await _db.audioDao.deleteId(id);
  }

  Future<Media?> getById(String id) async {
    final v = await _db.videoDao.getById(id);
    if (v != null) return _mediaFromVideo(v);
    final a = await _db.audioDao.getById(id);
    if (a != null) return _mediaFromAudio(a);
    return null;
  }

  /// Copy a user-picked file into app storage only if its chunked SHA-256 matches the
  /// row's `md5` field, then set [localUri] for playback on this device.
  Future<void> relocateLocalFile({
    required String mediaId,
    required XFile picked,
  }) async {
    try {
      final video = await _db.videoDao.getById(mediaId);
      if (video != null) {
        final hash = video.md5;
        if (hash == null || hash.isEmpty) {
          throw const FileFailure(
            'Cannot locate file: this item has no content fingerprint.',
          );
        }
        final result = await _storage.importPickedFileExpectingHash(
          picked,
          expectedHashHex: hash,
        );
        await _db.videoDao.insertRow(
          video.copyWith(
            localUri: Value(result.fileUri),
            size: Value(result.fileSize),
            updatedAt: DateTime.now(),
          ),
        );
        await _enqueueSync?.call(
          SyncEntityType.video,
          mediaId,
          SyncAction.update,
        );
        return;
      }

      final audio = await _db.audioDao.getById(mediaId);
      if (audio != null) {
        final hash = audio.md5;
        if (hash == null || hash.isEmpty) {
          throw const FileFailure(
            'Cannot locate file: this item has no content fingerprint.',
          );
        }
        final result = await _storage.importPickedFileExpectingHash(
          picked,
          expectedHashHex: hash,
        );
        await _db.audioDao.insertRow(
          audio.copyWith(
            localUri: Value(result.fileUri),
            size: Value(result.fileSize),
            updatedAt: DateTime.now(),
          ),
        );
        await _enqueueSync?.call(
          SyncEntityType.audio,
          mediaId,
          SyncAction.update,
        );
        return;
      }

      throw const FileFailure('Media not found.');
    } on AppFailure {
      rethrow;
    } catch (e, st) {
      Error.throwWithStackTrace(FileFailure('Relocate failed: $e'), st);
    }
  }
}

/// Element-wise comparison of two media lists without allocating. Avoids
/// pulling in `package:collection`'s `ListEquality` for one call site.
bool _listEqualsMedia(List<Media> a, List<Media> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
