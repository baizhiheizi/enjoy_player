/// Import + relink policy for library media (oEmbed resolution, placeholder
/// detection, hashing, storage GC, delete/language transaction policy).
///
/// Reads and row writes cross the [MediaRegistry] seam directly — this module
/// no longer relays them (issue #765). The whole-library watch lives on the
/// registry (`MediaRegistry.watchAll`, issue #753).
library;

import 'dart:async';

import 'package:cross_file/cross_file.dart';

import 'package:enjoy_player/core/application/app_language_catalog.dart';
import 'package:enjoy_player/core/errors/app_failure.dart';
import 'package:enjoy_player/core/ids/enjoy_ids.dart';
import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/core/utils/youtube_video_identity.dart';
import 'package:logging/logging.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/media_registry.dart';
import 'package:enjoy_player/data/files/app_managed_media_gc.dart';
import 'package:enjoy_player/data/files/file_storage.dart';
import 'package:enjoy_player/data/files/media_duration_probe.dart';
import 'package:enjoy_player/data/files/media_resolver.dart';
import 'package:enjoy_player/features/library/domain/media.dart';
import 'package:enjoy_player/features/library/data/youtube_oembed_api.dart';
import 'package:enjoy_player/features/sync/domain/sync_types.dart';
import 'package:http/http.dart' as http;

typedef YoutubeMetadataPatch = ({String title, String? thumbnailUrl});

class MediaLibraryRepository {
  MediaLibraryRepository(
    AppDatabase db,
    this._storage, {
    this._enqueueSync,
    this._oembedClient,
  }) : _db = db,
       _registry = MediaRegistry(db);

  static final Logger _log = logNamed('library.repository');

  final AppDatabase _db;
  final FileStorage _storage;
  final SyncEnqueueFn? _enqueueSync;
  final http.Client? _oembedClient;

  /// The registry is `const`-constructible and stateless; one field replaces
  /// the per-call constructions this file used to spell (issue #765).
  final MediaRegistry _registry;

  /// Imports a local file into the signed-in user's library.
  Future<String> importMedia(
    XFile file, {
    required String signedInUserId,
    String contentLanguage = kUnknownMediaLanguageTag,
  }) async {
    try {
      if (!isImportableLocalMediaFileName(file.name)) {
        throw const UnsupportedImportFileFailure();
      }
      final result = await _storage.importOrLinkPickedFile(file);
      final kind = isVideoFileName(file.name)
          ? MediaKind.video
          : MediaKind.audio;
      final now = DateTime.now();
      final contentHash = result.contentHashHex;

      if (kind == MediaKind.video) {
        final vid = enjoyLocalVideoVid(
          contentHashHex: contentHash,
          userId: signedInUserId,
        );
        final id = enjoyVideoId(vid: vid);
        final existing = await _registry.getVideoById(id);
        await _registry.upsertVideo(
          VideoRow(
            id: id,
            vid: vid,
            provider: 'user',
            title: result.title,
            description: existing?.description,
            thumbnailUrl: existing?.thumbnailUrl,
            durationSeconds: existing?.durationSeconds ?? 0,
            language: canonicalMediaLanguageTag(contentLanguage),
            source: existing?.source,
            localUri: result.fileUri,
            bookmarkData: result.bookmarkData,
            md5: contentHash,
            size: result.fileSize,
            localMtimeMs: result.mtimeMs,
            mediaUrl: existing?.mediaUrl,
            syncStatus: 'pending',
            serverUpdatedAt: existing?.serverUpdatedAt,
            createdAt: existing?.createdAt ?? now,
            updatedAt: now,
          ),
        );
        return await _finalizeLocalImport(
          id: id,
          previousUri: existing?.localUri,
          fileUri: result.fileUri,
          entityType: MediaRegistry.syncEntityTypeOf(kind),
          isUpdate: existing != null,
        );
      }

      final aid = enjoyLocalAudioAid(
        contentHashHex: contentHash,
        userId: signedInUserId,
      );
      final id = enjoyAudioId(aid: aid);
      final existing = await _registry.getAudioById(id);
      await _registry.upsertAudio(
        AudioRow(
          id: id,
          aid: aid,
          provider: 'user',
          title: result.title,
          description: existing?.description,
          thumbnailUrl: existing?.thumbnailUrl,
          durationSeconds: existing?.durationSeconds ?? 0,
          language: canonicalMediaLanguageTag(contentLanguage),
          translationKey: existing?.translationKey,
          sourceText: existing?.sourceText,
          voice: existing?.voice,
          source: existing?.source,
          localUri: result.fileUri,
          bookmarkData: result.bookmarkData,
          md5: contentHash,
          size: result.fileSize,
          localMtimeMs: result.mtimeMs,
          mediaUrl: existing?.mediaUrl,
          syncStatus: 'pending',
          serverUpdatedAt: existing?.serverUpdatedAt,
          createdAt: existing?.createdAt ?? now,
          updatedAt: now,
        ),
      );
      return await _finalizeLocalImport(
        id: id,
        previousUri: existing?.localUri,
        fileUri: result.fileUri,
        entityType: MediaRegistry.syncEntityTypeOf(kind),
        isUpdate: existing != null,
      );
    } on AppFailure {
      rethrow;
    } catch (e, st) {
      Error.throwWithStackTrace(FileFailure('Import failed: $e'), st);
    }
  }

