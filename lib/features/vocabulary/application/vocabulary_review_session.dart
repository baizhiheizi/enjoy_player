/// Ephemeral flashcard review session state for Vocabulary P1.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/features/vocabulary/application/vocabulary_providers.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_models.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_session_selection.dart';

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
    this.ratedStack = const [],
    this.history = const [],
    this.completed = false,
    this.primaryContextByItemId = const {},
  });

  final List<VocabularyItem> queue;
  final int index;
  final bool flipped;
  final bool ratingInFlight;
  final List<String> ratedStack;
  final List<ReviewHistoryEntry> history;
  final bool completed;
  final Map<String, String> primaryContextByItemId;

  bool get hasActiveSession => queue.isNotEmpty;

  bool get canUndo => ratedStack.isNotEmpty && !ratingInFlight;

  VocabularyItem? get currentItem {
    if (completed || index < 0 || index >= queue.length) return null;
    return queue[index];
  }

  int get total => queue.length;

  int get displayCurrent => completed ? total : (index + 1).clamp(1, total);

  String? primaryContextFor(String itemId) => primaryContextByItemId[itemId];

  ReviewSessionState copyWith({
    List<VocabularyItem>? queue,
    int? index,
    bool? flipped,
    bool? ratingInFlight,
    List<String>? ratedStack,
    List<ReviewHistoryEntry>? history,
    bool? completed,
    Map<String, String>? primaryContextByItemId,
  }) {
    return ReviewSessionState(
      queue: queue ?? this.queue,
      index: index ?? this.index,
      flipped: flipped ?? this.flipped,
      ratingInFlight: ratingInFlight ?? this.ratingInFlight,
      ratedStack: ratedStack ?? this.ratedStack,
      history: history ?? this.history,
      completed: completed ?? this.completed,
      primaryContextByItemId:
          primaryContextByItemId ?? this.primaryContextByItemId,
    );
  }
}

final vocabularyReviewSessionProvider =
    NotifierProvider<VocabularyReviewSession, ReviewSessionState>(
      VocabularyReviewSession.new,
    );

class VocabularyReviewSession extends Notifier<ReviewSessionState> {
  @override
  ReviewSessionState build() => const ReviewSessionState(queue: []);

  /// Start a session from [options] against current book items.
  ///
  /// Returns `false` when the built queue is empty (caller shows a message).
  Future<bool> start(ReviewSelectionOptions options, {DateTime? now}) async {
    final repo = ref.read(vocabularyRepositoryProvider);
    final items = await repo.listAll();
    final queue = buildVocabularySessionQueue(
      items: items,
      options: options,
      now: now ?? DateTime.now(),
    );
    if (queue.isEmpty) {
      state = const ReviewSessionState(queue: []);
      return false;
    }

    final contexts = <String, String>{};
    for (final item in queue) {
      final list = await repo.getContextsForItem(item.id);
      if (list.isEmpty) continue;
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      contexts[item.id] = list.first.text;
    }

    state = ReviewSessionState(
      queue: List<VocabularyItem>.from(queue),
      primaryContextByItemId: contexts,
    );
    return true;
  }

  /// Restore a previously built non-empty queue (tests / deep links).
  void startWithQueue(
    List<VocabularyItem> queue, {
    Map<String, String> primaryContextByItemId = const {},
  }) {
    if (queue.isEmpty) {
      state = const ReviewSessionState(queue: []);
      return;
    }
    state = ReviewSessionState(
      queue: List<VocabularyItem>.from(queue),
      primaryContextByItemId: primaryContextByItemId,
    );
  }

  void clear() {
    state = const ReviewSessionState(queue: []);
  }

  void flip() {
    final item = state.currentItem;
    if (item == null || state.completed || state.ratingInFlight) return;
    state = state.copyWith(flipped: true);
  }

  Future<void> rate(VocabularyRating rating) async {
    final item = state.currentItem;
    if (item == null ||
        !state.flipped ||
        state.ratingInFlight ||
        state.completed) {
      return;
    }

    state = state.copyWith(ratingInFlight: true);
    try {
      final repo = ref.read(vocabularyRepositoryProvider);
      final updated = await repo.markReviewed(itemId: item.id, rating: rating);
      final queue = List<VocabularyItem>.from(state.queue);
      if (updated != null) {
        queue[state.index] = updated;
      }
      final ratedStack = [...state.ratedStack, item.id];
      final history = [
        ...state.history,
        ReviewHistoryEntry(itemId: item.id, wasRated: true),
      ];
      final nextIndex = state.index + 1;
      if (nextIndex >= queue.length) {
        state = state.copyWith(
          queue: queue,
          ratedStack: ratedStack,
          history: history,
          ratingInFlight: false,
          completed: true,
          flipped: false,
          index: queue.length,
        );
      } else {
        state = state.copyWith(
          queue: queue,
          index: nextIndex,
          flipped: false,
          ratingInFlight: false,
          ratedStack: ratedStack,
          history: history,
        );
      }
    } catch (_) {
      state = state.copyWith(ratingInFlight: false);
      rethrow;
    }
  }

  void skip() {
    final item = state.currentItem;
    if (item == null || state.ratingInFlight || state.completed) return;
    final history = [
      ...state.history,
      ReviewHistoryEntry(itemId: item.id, wasRated: false),
    ];
    final nextIndex = state.index + 1;
    if (nextIndex >= state.queue.length) {
      state = state.copyWith(
        history: history,
        completed: true,
        flipped: false,
        index: state.queue.length,
      );
    } else {
      state = state.copyWith(
        index: nextIndex,
        flipped: false,
        history: history,
      );
    }
  }

  Future<void> undo() async {
    if (!state.canUndo) return;
    final itemId = state.ratedStack.last;
    state = state.copyWith(ratingInFlight: true);
    try {
      final repo = ref.read(vocabularyRepositoryProvider);
      final restored = await repo.undoLatestReview(itemId);
      final queue = List<VocabularyItem>.from(state.queue);
      final idx = queue.indexWhere((i) => i.id == itemId);
      if (restored != null && idx >= 0) {
        queue[idx] = restored;
      }
      final ratedStack = List<String>.from(state.ratedStack)..removeLast();
      // Rewind history to this rated card.
      final history = List<ReviewHistoryEntry>.from(state.history);
      while (history.isNotEmpty) {
        final last = history.removeLast();
        if (last.itemId == itemId && last.wasRated) break;
      }
      final restoreIndex = idx >= 0 ? idx : state.index;
      state = state.copyWith(
        queue: queue,
        index: restoreIndex,
        flipped: false,
        ratingInFlight: false,
        ratedStack: ratedStack,
        history: history,
        completed: false,
      );
    } catch (_) {
      state = state.copyWith(ratingInFlight: false);
      rethrow;
    }
  }

  void previous() {
    if (state.history.isEmpty || state.ratingInFlight) return;
    final history = List<ReviewHistoryEntry>.from(state.history);
    final last = history.removeLast();
    final idx = state.queue.indexWhere((i) => i.id == last.itemId);
    if (idx < 0) {
      state = state.copyWith(history: history);
      return;
    }
    // Previous does not auto-undo ratings; undo is explicit.
    state = state.copyWith(
      history: history,
      index: idx,
      flipped: false,
      completed: false,
    );
  }
}
