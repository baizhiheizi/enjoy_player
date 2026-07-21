import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';

class FlashcardSoftError extends StatelessWidget {
  const FlashcardSoftError({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.errorContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(t.radiusSm),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: t.space12,
          vertical: t.space8,
        ),
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: cs.onErrorContainer,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}
