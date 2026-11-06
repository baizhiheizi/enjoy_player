import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/features/vocabulary/application/vocabulary_review_session.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_session_selection.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

Future<void> startVocabularyReview(
  BuildContext context,
  WidgetRef ref,
  ReviewSelectionOptions options,
) async {
  final started = await ref
      .read(vocabularyReviewSessionProvider.notifier)
      .start(options);
  if (!context.mounted) return;
  if (!started) {
    AppNotice.info(context, AppLocalizations.of(context)!.vocabularyEmptyQueue);
    return;
  }
  await context.push('/vocabulary/review');
}
