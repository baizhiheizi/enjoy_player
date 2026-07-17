/// Empty states for Vocabulary (no words / no due / no matches).
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

enum VocabularyEmptyKind { noWords, noDue, noMatches }

class VocabularyEmptyState extends StatelessWidget {
  const VocabularyEmptyState({super.key, required this.kind});

  final VocabularyEmptyKind kind;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;

    final (title, body) = switch (kind) {
      VocabularyEmptyKind.noWords => (
        l10n.vocabularyNoWords,
        l10n.vocabularyNoWordsDescription,
      ),
      VocabularyEmptyKind.noDue => (
        l10n.vocabularyNoDueItems,
        l10n.vocabularyNoDueItemsDescription,
      ),
      VocabularyEmptyKind.noMatches => (
        l10n.vocabularyNoMatches,
        l10n.vocabularyNoMatches,
      ),
    };

    return Center(
      child: Padding(
        padding: EdgeInsets.all(t.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 48,
              color: cs.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            SizedBox(height: t.space16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: t.space8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