  /// Imports a YouTube video by pasted URL or bare video id.
  Future<String> importYoutubeVideo(
    String rawInput, {
    String? prefetchedTitle,
    String? prefetchedThumbnailUrl,
    String contentLanguage = kUnknownMediaLanguageTag,
  }) async {
    final id = parseYoutubeVideoId(rawInput);
    if (id == null) {
      throw const FileFailure('Invalid YouTube URL or video ID.');
    }
    final dup = await _registry.getYoutubeVideoByVid(id);
    if (dup != null) {
      await _maybePatchYoutubeMetadata(
        dup,
        prefetchedTitle: prefetchedTitle,
        prefetchedThumbnailUrl: prefetchedThumbnailUrl,
      );
      // Resurface on Home even when metadata was already complete (re-add).
      await _registry.touchUpdatedAt(dup.id);
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

    final row = VideoRow(
      id: rowId,
      vid: id,
      provider: 'youtube',
      title: title,
      description: null,
      thumbnailUrl: thumb,
      durationSeconds: 0,
      language: canonicalMediaLanguageTag(contentLanguage),
      source: 'youtube',
      localUri: null,
      md5: null,
      size: null,
      mediaUrl: 'https://www.youtube.com/watch?v=$id',
      syncStatus: 'pending',
      serverUpdatedAt: null,
      createdAt: now,
      updatedAt: now,
    );
    await _registry.upsertVideo(row);
    await _enqueueSync?.call(SyncEntityType.video, rowId, SyncAction.create);
    return rowId;
  }

  /// Re-fetches oEmbed when title/thumbnail are still import placeholders.
  Future<YoutubeMetadataPatch?> refreshYoutubeMetadataIfNeeded(
    String mediaId,
  ) async {
    final row = await _registry.getVideoById(mediaId);
    if (row == null || row.provider.toLowerCase() != 'youtube') return null;
    if (!_youtubeMetadataNeedsRefresh(row)) return null;

    final meta = await fetchYoutubeOembed(row.vid, client: _oembedClient);
    if (meta == null) return null;

    final title = meta.title;
    final thumb = meta.thumbnailUrl ?? row.thumbnailUrl;
    await _registry.updateYoutubeMetadata(
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
    await _registry.updateYoutubeMetadata(
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

  /// Bumps library-row [updatedAt] so Home "Recent media" ranks recently opened
  /// items without enqueueing a cloud sync update.
  ///
  /// Failures are swallowed (logged) so fire-and-forget callers from
  /// [PlayerController.openMedia] cannot fail tests or tear-down when the DB
  /// is already closed.
  Future<void> touchMediaUpdatedAt(String mediaId) async {
    try {
      await _registry.touchUpdatedAt(mediaId);
    } on Object catch (e, st) {
      _log.warning('touchMediaUpdatedAt failed for $mediaId', e, st);
    }
  }

  Future<void> deleteMedia(String id) async {
    // Atomic: enqueue the sync row inside the same transaction as the
    // local delete. If the local delete fails, the sync enqueue is
    // rolled back and the user can retry; previously, a sync row
    // could be left pointing at a media id that no longer exists
    // locally when the local delete threw between the two calls.
    // Registry dispatch (video-first probe + which table to delete) runs
    // inside the same zone, so it joins the transaction.
    String? localUri;
    await _db.transaction(() async {
      localUri = await _registry.localUriOf(id);
      final kind = await _registry.deleteById(id);
      if (kind != null) {
        await _enqueueSync?.call(
          MediaRegistry.syncEntityTypeOf(kind),
          id,
          SyncAction.delete,
        );
      }
    });
    await _maybeDeleteAppManagedMedia(localUri);
  }

  Future<void> _maybeDeleteAppManagedMedia(String? fileUri) {
    return deleteAppManagedMediaIfUnreferenced(
      db: _db,
      storage: _storage,
      fileUri: fileUri,
    );
  }

  /// Updates content language on an existing audio or video row.
  Future<void> updateMediaLanguage(String id, String language) async {
    final canonical = canonicalMediaLanguageTag(language);
    // Canonicalization, the same-tag short-circuit (skip the write, the
    // fetch-state clear, and the sync enqueue), and the transcript
    // fetch-state clear are repo-layer policy — the registry only owns the
    // videos/audios write dispatch.
    final hit = await _registry.probeBoth(id);
    final current = hit.video?.language ?? hit.audio?.language;
    if (hit.video == null && hit.audio == null) {
      throw const FileFailure('Media not found.');
    }
    if (tagsEqual(current!, canonical)) return;
    final kind = await _registry.updateLanguage(id, canonical);
    if (kind == null) throw const FileFailure('Media not found.');
    if (kind == MediaKind.video) {
      await _db.transcriptFetchStateDao.clearForTarget('video', id);
    }
    await _enqueueSync?.call(
      MediaRegistry.syncEntityTypeOf(kind),
      id,
      SyncAction.update,
    );
  }

  /// Link or copy a user-picked file when its chunked SHA-256 matches the
  /// row's `md5` field, then set [localUri] for playback on this device.
  Future<void> relocateLocalFile({
    required String mediaId,
    required XFile picked,
  }) async {
    try {
      final hit = await _registry.probeBoth(mediaId);
      final video = hit.video;
      final audio = hit.audio;
      if (video == null && audio == null) {
        throw const FileFailure('Media not found.');
      }
      final kind = video != null ? MediaKind.video : MediaKind.audio;
      await _relocateLinkedFile(
        mediaId: mediaId,
        md5: video?.md5 ?? audio?.md5,
        previousUri: video?.localUri ?? audio?.localUri,
        kind: kind,
        picked: picked,
        // Relocate persist (all four fields, nulls clearing stale trust
        // metadata) lives on the registry — same write as before.
        // Wrapped in an async block so the callback's declared
        // `Future<void>` signature cleanly discards the
        // `Future<MediaKind?>` returned by the registry write.
        persist: (result) async {
          await _registry.updateLocalFile(
            mediaId,
            localUri: result.fileUri,
            bookmarkData: result.bookmarkData,
            size: result.fileSize,
            mtimeMs: result.mtimeMs,
          );
        },
      );
    } on AppFailure {
      rethrow;
    } catch (e, st) {
      Error.throwWithStackTrace(FileFailure('Relocate failed: $e'), st);
    }
  }

  Future<String> _finalizeLocalImport({
    required String id,
    required String? previousUri,
    required String fileUri,
    required SyncEntityType entityType,
    required bool isUpdate,
  }) async {
    if (previousUri != null && previousUri != fileUri) {
      await _maybeDeleteAppManagedMedia(previousUri);
    }
    unawaited(probeAndPatchMediaDuration(_db, id, fileUri));
    await _enqueueSync?.call(
      entityType,
      id,
      isUpdate ? SyncAction.update : SyncAction.create,
    );
    return id;
  }

  Future<void> _relocateLinkedFile({
    required String mediaId,
    required String? md5,
    required String? previousUri,
    required MediaKind kind,
    required XFile picked,
    required Future<void> Function(FileImportResult result) persist,
  }) async {
    final hash = md5;
    if (hash == null || hash.isEmpty) {
      throw const FileFailure(
        'Cannot locate file: this item has no content fingerprint.',
      );
    }
    final result = await _storage.importOrLinkPickedFile(
      picked,
      expectedHashHex: hash,
    );
    await persist(result);
    if (previousUri != null && previousUri != result.fileUri) {
      await _maybeDeleteAppManagedMedia(previousUri);
    }
    await _enqueueSync?.call(
      MediaRegistry.syncEntityTypeOf(kind),
      mediaId,
      SyncAction.update,
    );
  }
}
