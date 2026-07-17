/// Shared Vocabulary localization helpers for status / relative labels.
library;

import 'package:enjoy_player/features/vocabulary/domain/vocabulary_models.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_relative_review.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

String vocabularyStatusLabel(AppLocalizations l10n, VocabularyStatus status) {
  return switch (status) {
    VocabularyStatus.new_ => l10n.vocabularyStatusNew,
    VocabularyStatus.learning => l10n.vocabularyStatusLearning,
    VocabularyStatus.reviewing => l10n.vocabularyStatusReviewing,
    VocabularyStatus.mastered => l10n.vocabularyStatusMastered,
  };
}

String vocabularyRelativeLabel(
  AppLocalizations l10n,
  RelativeNextReviewLabel label,
) {
  return switch (label) {
    RelativeNextReviewOverdue() => l10n.vocabularyOverdue,
    RelativeNextReviewToday() => l10n.vocabularyToday,
    RelativeNextReviewTomorrow() => l10n.vocabularyTomorrow,
    RelativeNextReviewInDays(:final days) => l10n.vocabularyInDays(days),
  };
}
