/// Free-tier card for the tier catalog — read-only, reflects the user's
/// current tier when applicable.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/typography.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_avatar.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/features/subscription/presentation/widgets/tier_catalog_features.dart';
import 'package:enjoy_player/features/subscription/presentation/widgets/tier_catalog_scaffold.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class TierFreeCard extends StatelessWidget {
  const TierFreeCard({
    required this.expand,
    required this.isCurrent,
    super.key,
  });

  final bool expand;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return TierCardScaffold(
      expand: expand,
      badges: isCurrent
          ? EnjoyTierBadge(
              label: l10n.subscriptionCurrentPlan,
              color: cs.secondaryContainer,
              textColor: cs.onSecondaryContainer,
              padding: kCatalogPillPadding,
            )
          : null,
      title: l10n.subscriptionTierFreeName,
      description: l10n.subscriptionTierFreeDescription,
      price: Text(
        l10n.subscriptionTierFreePrice,
        style: enjoyDisplayStyle(
          context,
          size: kTierPriceSize,
          color: Theme.of(context).colorScheme.onSurface,
          height: 1,
        ),
      ),
      dailyCredits: l10n.subscriptionTierFreeDailyCredits,
      features: sharedAiFeatures(l10n),
      emphasizeFeatures: false,
      cta: EnjoyButton.secondary(
        onPressed: null,
        child: Text(
          isCurrent
              ? l10n.subscriptionCurrentPlan
              : l10n.subscriptionTierCatalogNotSelected,
        ),
      ),
    );
  }
}
