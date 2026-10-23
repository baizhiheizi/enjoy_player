part of 'media_registry.dart';

mixin MediaRegistryStreams {
  AppDatabase get _db;

  /// The set of YouTube video ids (`videos.vid`) present in the library,
  /// re-emitted whenever the `videos` table changes.
  ///
  /// Exists so a caller that needs *membership* — "is this feed entry already
  /// imported?" — can watch one small stream instead of issuing a per-item
  /// `getYoutubeVideoByVid` probe (issue #764 candidate 6: the discover feed
  /// did the latter once per tile, per scroll). Videos only, so an audio-only
  /// library write does not rebuild the feed.
  ///
  /// The Drift `watch()` source is broadcast, so the returned stream is too:
  /// the discover feed joins this from both the merged timeline and a
  /// single-channel view, and those two can be subscribed at the same time
  /// (the timeline provider is keep-alive, so opening a channel does not
  /// tear it down). The plumbing — per-listener dedupe state, multi-listener
  /// support, error forwarding, upstream cancellation — lives on
  /// [StreamDistinctExt.distinctBy] so the registry stays aligned with the
  /// rest of the codebase (architecture review #794 candidate 6). The
  /// comparator is custom because `Set<String>` lacks value `==`.
  Stream<Set<String>> watchYoutubeVideoIds() {
    return _db.videoDao
        .watchContentIdsByProvider('youtube')
        .distinctBy(_setEquals);
  }

  /// The merged `videos` + `audios` library as one stream of [Media],
  /// `createdAt`-descending (issue #753).
  ///
  /// The DAO halves are `selectOnly` projections of the columns [Media]
  /// needs — `description` and `bookmarkData` blobs never cross the DAO
  /// boundary (issue #810 D6). Merge mechanics, dedupe, and per-listener
  /// semantics live on [_mergeLibraryRows].
  Stream<List<Media>> watchAll() {
    return _mergeLibraryRows(
      videosStream: _db.videoDao.watchAll(),
      audiosStream: _db.audioDao.watchAll(),
      merge: _mergeRowsByCreatedAtDesc,
      areEqual: _listEquals,
    );
  }

  /// Per-kind row counts across both library tables, without materializing
  /// rows. Every `videos` row is one `MediaKind.video`, every `audios` row one
  /// `MediaKind.audio`, so the tab headers' contract is unchanged.
  Stream<({int audio, int video})> watchKindCounts() {
    return combineLatest2(
      _db.videoDao.watchCount(),
      _db.audioDao.watchCount(),
      (int video, int audio) => (video: video, audio: audio),
    ).distinctBy((previous, current) => previous == current);
  }

  /// One kind's media, newest `updated_at` first, from its own table only.
  Stream<List<Media>> watchByKind(MediaKind kind) {
    final dao = kind == MediaKind.video ? _db.videoDao : _db.audioDao;
    return dao
        .watchByUpdatedAt()
        .map(
          (rows) => [
            for (final row in rows) mediaFromLibraryProjection(row, kind: kind),
          ],
        )
        .distinctBy(_listEquals);
  }

  /// Media rows for one `provider` value across both tables, newest first.
  Stream<List<Media>> watchByProvider(String provider) {
    return _mergeLibraryRows(
      videosStream: _db.videoDao.watchByProvider(provider),
      audiosStream: _db.audioDao.watchByProvider(provider),
      merge: _mergeRowsByUpdatedAtDesc,
      areEqual: _listEquals,
    );
  }

  /// Media rows for [ids] across both tables, newest first.
  Stream<List<Media>> watchByIds(Set<String> ids) {
    return _mergeLibraryRows(
      videosStream: _db.videoDao.watchByIds(ids),
      audiosStream: _db.audioDao.watchByIds(ids),
      merge: _mergeRowsByUpdatedAtDesc,
      areEqual: _listEquals,
    );
  }

  /// The [limit] most recently updated items across both tables as one
  /// stream of [Media], `updatedAt`-descending (issue #810 D6 — Home
  /// recents no longer sorts the full merged library in Dart).
  ///
  /// Each DAO pre-limits its half to [limit] rows (`updated_at DESC,
  /// created_at DESC` with the `idx_*_updated_at` indexes, migration 19);
  /// merging two top-N halves yields the global top-N because any row
  /// outside a table's own top-N is outside the global top-N too.
  Stream<List<Media>> watchRecentByUpdatedAt(int limit) {
    return _mergeLibraryRows(
      videosStream: _db.videoDao.watchRecentByUpdatedAt(limit),
      audiosStream: _db.audioDao.watchRecentByUpdatedAt(limit),
      merge: (videos, audios) =>
          _mergeRowsByUpdatedAtDesc(videos, audios).take(limit).toList(),
      areEqual: _listEquals,
    );
  }

  List<Media> _mergeRowsByCreatedAtDesc(
    List<MediaLibraryRow> videos,
    List<MediaLibraryRow> audios,
  ) {
    return _mappedRows(videos, audios)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<Media> _mergeRowsByUpdatedAtDesc(
    List<MediaLibraryRow> videos,
    List<MediaLibraryRow> audios,
  ) {
    return _mappedRows(videos, audios)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  List<Media> _mappedRows(
    List<MediaLibraryRow> videos,
    List<MediaLibraryRow> audios,
  ) {
    return <Media>[
      ...videos.map(
        (row) => mediaFromLibraryProjection(row, kind: MediaKind.video),
      ),
      ...audios.map(
        (row) => mediaFromLibraryProjection(row, kind: MediaKind.audio),
      ),
    ];
  }

  /// Merges the two table streams per listener.
  ///
  /// Dedupe, empty-first-emission, same-turn coalescing, and multi-subscription
  /// semantics are contract behaviors pinned by `media_registry_test.dart`; the
  /// rationale and tradeoffs live in `docs/features/library.md`.
  Stream<T> _mergeLibraryRows<T>({
    required Stream<List<MediaLibraryRow>> videosStream,
    required Stream<List<MediaLibraryRow>> audiosStream,
    required T Function(
      List<MediaLibraryRow> videos,
      List<MediaLibraryRow> audios,
    )
    merge,
    required bool Function(T previous, T current) areEqual,
  }) {
    return Stream<T>.multi((controller) {
      late StreamSubscription<List<MediaLibraryRow>> subV;
      late StreamSubscription<List<MediaLibraryRow>> subA;
      var videos = <MediaLibraryRow>[];
      var audios = <MediaLibraryRow>[];
      List<MediaLibraryRow>? lastVideos;
      List<MediaLibraryRow>? lastAudios;
      var emitScheduled = false;
      var closed = false;

      void emit() {
        if (closed) return;
        if (lastVideos != null &&
            _listEquals(lastVideos!, videos) &&
            _listEquals(lastAudios!, audios)) {
          return;
        }
        lastVideos = videos;
        lastAudios = audios;
        controller.add(merge(videos, audios));
      }

      void forwardError(Object error, StackTrace stackTrace) {
        if (closed) return;
        controller.addError(error, stackTrace);
      }

      void scheduleEmit() {
        if (emitScheduled) return;
        emitScheduled = true;
        scheduleMicrotask(() {
          emitScheduled = false;
          emit();
        });
      }

      subV = videosStream.listen((rows) {
        videos = rows;
        scheduleEmit();
      }, onError: forwardError);
      subA = audiosStream.listen((rows) {
        audios = rows;
        scheduleEmit();
      }, onError: forwardError);
      controller.onCancel = () {
        closed = true;
        unawaited(subV.cancel());
        unawaited(subA.cancel());
      };
    }, isBroadcast: true).distinctBy(areEqual);
  }
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

/// Set equality with `==` semantics, mirroring `flutter/foundation`'s
/// `setEquals`. Same Flutter-free rationale as [_listEquals] — `Set<String>`
/// falls back to identity `==`, which would re-emit on every fresh
/// allocation even when the contents match.
bool _setEquals(Set<String> a, Set<String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final value in a) {
    if (!b.contains(value)) return false;
  }
  return true;
}
