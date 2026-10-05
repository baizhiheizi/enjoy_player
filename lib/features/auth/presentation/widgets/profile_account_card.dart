/// Profile account card: credits row + Subscription / Credits nav tiles.
library;

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_card.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_icon_tile.dart';
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
              padding: EdgeInsets.fromLTRB(
                kSettingsRowHorizontalPadding,
                t.space16,
                kSettingsRowHorizontalPadding,
                t.space16,
              ),
              child: Row(
                children: [
                  const EnjoyIconTile(
                    icon: EnjoyIcons.boltFill,
                    color: EnjoyTint.amber,
                    size: kSettingsRowLeadingSize,
                  ),
                  const SizedBox(width: kSettingsRowLeadingGap),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.profileCreditsAvailable(
                            fmt.format(available),
                            fmt.format(dailyLimit),
                          ),
                          style: tt.titleSmall?.copyWith(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w500,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        SizedBox(height: t.space8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(t.radiusFull),
                          child: SizedBox(
                            height: 5,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                ColoredBox(color: t.fill),
                                FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: dailyLimit <= 0
                                      ? 0
                                      : (available / dailyLimit).clamp(
                                          0.0,
                                          1.0,
                                        ),
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(gradient: t.logo),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SettingsRowDivider(insetForLeading: false),
          SettingsRow(
            leading: EnjoyIconTile(
              icon: EnjoyIcons.premium,
              size: kSettingsRowLeadingSize,
              gradient: t.logo,
            ),
            title: l10n.profileSubscriptionTile,
            subtitle: l10n.profileSubscriptionSubtitle,
            onTap: onSubscriptionTap,
            responsive: false,
          ),
          const SettingsRowDivider(),
          SettingsRow(
            leadingIcon: EnjoyIcons.receipt,
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
