/// Value objects for an active Vocabulary review run.
library;

import 'package:enjoy_player/features/vocabulary/domain/vocabulary_models.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_review_practice.dart';

/// One step in the session navigation history (for ← previous).
final class ReviewHistoryEntry {
  const ReviewHistoryEntry({required this.itemId, required this.wasRated});

  final String itemId;
  final bool wasRated;
}

/// Mutable UI state for an active review run.
final class ReviewSessionState {
  const ReviewSessionState({
    required this.queue,
    this.index = 0,
    this.flipped = false,
    this.ratingInFlight = false,
    this.dictionaryFetchInFlight = false,
    this.contextualFetchInFlight = false,
    this.dictionaryError,
    this.contextualError,
    this.mediaError,
    this.ratedStack = const [],
    this.history = const [],
    this.completed = false,
    this.contextsByItemId = const {},
    this.activeContextIndexByItemId = const {},
    this.practicePhase = ReviewPracticePhase.none,
  });

  final List<VocabularyItem> queue;
  final int index;
  final bool flipped;
  final bool ratingInFlight;
  final bool dictionaryFetchInFlight;
  final bool contextualFetchInFlight;
  final String? dictionaryError;
  final String? contextualError;
  final String? mediaError;
  final List<String> ratedStack;
  final List<ReviewHistoryEntry> history;
  final bool completed;
  final Map<String, List<VocabularyContext>> contextsByItemId;
  final Map<String, int> activeContextIndexByItemId;
  final ReviewPracticePhase practicePhase;

  bool get hasActiveSession => queue.isNotEmpty;

  bool get canUndo => ratedStack.isNotEmpty && !ratingInFlight;

  ReviewPracticeMode get practiceMode => practicePhase.asMode;

  bool get practiceSheetOpen => practicePhase.overlayOpen;

  /// True while clip practice is open (suppress mini-bar).
  bool get practiceOwnsVideoStage => practicePhase.isClip;

  bool get clipPlayInFlight => practicePhase == ReviewPracticePhase.clipOpening;

  bool get claimsVideoSurface => practicePhase.claimsVideoSurface;

  VocabularyItem? get currentItem {
    if (completed || index < 0 || index >= queue.length) return null;
    return queue[index];
  }

  /// Active context for the current card (earliest by default; pager may change).
  VocabularyContext? get currentPrimaryContext {
    final item = currentItem;
    if (item == null) return null;
    return primaryContextFor(item.id);
  }

  List<VocabularyContext> contextsFor(String itemId) =>
      contextsByItemId[itemId] ?? const [];

  int activeContextIndexFor(String itemId) {
    final list = contextsFor(itemId);
    if (list.isEmpty) return 0;
    final raw = activeContextIndexByItemId[itemId] ?? 0;
    if (raw < 0) return 0;
    if (raw >= list.length) return list.length - 1;
    return raw;
  }

  int get currentContextsCount {
    final item = currentItem;
    if (item == null) return 0;
    return contextsFor(item.id).length;
  }

  int get currentActiveContextIndex {
    final item = currentItem;
    if (item == null) return 0;
    return activeContextIndexFor(item.id);
  }

  int get total => queue.length;

  int get displayCurrent => completed ? total : (index + 1).clamp(1, total);

  /// Cards left after the current one (0 when complete or on the last card).
  int get remaining => completed ? 0 : (total - displayCurrent).clamp(0, total);

  VocabularyContext? primaryContextFor(String itemId) {
    final list = contextsFor(itemId);
    if (list.isEmpty) return null;
    return list[activeContextIndexFor(itemId)];
  }

  ReviewSessionState copyWith({
    List<VocabularyItem>? queue,
    int? index,
    bool? flipped,
    bool? ratingInFlight,
    bool? dictionaryFetchInFlight,
    bool? contextualFetchInFlight,
    String? dictionaryError,
    bool clearDictionaryError = false,
    String? contextualError,
    bool clearContextualError = false,
    String? mediaError,
    bool clearMediaError = false,
    List<String>? ratedStack,
    List<ReviewHistoryEntry>? history,
    bool? completed,
    Map<String, List<VocabularyContext>>? contextsByItemId,
    Map<String, int>? activeContextIndexByItemId,
    ReviewPracticePhase? practicePhase,
  }) {
    return ReviewSessionState(
      queue: queue ?? this.queue,
      index: index ?? this.index,
      flipped: flipped ?? this.flipped,
      ratingInFlight: ratingInFlight ?? this.ratingInFlight,
      dictionaryFetchInFlight:
          dictionaryFetchInFlight ?? this.dictionaryFetchInFlight,
      contextualFetchInFlight:
          contextualFetchInFlight ?? this.contextualFetchInFlight,
      dictionaryError: clearDictionaryError
          ? null
          : (dictionaryError ?? this.dictionaryError),
      contextualError: clearContextualError
          ? null
          : (contextualError ?? this.contextualError),
      mediaError: clearMediaError ? null : (mediaError ?? this.mediaError),
      ratedStack: ratedStack ?? this.ratedStack,
      history: history ?? this.history,
      completed: completed ?? this.completed,
      contextsByItemId: contextsByItemId ?? this.contextsByItemId,
      activeContextIndexByItemId:
          activeContextIndexByItemId ?? this.activeContextIndexByItemId,
      practicePhase: practicePhase ?? this.practicePhase,
    );
  }
}
