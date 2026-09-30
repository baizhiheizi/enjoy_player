/// Shared select-only library projection for the `videos` / `audios` DAOs
/// (issue #810 D6, review on #815).
///
/// The two tables expose the same SQL column names for everything
/// [MediaLibraryRow] carries — only the content-hash column differs
/// (`videos.vid` vs `audios.aid`). The column list and the row mapping
/// therefore live here exactly once; each DAO supplies its table plus the one
/// column whose Dart getter name differs. Names resolve through Drift's
/// `TableInfo.columnsByName` at first use, so a column renamed on one table
/// fails loudly here (missing-key cast) instead of silently diverging between
/// the two DAOs.
library;

import 'package:drift/drift.dart';

import 'media_library_row.dart';

mixin MediaLibraryProjection<DB extends GeneratedDatabase>
    on DatabaseAccessor<DB> {
  /// Table projected by [watchAll] / [watchRecentByUpdatedAt].
  TableInfo<Table, dynamic> get mediaLibraryTable;

  /// Content-hash column of [mediaLibraryTable] (`vid` / `aid`).
  GeneratedColumn<String> get mediaLibraryContentHash;

  late final _ProjectedLibraryColumns _projected =
      _ProjectedLibraryColumns.resolve(
        mediaLibraryTable,
        mediaLibraryContentHash,
      );

  /// Library-wide watch projecting only the columns [MediaLibraryRow] needs
  /// (`createdAt`-descending; issue #810 D6 — skips `description` and
  /// `bookmarkData` blobs).
  Stream<List<MediaLibraryRow>> watchAll() {
    return (selectOnly(mediaLibraryTable)
          ..addColumns(_projected.all)
          ..orderBy([OrderingTerm.desc(_projected.createdAt)]))
        .map(_libraryRow)
        .watch();
  }

  /// Up to [limit] rows with the newest `updated_at` first (`updated_at DESC,
  /// created_at DESC` tiebreak), for the Home recents query (issue #810 D6).
  Stream<List<MediaLibraryRow>> watchRecentByUpdatedAt(int limit) {
    return (selectOnly(mediaLibraryTable)
          ..addColumns(_projected.all)
          ..orderBy([
            OrderingTerm.desc(_projected.updatedAt),
            OrderingTerm.desc(_projected.createdAt),
          ])
          ..limit(limit))
        .map(_libraryRow)
        .watch();
  }

  MediaLibraryRow _libraryRow(TypedResult r) => MediaLibraryRow(
    id: r.read(_projected.id)!,
    title: r.read(_projected.title)!,
    localUri: r.read(_projected.localUri),
    mediaUrl: r.read(_projected.mediaUrl),
    thumbnailUrl: r.read(_projected.thumbnailUrl),
    durationSeconds: r.read(_projected.durationSeconds)!,
    language: r.read(_projected.language)!,
    contentHash: r.read(_projected.contentHash)!,
    size: r.read(_projected.size),
    source: r.read(_projected.source),
    provider: r.read(_projected.provider)!,
    syncStatus: r.read(_projected.syncStatus),
    createdAt: r.read(_projected.createdAt)!,
    updatedAt: r.read(_projected.updatedAt)!,
  );
}

final class _ProjectedLibraryColumns {
  const _ProjectedLibraryColumns({
    required this.id,
    required this.title,
    required this.localUri,
    required this.mediaUrl,
    required this.thumbnailUrl,
    required this.durationSeconds,
    required this.language,
    required this.contentHash,
    required this.size,
    required this.source,
    required this.provider,
    required this.syncStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  factory _ProjectedLibraryColumns.resolve(
    TableInfo<Table, dynamic> table,
    GeneratedColumn<String> contentHash,
  ) {
    GeneratedColumn<T> column<T extends Object>(String name) =>
        table.columnsByName[name]! as GeneratedColumn<T>;
    return _ProjectedLibraryColumns(
      id: column<String>('id'),
      title: column<String>('title'),
      localUri: column<String>('local_uri'),
      mediaUrl: column<String>('media_url'),
      thumbnailUrl: column<String>('thumbnail_url'),
      durationSeconds: column<int>('duration_seconds'),
      language: column<String>('language'),
      contentHash: contentHash,
      size: column<int>('size'),
      source: column<String>('source'),
      provider: column<String>('provider'),
      syncStatus: column<String>('sync_status'),
      createdAt: column<DateTime>('created_at'),
      updatedAt: column<DateTime>('updated_at'),
    );
  }

  final GeneratedColumn<String> id;
  final GeneratedColumn<String> title;
  final GeneratedColumn<String> localUri;
  final GeneratedColumn<String> mediaUrl;
  final GeneratedColumn<String> thumbnailUrl;
  final GeneratedColumn<int> durationSeconds;
  final GeneratedColumn<String> language;
  final GeneratedColumn<String> contentHash;
  final GeneratedColumn<int> size;
  final GeneratedColumn<String> source;
  final GeneratedColumn<String> provider;
  final GeneratedColumn<String> syncStatus;
  final GeneratedColumn<DateTime> createdAt;
  final GeneratedColumn<DateTime> updatedAt;

  List<GeneratedColumn<Object>> get all => [
    id,
    title,
    localUri,
    mediaUrl,
    thumbnailUrl,
    durationSeconds,
    language,
    contentHash,
    size,
    source,
    provider,
    syncStatus,
    createdAt,
    updatedAt,
  ];
}
