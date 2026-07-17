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

    final (title, body, icon) = switch (kind) {
      VocabularyEmptyKind.noWords => (
        l10n.vocabularyNoWords,
        l10n.vocabularyNoWordsDescription,
        Icons.menu_book_outlined,
      ),
      VocabularyEmptyKind.noDue => (
        l10n.vocabularyNoDueItems,
        l10n.vocabularyNoDueItemsDescription,
        Icons.schedule_outlined,
      ),
      VocabularyEmptyKind.noMatches => (
        l10n.vocabularyNoMatches,
        l10n.vocabularyNoMatches,
        Icons.search_off_rounded,
      ),
    };

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: EdgeInsets.all(t.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: EdgeInsets.all(t.space20),
                  child: Icon(
                    icon,
                    size: 32,
                    color: cs.primary.withValues(alpha: 0.9),
                  ),
                ),
              ),
              SizedBox(height: t.space20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              SizedBox(height: t.space8),
              Text(
                body,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
