library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/features/subscription/presentation/credits_failure_actions.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class LookupCreditsBanner extends StatelessWidget {
  const LookupCreditsBanner({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tt = Theme.of(context).textTheme;
    final t = EnjoyThemeTokens.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.sunk,
        borderRadius: BorderRadius.circular(t.radiusMd),
      ),
      child: Padding(
        padding: EdgeInsets.all(t.space12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(EnjoyIcons.wallet, size: 20, color: t.ink2),
                SizedBox(width: t.space8),
                Expanded(
                  child: Text(
                    message,
                    style: tt.bodySmall?.copyWith(height: 1.35),
                  ),
                ),
              ],
            ),
            SizedBox(height: t.space12),
            EnjoyButton.brand(
              size: EnjoyButtonSize.small,
              onPressed: () => context.push('/subscription'),
              child: Text(creditsCtaLabel(l10n)),
            ),
          ],
        ),
      ),
    );
  }
}
