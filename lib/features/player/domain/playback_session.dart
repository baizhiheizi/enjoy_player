/// In-memory playback session (maps web `PlaybackSession` / echo session slice).
library;

class PlaybackSession {
  const PlaybackSession({
    required this.mediaId,
    required this.dexieTargetType,
    required this.mediaType,
    required this.mediaTitle,
    this.thumbnailUrl,
    required this.durationSeconds,
    required this.currentTimeSeconds,
    required this.currentSegmentIndex,
    required this.language,
    required this.startedAt,
    required this.lastActiveAt,
    this.transcriptId,
  });

  final String mediaId;
  /// Weapp `TargetType` for the open media (`Video` | `Audio`).
  final String dexieTargetType;
  final String mediaType;
  final String mediaTitle;
  final String? thumbnailUrl;
  final double durationSeconds;
  final double currentTimeSeconds;
  final int currentSegmentIndex;
  final String language;
  final DateTime startedAt;
  final DateTime lastActiveAt;
  final String? transcriptId;

  PlaybackSession copyWith({
    String? mediaId,
    String? dexieTargetType,
    String? mediaType,
    String? mediaTitle,
    String? thumbnailUrl,
    double? durationSeconds,
    double? currentTimeSeconds,
    int? currentSegmentIndex,
    String? language,
    DateTime? startedAt,
    DateTime? lastActiveAt,
    String? transcriptId,
  }) {
    return PlaybackSession(
      mediaId: mediaId ?? this.mediaId,
      dexieTargetType: dexieTargetType ?? this.dexieTargetType,
      mediaType: mediaType ?? this.mediaType,
      mediaTitle: mediaTitle ?? this.mediaTitle,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      currentTimeSeconds: currentTimeSeconds ?? this.currentTimeSeconds,
      currentSegmentIndex: currentSegmentIndex ?? this.currentSegmentIndex,
      language: language ?? this.language,
      startedAt: startedAt ?? this.startedAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      transcriptId: transcriptId ?? this.transcriptId,
    );
  }
}
