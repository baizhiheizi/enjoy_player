/// Prev/next pager for multi-context flashcards.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/interaction/enjoy_tappable.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class VocabularyContextPager extends StatelessWidget {
  const VocabularyContextPager({
    super.key,
    required this.index,
    required this.total,
    required this.onPrevious,
    required this.onNext,
  });

  /// Zero-based active index.
  final int index;

  final int total;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    if (total <= 1) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final display = index + 1;

    return Semantics(
      label: l10n.vocabularyContextOfTotal(display, total),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          EnjoyTappableIcon(
            icon: Icons.chevron_left_rounded,
            tooltip: l10n.vocabularyPreviousContext,
            onPressed: index > 0 ? onPrevious : null,
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: t.space8),
            child: Text(
              l10n.vocabularyContextOfTotal(display, total),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          EnjoyTappableIcon(
            icon: Icons.chevron_right_rounded,
            tooltip: l10n.vocabularyNextContext,
            onPressed: index < total - 1 ? onNext : null,
          ),
        ],
      ),
    );
  }
}
