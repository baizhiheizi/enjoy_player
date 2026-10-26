/// Inline warning and loading placeholder for the unified purchase modal's
/// plan fetch.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Warns that an active auto-renew already exists, so a second one cannot be
/// started on the same account.
class ActiveAutoRenewWarning extends StatelessWidget {
  const ActiveAutoRenewWarning({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.tertiaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(t.radiusMd),
        border: Border.all(color: cs.tertiary.withValues(alpha: 0.4), width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.all(t.space12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(EnjoyIcons.warning, color: cs.onTertiaryContainer),
            SizedBox(width: t.space12),
            Expanded(
              child: Text(
                l10n.subscriptionPurchaseModalAutoRenewActiveWarning,
                style: tt.bodyMedium?.copyWith(color: cs.onTertiaryContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Spinner shown in place of the path selector while the plans catalog loads.
class PlansLoadingPlaceholder extends StatelessWidget {
  const PlansLoadingPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: t.space24),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}
