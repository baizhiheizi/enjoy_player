part of 'vocabulary_review_session.dart';

/// Clip / echo practice overlay state machine.
mixin VocabularyReviewSessionPractice
    on VocabularyReviewSessionBase, VocabularyReviewSessionLifecycle {
  /// Shows clip practice overlay in the opening phase (no surface claim yet).
  void preparePracticeClip() {
    final ctx = state.currentPrimaryContext;
    if (ctx == null ||
        state.clipPlayInFlight ||
        state.completed ||
        state.practicePhase.isClip ||
        !vocabularyContextSupportsMediaActions(ctx)) {
      return;
    }
    state = state.copyWith(
      practicePhase: ReviewPracticePhase.clipOpening,
      clearMediaError: true,
    );
  }

  /// Opens media on the permanent surface, seeks the clip window, then plays.
  Future<void> startPracticeClipPlayback() async {
    final ctx = state.currentPrimaryContext;
    if (ctx == null ||
        state.completed ||
        state.practicePhase != ReviewPracticePhase.clipOpening ||
        !vocabularyContextSupportsMediaActions(ctx)) {
      return;
    }
    try {
      await playVocabularyClip(
        player: ref.read(playerControllerProvider.notifier),
        echo: ref.read(echoModeProvider.notifier),
        context: ctx,
      );
      if (ref.mounted &&
          state.practicePhase == ReviewPracticePhase.clipOpening) {
        state = state.copyWith(practicePhase: ReviewPracticePhase.clipReady);
      }
    } catch (e, st) {
      _log.warning('Clip play failed', e, st);
      if (ref.mounted) {
        state = state.copyWith(
          practicePhase: ReviewPracticePhase.none,
          mediaError: 'play_failed',
        );
        try {
          await ref
              .read(playerControllerProvider.notifier)
              .clear(keepVideoSurface: true);
        } catch (_) {}
      }
    }
  }

  /// Opens clip practice (sets opening phase then plays).
  Future<void> openPracticeClip() async {
    _practiceOpenedAt = DateTime.now();
    _analytics.capture(
      AnalyticsEvents.practiceSessionStarted,
      properties: AnalyticsEvents.practiceStarted(
        surface: AnalyticsEvents.surfaceFlashcard,
        itemCount: 1,
      ),
    );
    preparePracticeClip();
    await startPracticeClipPlayback();
  }

  /// Opens echo practice as a recorder-only overlay (no player session).
  Future<void> openPracticeEcho() async {
    final ctx = state.currentPrimaryContext;
    if (ctx == null ||
        state.completed ||
        !vocabularyContextSupportsMediaActions(ctx)) {
      return;
    }
    if (state.practicePhase.isClip) {
      await clearPractice();
    }
    if (!ref.mounted) return;
    _practiceOpenedAt = DateTime.now();
    _analytics.capture(
      AnalyticsEvents.practiceSessionStarted,
      properties: AnalyticsEvents.practiceStarted(
        surface: AnalyticsEvents.surfaceFlashcard,
        itemCount: 1,
      ),
    );
    state = state.copyWith(
      practicePhase: ReviewPracticePhase.echo,
      clearMediaError: true,
    );
  }

  /// Test helper to simulate an open practice sheet without media APIs.
  @visibleForTesting
  void debugSetPracticeMode(ReviewPracticeMode mode) {
    state = state.copyWith(practicePhase: mode.toPhase());
  }

  /// Test helper for explicit practice phases.
  @visibleForTesting
  void debugSetPracticePhase(ReviewPracticePhase phase) {
    state = state.copyWith(practicePhase: phase);
  }
}
