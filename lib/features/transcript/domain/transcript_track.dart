/// UI-facing subtitle track metadata (decoupled from persistence rows).
library;

class TranscriptTrack {
  const TranscriptTrack({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.language,
    required this.source,
    required this.label,
    this.trackIndex,
  });

  final String id;

  /// Dexie `TargetType` (`Video` | `Audio` | …).
  final String targetType;
  final String targetId;
  final String language;
  final String source;
  final String label;
  final int? trackIndex;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TranscriptTrack &&
          other.id == id &&
          other.targetType == targetType &&
          other.targetId == targetId &&
          other.language == language &&
          other.source == source &&
          other.label == label &&
          other.trackIndex == trackIndex;

  @override
  int get hashCode => Object.hash(
    id,
    targetType,
    targetId,
    language,
    source,
    label,
    trackIndex,
  );
}
