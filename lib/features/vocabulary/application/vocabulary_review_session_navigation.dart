part of 'vocabulary_review_session.dart';

/// Card-level navigation: flipping, rating, skipping, undoing, jumping back.
mixin VocabularyReviewSessionNavigation on VocabularyReviewSessionBase {
  void flip() {
    final item = state.currentItem;
    if (item == null ||
        state.completed ||
        state.ratingInFlight ||
        state.practiceSheetOpen) {
      return;
    }
    state = state.copyWith(flipped: true);
  }

  void unflip() {
    final item = state.currentItem;
    if (item == null ||
        state.completed ||
        state.ratingInFlight ||
        !state.flipped ||
        state.practiceSheetOpen) {
      return;
    }
    state = state.copyWith(flipped: false);
  }

  void toggleFlip() {
    if (state.flipped) {
      unflip();
    } else {
      flip();
    }
  }

  Future<void> rate(VocabularyRating rating) async {
    final item = state.currentItem;
    if (item == null ||
        !state.flipped ||
        state.ratingInFlight ||
        state.completed ||
        state.practiceSheetOpen) {
      return;
    }

    state = state.copyWith(ratingInFlight: true);
    try {
      final repo = ref.read(vocabularyRepositoryProvider);
      final updated = await repo.markReviewed(itemId: item.id, rating: rating);
      _ratings[item.id] = rating;
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
          practicePhase: ReviewPracticePhase.none,
        );
        _captureReviewCompleted();
      } else {
        state = state.copyWith(
          queue: queue,
          index: nextIndex,
          flipped: false,
          ratingInFlight: false,
          ratedStack: ratedStack,
          history: history,
          practicePhase: ReviewPracticePhase.none,
        );
      }
    } catch (_) {
      state = state.copyWith(ratingInFlight: false);
      rethrow;
    }
  }

  void skip() {
    final item = state.currentItem;
    if (item == null ||
        state.ratingInFlight ||
        state.completed ||
        state.practiceSheetOpen) {
      return;
    }
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
        practicePhase: ReviewPracticePhase.none,
      );
      _captureReviewCompleted();
    } else {
      state = state.copyWith(
        index: nextIndex,
        flipped: false,
        history: history,
        practicePhase: ReviewPracticePhase.none,
      );
    }
  }

  Future<void> undo() async {
    if (!state.canUndo || state.practiceSheetOpen) return;
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
      _ratings.remove(itemId);
      final ratedStack = List<String>.from(state.ratedStack)..removeLast();
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
    if (state.history.isEmpty ||
        state.ratingInFlight ||
        state.practiceSheetOpen) {
      return;
    }
    final history = List<ReviewHistoryEntry>.from(state.history);
    final last = history.removeLast();
    final idx = state.queue.indexWhere((i) => i.id == last.itemId);
    if (idx < 0) {
      state = state.copyWith(history: history);
      return;
    }
    state = state.copyWith(
      history: history,
      index: idx,
      flipped: false,
      completed: false,
      practicePhase: ReviewPracticePhase.none,
    );
  }
}
