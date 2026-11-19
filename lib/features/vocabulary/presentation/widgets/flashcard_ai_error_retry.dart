import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/features/subscription/presentation/credits_failure_actions.dart';
import 'package:enjoy_player/features/vocabulary/domain/vocabulary_ai_error.dart';
import 'package:enjoy_player/features/vocabulary/presentation/widgets/flashcard_soft_error.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// The AI-fetch surface shared by the flashcard's dictionary and contextual
/// tabs.
///
/// [error] is one of the `kVocabularyAiError*` sentinels: a credits
/// rejection shows the credits message plus the plans-and-packages CTA, any
/// other failure shows the generic AI-fetch message, and a null [error] shows
/// neither. The retry button always follows, so a failed fetch can be
/// re-attempted in place.
class FlashcardAiErrorRetry extends StatelessWidget {
  const FlashcardAiErrorRetry({
    super.key,
    required this.error,
    required this.onRetry,
    required this.retryLabel,
  });

  final String? error;
  final VoidCallback onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final isCredits = error == kVocabularyAiErrorCredits;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (error != null) ...[
          FlashcardSoftError(
            message: isCredits
                ? l10n.subscriptionCreditsLimitMessageWithPackages
                : l10n.vocabularyAiFetchFailed,
          ),
          if (isCredits) ...[
            SizedBox(height: t.space8),
            const Align(
              alignment: AlignmentDirectional.centerStart,
              child: CreditsCtaButton(),
            ),
          ],
          SizedBox(height: t.space8),
        ],
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: EnjoyButton.secondary(
            onPressed: onRetry,
            child: Text(retryLabel),
          ),
        ),
      ],
    );
  }
}
