/// Profile account card: balance row + Subscription / Credits nav tiles.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/interaction/haptics.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_card.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class ProfileAccountCard extends StatelessWidget {
  const ProfileAccountCard({
    required this.balance,
    required this.onCreditsTap,
    required this.onSubscriptionTap,
    super.key,
  });

  final double? balance;
  final VoidCallback onCreditsTap;
  final VoidCallback onSubscriptionTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final balanceText = balance?.toStringAsFixed(2);
    final isNegative = balance != null && balance! < 0;

    return EnjoyCard(
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (balance != null && balanceText != null)
            Semantics(
              label: l10n.profileBalance(balanceText),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: t.space20,
                  vertical: t.space16,
                ),
                child: Row(
                  children: [
                    if (isNegative) ...[
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 20,
                        color: cs.error,
                      ),
                      SizedBox(width: t.space12),
                    ],
                    Expanded(
                      child: Text(
                        l10n.profileBalance(balanceText),
                        style: tt.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isNegative ? cs.error : null,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (balance != null && balanceText != null)
            Divider(
              height: 1,
              indent: t.space20,
              endIndent: t.space20,
              color: cs.outlineVariant.withValues(alpha: 0.18),
            ),
          ProfileNavTile(
            leadingIcon: Icons.workspace_premium_outlined,
            title: l10n.profileSubscriptionTile,
            subtitle: l10n.profileSubscriptionSubtitle,
            onTap: onSubscriptionTap,
          ),
          Divider(
            height: 1,
            indent: t.space20,
            endIndent: t.space20,
            color: cs.outlineVariant.withValues(alpha: 0.18),
          ),
          ProfileNavTile(
            leadingIcon: Icons.receipt_long_rounded,
            title: l10n.profileCreditsUsageTile,
            subtitle: l10n.profileCreditsUsageSubtitle,
            onTap: onCreditsTap,
          ),
        ],
      ),
    );
  }
}

class ProfileNavTile extends StatelessWidget {
  const ProfileNavTile({
    required this.leadingIcon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    super.key,
  });

  final IconData leadingIcon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: Haptics.wrapTap(context, onTap),
        borderRadius: BorderRadius.circular(t.radiusLg),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return cs.primary.withValues(alpha: 0.08);
          }
          return null;
        }),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: t.space20,
              vertical: t.space12,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: Icon(leadingIcon, size: 22, color: cs.primary),
                  ),
                ),
                SizedBox(width: t.space16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: tt.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: t.space4),
                      Text(
                        subtitle,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
