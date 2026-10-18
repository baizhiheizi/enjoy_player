part of 'vocabulary_review_session.dart';

/// Per-card context paging.
mixin VocabularyReviewSessionContext
    on VocabularyReviewSessionBase, VocabularyReviewSessionLifecycle {
  /// Selects the active context index for the current item (clamped; no wrap).
  Future<void> selectContext(int index) async {
    final item = state.currentItem;
    if (item == null || state.completed) return;
    final list = state.contextsFor(item.id);
    if (list.isEmpty) return;
    final clamped = index.clamp(0, list.length - 1);
    if (state.practiceSheetOpen) {
      await clearPractice();
    }
    final indices = Map<String, int>.from(state.activeContextIndexByItemId);
    indices[item.id] = clamped;
    state = state.copyWith(
      activeContextIndexByItemId: indices,
      clearMediaError: true,
    );
  }

  Future<void> selectPreviousContext() async {
    final item = state.currentItem;
    if (item == null) return;
    final i = state.activeContextIndexFor(item.id);
    if (i <= 0) return;
    await selectContext(i - 1);
  }

  Future<void> selectNextContext() async {
    final item = state.currentItem;
    if (item == null) return;
    final list = state.contextsFor(item.id);
    final i = state.activeContextIndexFor(item.id);
    if (i >= list.length - 1) return;
    await selectContext(i + 1);
  }
}
