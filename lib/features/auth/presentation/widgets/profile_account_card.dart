/// Profile account card: credits row + Subscription / Credits nav tiles.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_card.dart';
import 'package:enjoy_player/features/settings/presentation/widgets/settings_row.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class ProfileAccountCard extends StatelessWidget {
  const ProfileAccountCard({
    required this.creditsUsedToday,
    required this.dailyLimit,
    required this.onCreditsTap,
    required this.onSubscriptionTap,
    super.key,
  });

  final int? creditsUsedToday;
  final int dailyLimit;
  final VoidCallback onCreditsTap;
  final VoidCallback onSubscriptionTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final used = creditsUsedToday ?? 0;
    final available = (dailyLimit - used).clamp(0, dailyLimit);
    final fmt = NumberFormat.decimalPattern();

    return EnjoyCard(
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            label: l10n.profileCreditsAvailable(
              fmt.format(available),
              fmt.format(dailyLimit),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: t.space20,
                vertical: t.space16,
              ),
              child: Row(
                children: [
                  Icon(Icons.bolt_rounded, size: 20, color: cs.primary),
                  SizedBox(width: t.space12),
                  Expanded(
                    child: Text(
                      l10n.profileCreditsAvailable(
                        fmt.format(available),
                        fmt.format(dailyLimit),
                      ),
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Divider(
            height: 1,
            indent: t.space20,
            endIndent: t.space20,
            color: cs.outlineVariant.withValues(alpha: 0.18),
          ),
          SettingsRow(
            leadingIcon: Icons.workspace_premium_outlined,
            title: l10n.profileSubscriptionTile,
            subtitle: l10n.profileSubscriptionSubtitle,
            onTap: onSubscriptionTap,
            responsive: false,
          ),
          Divider(
            height: 1,
            indent: t.space20,
            endIndent: t.space20,
            color: cs.outlineVariant.withValues(alpha: 0.18),
          ),
          SettingsRow(
            leadingIcon: Icons.receipt_long_rounded,
            title: l10n.profileCreditsUsageTile,
            subtitle: l10n.profileCreditsUsageSubtitle,
            onTap: onCreditsTap,
            responsive: false,
          ),
        ],
      ),
    );
  }
}
