/// Empty states for Vocabulary (no words / no due / no matches).
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/widgets/empty_state.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

enum VocabularyEmptyKind { noWords, noDue, noMatches }

class VocabularyEmptyState extends StatelessWidget {
  const VocabularyEmptyState({
    super.key,
    required this.kind,
    this.action,
    this.actionLabel,
  });

  final VocabularyEmptyKind kind;
  final VoidCallback? action;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
        l10n.vocabularyNoMatchesDescription,
        Icons.search_off_rounded,
      ),
    };

    return EmptyState(
      icon: icon,
      title: title,
      subtitle: body,
      action: action,
      actionLabel: actionLabel,
    );
  }
}
