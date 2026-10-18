/// Ephemeral flashcard review session state for Vocabulary.
///
/// Composition root for the review session notifier: shared run state lives
/// in [VocabularyReviewSessionBase]; one mixin per concern (lifecycle,
/// navigation, context paging, async fetches, practice overlay) lives in a
/// sibling part file and composes onto it. `VocabularyReviewSessionLifecycle`
/// precedes `VocabularyReviewSessionContext` / `VocabularyReviewSessionPractice`
/// because both call `clearPractice()`.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/analytics/analytics.dart';
import 'package:enjoy_player/core/analytics/analytics_events.dart';
import 'package:enjoy_player/core/analytics/analytics_provider.dart';
import 'package:enjoy_player/core/errors/app_failure.dart';
import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/features/ai/application/ai_services.dart';
import 'package:enjoy_player/features/player/application/echo_mode_provider.dart';
import 'package:enjoy_player/features/player/application/player_controller.dart';
import 'package:enjoy_player/features/vocabulary/application/vocabulary_providers.dart';
import 'package:enjoy_player/features/vocabulary/application/vocabulary_review_media.dart';
import 'package:enjoy_player/features/vocabulary/application/vocabulary_review_session_state.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_explanation_codec.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_models.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_review_practice.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_session_selection.dart';

export 'vocabulary_review_session_state.dart';

part 'vocabulary_review_session_context.dart';
part 'vocabulary_review_session_fetches.dart';
part 'vocabulary_review_session_lifecycle.dart';
part 'vocabulary_review_session_navigation.dart';
part 'vocabulary_review_session_practice.dart';

final _log = logNamed('VocabularyReviewSession');

final vocabularyReviewSessionProvider =
    NotifierProvider<VocabularyReviewSession, ReviewSessionState>(
      VocabularyReviewSession.new,
    );

/// Run-scoped state shared by every concern mixin.
mixin VocabularyReviewSessionBase on Notifier<ReviewSessionState> {
  /// Ratings for the current run, keyed by item — lets the completion event
  /// report correct-vs-incorrect without changing [ReviewSessionState].
  final Map<String, VocabularyRating> _ratings = {};

  /// When flashcard practice (clip/echo) was opened — for practice duration.
  DateTime? _practiceOpenedAt;

  Analytics get _analytics => ref.read(analyticsProvider);

  void _clearRunTallies() {
    _ratings.clear();
    _practiceOpenedAt = null;
  }

  /// Emits the catalog review-completion event from the tallies of this run.
  void _captureReviewCompleted() {
    final correct = _ratings.values
        .where(
          (r) => r == VocabularyRating.know || r == VocabularyRating.knowWell,
        )
        .length;
    _analytics.capture(
      AnalyticsEvents.vocabularyReviewCompleted,
      properties: AnalyticsEvents.vocabularyReview(
        reviewedCount: _ratings.length,
        correctCount: correct,
      ),
    );
  }
}

class VocabularyReviewSession extends Notifier<ReviewSessionState>
    with
        VocabularyReviewSessionBase,
        VocabularyReviewSessionLifecycle,
        VocabularyReviewSessionNavigation,
        VocabularyReviewSessionContext,
        VocabularyReviewSessionFetches,
        VocabularyReviewSessionPractice {
  @override
  ReviewSessionState build() => const ReviewSessionState(queue: []);

  /// Whether a review queue is currently loaded (safe to read outside [build]).
  bool get hasActiveSession => state.hasActiveSession;
}
