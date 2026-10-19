/// Plans-loading failure surface for the tier catalog, with retry.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_card.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class TierPlansError extends StatelessWidget {
  const TierPlansError({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return EnjoyCard(
      padding: EdgeInsets.all(t.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.subscriptionAutoRenewPlansUnavailable,
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          SizedBox(height: t.space12),
          Align(
            alignment: Alignment.centerRight,
            child: EnjoyButton.secondary(
              onPressed: onRetry,
              child: Text(l10n.retry),
            ),
          ),
        ],
      ),
    );
  }
}
