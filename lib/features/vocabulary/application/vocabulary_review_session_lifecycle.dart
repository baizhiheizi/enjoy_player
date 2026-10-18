part of 'vocabulary_review_session.dart';

/// Session start, teardown, and practice-overlay teardown.
mixin VocabularyReviewSessionLifecycle on VocabularyReviewSessionBase {
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

    _clearRunTallies();

    final contextsByItemId = await repo.getContextsForItems(
      queue.map((item) => item.id),
    );
    final activeIndex = <String, int>{for (final item in queue) item.id: 0};

    state = ReviewSessionState(
      queue: List<VocabularyItem>.from(queue),
      contextsByItemId: contextsByItemId,
      activeContextIndexByItemId: activeIndex,
    );
    return true;
  }

  /// Restore a previously built non-empty queue (tests / deep links).
  void startWithQueue(
    List<VocabularyItem> queue, {
    Map<String, List<VocabularyContext>> contextsByItemId = const {},
    Map<String, int> activeContextIndexByItemId = const {},
    Map<String, VocabularyContext> primaryContextByItemId = const {},
  }) {
    if (queue.isEmpty) {
      state = const ReviewSessionState(queue: []);
      return;
    }

    var contexts = Map<String, List<VocabularyContext>>.from(contextsByItemId);
    var indices = Map<String, int>.from(activeContextIndexByItemId);
    if (contexts.isEmpty && primaryContextByItemId.isNotEmpty) {
      for (final e in primaryContextByItemId.entries) {
        contexts[e.key] = [e.value];
        indices[e.key] = 0;
      }
    }

    state = ReviewSessionState(
      queue: List<VocabularyItem>.from(queue),
      contextsByItemId: contexts,
      activeContextIndexByItemId: indices,
    );
  }

  void clear() {
    final hadPractice = state.practiceSheetOpen;
    _clearRunTallies();
    state = const ReviewSessionState(queue: []);
    if (hadPractice) {
      ref.read(echoModeProvider.notifier).deactivate();
      try {
        unawaited(
          ref.read(playerControllerProvider.notifier).activeEngine.pause(),
        );
      } catch (_) {}
    }
  }

  /// Pauses lesson media, clears the playback session, and closes practice UI.
  ///
  /// Does **not** clear the review queue — the flashcard stays mounted.
  Future<void> clearPractice() async {
    if (state.practicePhase == ReviewPracticePhase.none) return;
    final wasClip = state.practicePhase.isClip;
    if (_practiceOpenedAt != null) {
      final duration = DateTime.now().difference(_practiceOpenedAt!);
      _practiceOpenedAt = null;
      _analytics.capture(
        AnalyticsEvents.practiceSessionCompleted,
        properties: AnalyticsEvents.practiceCompleted(
          surface: AnalyticsEvents.surfaceFlashcard,
          durationSeconds: duration.inSeconds,
          itemsCompleted: 1,
        ),
      );
    }
    ref.read(echoModeProvider.notifier).deactivate();
    if (wasClip) {
      final player = ref.read(playerControllerProvider.notifier);
      final hasSession = ref.read(playerControllerProvider) != null;
      if (hasSession) {
        try {
          await player.activeEngine.pause();
        } catch (_) {}
        try {
          await player.clear(keepVideoSurface: true);
        } catch (_) {}
      }
    }
    if (!ref.mounted) return;
    state = state.copyWith(
      practicePhase: ReviewPracticePhase.none,
      clearMediaError: true,
    );
  }
}
