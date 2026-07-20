/// Types for offline-first cloud sync (audio / video / recording metadata).
library;

/// Matches web `EntityType` subset implemented on Flutter.
enum SyncEntityType {
  audio,
  video,
  recording,
  youtubeSubscription,
  vocabularyItem,
  vocabularyContext,
}

extension SyncEntityTypeWire on SyncEntityType {
  String get wireName => switch (this) {
    SyncEntityType.audio => 'audio',
    SyncEntityType.video => 'video',
    SyncEntityType.recording => 'recording',
    SyncEntityType.youtubeSubscription => 'youtube_subscription',
    SyncEntityType.vocabularyItem => 'vocabulary_item',
    SyncEntityType.vocabularyContext => 'vocabulary_context',
  };

  static SyncEntityType? tryParse(String raw) => switch (raw) {
    'audio' => SyncEntityType.audio,
    'video' => SyncEntityType.video,
    'recording' => SyncEntityType.recording,
    'youtube_subscription' => SyncEntityType.youtubeSubscription,
    'vocabulary_item' => SyncEntityType.vocabularyItem,
    'vocabulary_context' => SyncEntityType.vocabularyContext,
    _ => null,
  };
}

/// Callback stored on [MediaLibraryRepository] to enqueue cloud sync work.
typedef SyncEnqueueFn =
    Future<void> Function(SyncEntityType type, String id, SyncAction action);

/// Matches web `SyncAction`.
enum SyncAction { create, update, delete }

extension SyncActionWire on SyncAction {
  String get wireName => switch (this) {
    SyncAction.create => 'create',
    SyncAction.update => 'update',
    SyncAction.delete => 'delete',
  };

  static SyncAction? tryParse(String raw) => switch (raw) {
    'create' => SyncAction.create,
    'update' => SyncAction.update,
    'delete' => SyncAction.delete,
    _ => null,
  };
}

final class SyncOptions {
  const SyncOptions({this.resetFailed = false});

  /// When true, resets permanently failed queue rows before processing.
  final bool resetFailed;
}

final class SyncResult {
  const SyncResult({
    required this.success,
    required this.synced,
    required this.failed,
    this.errors,
  });

  final bool success;
  final int synced;
  final int failed;
  final List<String>? errors;

  SyncResult merge(SyncResult other) => SyncResult(
    success: success && other.success,
    synced: synced + other.synced,
    failed: failed + other.failed,
    errors: [...?errors, ...?other.errors],
  );
}
