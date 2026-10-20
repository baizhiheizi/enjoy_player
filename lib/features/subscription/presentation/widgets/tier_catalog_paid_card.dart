/// Paid-tier (Lite / Pro) card for the tier catalog: interval-aware pricing,
/// badges, CTA, and the Pro highlight gradient.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/typography.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_avatar.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:enjoy_player/features/subscription/domain/subscription_plan.dart';
import 'package:enjoy_player/features/subscription/presentation/widgets/tier_catalog_features.dart';
import 'package:enjoy_player/features/subscription/presentation/widgets/tier_catalog_interval.dart';
import 'package:enjoy_player/features/subscription/presentation/widgets/tier_catalog_plan_lookup.dart';
import 'package:enjoy_player/features/subscription/presentation/widgets/tier_catalog_scaffold.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class TierPaidCard extends StatelessWidget {
  const TierPaidCard({
    required this.expand,
    required this.tier,
    required this.plans,
    required this.interval,
    required this.isCurrent,
    required this.isLowerThanCurrent,
    required this.onChoose,
    super.key,
  });

  final bool expand;
  final SubscriptionTier tier;
  final List<SubscriptionPlan> plans;
  final CatalogInterval interval;
  final bool isCurrent;
  final bool isLowerThanCurrent;
  final VoidCallback onChoose;

  bool get _isLite => tier == SubscriptionTier.lite;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final selectedPlan = resolveCatalogPlan(plans, interval, tier);
    final fallbackPlan = resolveCatalogPlan(plans, CatalogInterval.month, tier);
    final resolved = selectedPlan ?? fallbackPlan;
    final amount = resolved != null
        ? NumberFormat('0.00').format(resolved.amount)
        : null;
    final unitLabel = interval == CatalogInterval.year
        ? l10n.subscriptionTierCatalogPerYear
        : l10n.subscriptionTierCatalogPerMonth;

    final tierName = _isLite
        ? l10n.subscriptionTierLiteName
        : l10n.subscriptionTierProName;
    final tierDescription = _isLite
        ? l10n.subscriptionTierLiteDescription
        : l10n.subscriptionTierProDescription;
    final dailyCredits = _isLite
        ? l10n.subscriptionTierLiteDailyCredits
        : l10n.subscriptionTierProDailyCredits;

    final ctaLabel = isCurrent
        ? (_isLite
              ? l10n.subscriptionTierCatalogExtendLite
              : l10n.subscriptionTierCatalogExtendPro)
        : (_isLite
              ? l10n.subscriptionTierCatalogChooseLite
              : l10n.subscriptionTierCatalogChoosePro);
    final ctaEnabled = !isLowerThanCurrent && resolved != null;
    final ctaLabelActual = isLowerThanCurrent
        ? l10n.subscriptionTierCatalogNotSelected
        : ctaLabel;

    Widget? badges;
    if (!_isLite) {
      badges = Row(
        children: [
          EnjoyTierBadge(
            label: l10n.subscriptionTierCatalogRecommended,
            leading: EnjoyIcons.sparkleFill,
            padding: kCatalogPillPadding,
          ),
          if (isCurrent) ...[
            SizedBox(width: t.space8),
            EnjoyTierBadge(
              label: l10n.subscriptionCurrentPlan,
              color: cs.secondaryContainer,
              textColor: cs.onSecondaryContainer,
              padding: kCatalogPillPadding,
            ),
          ],
        ],
      );
    } else if (isCurrent) {
      badges = EnjoyTierBadge(
        label: l10n.subscriptionCurrentPlan,
        color: cs.secondaryContainer,
        textColor: cs.onSecondaryContainer,
        padding: kCatalogPillPadding,
      );
    }

    final price = Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: amount != null
              ? FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    '\$$amount',
                    maxLines: 1,
                    softWrap: false,
                    style: enjoyDisplayStyle(
                      context,
                      size: kTierPriceSize,
                      color: cs.onSurface,
                      height: 1,
                    ),
                  ),
                )
              : SizedBox(
                  width: 72,
                  height: 28,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(t.radiusSm),
                    ),
                  ),
                ),
        ),
        SizedBox(width: t.space4),
        Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Text(
            '/ $unitLabel',
            maxLines: 1,
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
      ],
    );

    final inner = TierCardScaffold(
      expand: expand,
      badges: badges,
      title: tierName,
      description: tierDescription,
      price: price,
      dailyCredits: dailyCredits,
      intervalLine: amount == null
          ? null
          : l10n.subscriptionTierCatalogSelectedInterval(amount, unitLabel),
      features: paidTierFeatures(l10n),
      emphasizeFeatures: !_isLite,
      cta: EnjoyButton.brand(
        onPressed: ctaEnabled ? onChoose : null,
        child: Text(ctaLabelActual),
      ),
    );

    if (!_isLite) {
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(t.radiusLg + 2),
          gradient: t.logo,
          boxShadow: [
            BoxShadow(
              color: t.logoEnd.withValues(alpha: 0.25),
              blurRadius: 32,
              spreadRadius: -6,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Padding(padding: const EdgeInsets.all(1.5), child: inner),
      );
    }
    return inner;
  }
}
