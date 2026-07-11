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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaybackSession &&
          other.mediaId == mediaId &&
          other.dexieTargetType == dexieTargetType &&
          other.mediaType == mediaType &&
          other.mediaTitle == mediaTitle &&
          other.thumbnailUrl == thumbnailUrl &&
          other.durationSeconds == durationSeconds &&
          other.currentTimeSeconds == currentTimeSeconds &&
          other.currentSegmentIndex == currentSegmentIndex &&
          other.language == language &&
          other.startedAt == startedAt &&
          other.transcriptId == transcriptId;

  @override
  int get hashCode => Object.hash(
    mediaId,
    dexieTargetType,
    mediaType,
    mediaTitle,
    thumbnailUrl,
    durationSeconds,
    currentTimeSeconds,
    currentSegmentIndex,
    language,
    startedAt,
    transcriptId,
  );
}

/// Stable subset for navigation chrome and artwork — excludes clock fields so UI
/// does not rebuild on every position tick ([PlaybackSession.currentTimeSeconds]).
typedef PlaybackChrome = ({
  String mediaId,
  String dexieTargetType,
  String mediaType,
  String mediaTitle,
  String? thumbnailUrl,
  double durationSeconds,
  String language,
});

PlaybackChrome? playbackChromeOf(PlaybackSession? session) {
  if (session == null) return null;
  return (
    mediaId: session.mediaId,
    dexieTargetType: session.dexieTargetType,
    mediaType: session.mediaType,
    mediaTitle: session.mediaTitle,
    thumbnailUrl: session.thumbnailUrl,
    durationSeconds: session.durationSeconds,
    language: session.language,
  );
}
