/// SRS-preserving conflict resolution for vocabulary items.
///
/// Ports Enjoy web `resolveVocabularyItemConflict`
/// (`apps/web/src/db/services/sync-utils.ts`): plain last-write-wins on
/// `updatedAt` would let a stale metadata edit on one device clobber newer
/// spaced-repetition progress made on another. Instead, whichever side has
/// the freshest SRS activity keeps its SRS fields; the other side's word /
/// explanation metadata is adopted only if it is textually newer than that
/// SRS activity. See ADR-0054 and
/// `specs/024-vocabulary-sync-anki/research.md` §6.
library;

/// Minimal item shape needed to resolve a conflict — decoupled from Drift
/// rows / JSON so tests can port web fixtures directly.
final class VocabularyItemConflictSide {
  const VocabularyItemConflictSide({
    required this.word,
    required this.status,
    required this.easeFactor,
    required this.interval,
    required this.nextReviewAt,
    required this.reviewsCount,
    this.lastReviewedAt,
    this.explanation,
    required this.contextsCount,
    required this.updatedAt,
  });

  final String word;
  final String status;
  final double easeFactor;
  final int interval;
  final DateTime nextReviewAt;
  final int reviewsCount;
  final DateTime? lastReviewedAt;
  final String? explanation;
  final int contextsCount;
  final DateTime updatedAt;
}

/// Resolved item state to persist locally after merging [local] and [server].
final class VocabularyItemConflictResult {
  const VocabularyItemConflictResult({
    required this.word,
    required this.status,
    required this.easeFactor,
    required this.interval,
    required this.nextReviewAt,
    required this.reviewsCount,
    this.lastReviewedAt,
    this.explanation,
    required this.contextsCount,
    required this.updatedAt,
    required this.serverUpdatedAt,
    required this.keptLocalSrs,
  });

  final String word;
  final String status;
  final double easeFactor;
  final int interval;
  final DateTime nextReviewAt;
  final int reviewsCount;
  final DateTime? lastReviewedAt;
  final String? explanation;
  final int contextsCount;
  final DateTime updatedAt;
  final DateTime serverUpdatedAt;

  /// Whether the merge kept the local side's SRS fields (`true`) or adopted
  /// the server's SRS state wholesale (`false`).
  final bool keptLocalSrs;
}

/// Whether the local side's spaced-repetition activity is fresher than the
/// server side's, per web `resolveVocabularyItemConflict`:
///
/// - If both sides have reviewed the word, later `lastReviewedAt` wins.
/// - If only one side has ever reviewed the word, that side wins.
/// - If neither side has reviewed the word, the higher `reviewsCount` wins
///   (covers imported/seeded rows without a review timestamp).
bool localVocabularySrsIsNewer({
  required DateTime? localLastReviewedAt,
  required DateTime? serverLastReviewedAt,
  required int localReviewsCount,
  required int serverReviewsCount,
}) {
  if (localLastReviewedAt != null && serverLastReviewedAt != null) {
    return localLastReviewedAt.isAfter(serverLastReviewedAt);
  }
  if (localLastReviewedAt != null) return true;
  if (serverLastReviewedAt != null) return false;
  return localReviewsCount > serverReviewsCount;
}

/// Merges [local] and [server] item state.
///
/// When local SRS is newer, local SRS fields are kept and the server's
/// `word` / `explanation` are adopted only if `server.updatedAt` is newer
/// than the local SRS reference (`lastReviewedAt` if set, else
/// `local.updatedAt`) — otherwise the server side is preferred wholesale.
VocabularyItemConflictResult resolveVocabularyItemConflict({
  required VocabularyItemConflictSide local,
  required VocabularyItemConflictSide server,
}) {
  final localSrsNewer = localVocabularySrsIsNewer(
    localLastReviewedAt: local.lastReviewedAt,
    serverLastReviewedAt: server.lastReviewedAt,
    localReviewsCount: local.reviewsCount,
    serverReviewsCount: server.reviewsCount,
  );

  if (!localSrsNewer) {
    return VocabularyItemConflictResult(
      word: server.word,
      status: server.status,
      easeFactor: server.easeFactor,
      interval: server.interval,
      nextReviewAt: server.nextReviewAt,
      reviewsCount: server.reviewsCount,
      lastReviewedAt: server.lastReviewedAt,
      explanation: server.explanation,
      contextsCount: server.contextsCount,
      updatedAt: server.updatedAt,
      serverUpdatedAt: server.updatedAt,
      keptLocalSrs: false,
    );
  }

  final localSrsReference = local.lastReviewedAt ?? local.updatedAt;
  final adoptServerMetadata = server.updatedAt.isAfter(localSrsReference);

  return VocabularyItemConflictResult(
    word: adoptServerMetadata ? server.word : local.word,
    status: local.status,
    easeFactor: local.easeFactor,
    interval: local.interval,
    nextReviewAt: local.nextReviewAt,
    reviewsCount: local.reviewsCount,
    lastReviewedAt: local.lastReviewedAt,
    explanation: adoptServerMetadata ? server.explanation : local.explanation,
    contextsCount: local.contextsCount,
    updatedAt: local.updatedAt,
    serverUpdatedAt: local.updatedAt,
    keptLocalSrs: true,
  );
}
