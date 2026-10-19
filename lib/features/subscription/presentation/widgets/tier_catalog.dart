/// Tier catalog: unified Free / Lite / Pro selection with a Monthly / Yearly toggle.
///
/// Replaces the previous free-vs-Pro comparison layout that lived in the
/// subscription screen. The Free card is read-only — it always reflects the
/// user's current tier when applicable. The Lite and Pro cards expose an
/// [onChoosePaid] callback that the host page wires up to the unified
/// purchase modal (auto-renew primary, prepaid secondary).
///
/// **Pricing is sourced from the catalog endpoint** (`GET /api/v1/subscriptions/plans`).
/// When a plan has not loaded yet, the price line renders a skeleton rather
/// than a hardcoded fallback — the Rails API is the single source of truth.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/typography.dart';
import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:enjoy_player/features/subscription/application/subscription_plans_provider.dart';
import 'package:enjoy_player/features/subscription/domain/subscription_plan.dart';
import 'package:enjoy_player/features/subscription/domain/subscription_status.dart';
import 'package:enjoy_player/features/subscription/presentation/widgets/tier_catalog_error.dart';
import 'package:enjoy_player/features/subscription/presentation/widgets/tier_catalog_free_card.dart';
import 'package:enjoy_player/features/subscription/presentation/widgets/tier_catalog_interval.dart';
import 'package:enjoy_player/features/subscription/presentation/widgets/tier_catalog_interval_toggle.dart';
import 'package:enjoy_player/features/subscription/presentation/widgets/tier_catalog_paid_card.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

export 'package:enjoy_player/features/subscription/presentation/widgets/tier_catalog_interval.dart'
    show CatalogInterval, catalogIntervalFromString, catalogIntervalWire;

/// Approximate savings percentage when paying yearly vs monthly for a tier.
///
/// Returns the integer percentage (e.g. `17` for a 17% saving) or `null` when
/// the inputs are missing or non-positive.
int? _savingsPercentForTier(List<SubscriptionPlan> plans, String tier) {
  SubscriptionPlan? monthly;
  SubscriptionPlan? yearly;
  for (final plan in plans) {
    if (plan.tier != tier) continue;
    if (plan.isYearly) {
      yearly = plan;
    } else {
      monthly = plan;
    }
  }
  if (monthly == null || yearly == null) return null;
  if (monthly.amount <= 0) return null;
  final monthlyAnnual = monthly.amount * 12;
  if (monthlyAnnual <= 0) return null;
  final ratio = 1 - (yearly.amount / monthlyAnnual);
  if (ratio.isNaN || ratio.isInfinite) return null;
  final pct = (ratio * 100).round();
  return pct <= 0 ? null : pct;
}

class TierCatalog extends ConsumerStatefulWidget {
  const TierCatalog({required this.status, this.onChoosePaid, super.key});

  final SubscriptionStatus status;

  /// Fired when the user taps a paid tier's CTA (Lite or Pro). The host wires
  /// this to the unified purchase modal (auto-renew primary, prepaid secondary).
  final void Function(SubscriptionTier tier, CatalogInterval interval)?
  onChoosePaid;

  @override
  ConsumerState<TierCatalog> createState() => _TierCatalogState();
}

class _TierCatalogState extends ConsumerState<TierCatalog> {
  CatalogInterval _interval = CatalogInterval.month;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    final plansAsync = ref.watch(subscriptionPlansProvider);

    if (widget.status.hasActiveAutoRenewPlan) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.subscriptionChoosePlan,
          style: enjoyDisplayStyle(
            context,
            size: 30,
            color: Theme.of(context).colorScheme.onSurface,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.subscriptionTierCatalogDescription,
          style: tt.bodyMedium?.copyWith(color: t.ink3),
        ),
        SizedBox(height: t.space20),
        plansAsync.when(
          data: (plans) => _buildContent(context, plans),
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => TierPlansError(
            onRetry: () => ref.invalidate(subscriptionPlansProvider),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, List<SubscriptionPlan> plans) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final liteSavings = _savingsPercentForTier(plans, 'lite');
    final proSavings = _savingsPercentForTier(plans, 'pro');
    final savingsPercent = proSavings ?? liteSavings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TierIntervalToggle(
          value: _interval,
          onChanged: (v) => setState(() => _interval = v),
          yearlyLabel: l10n.subscriptionAutoRenewYearly,
          monthlyLabel: l10n.subscriptionAutoRenewMonthly,
          savingsLabel:
              _interval == CatalogInterval.year && savingsPercent != null
              ? l10n.subscriptionTierCatalogIntervalYearSavings(
                  '$savingsPercent',
                )
              : null,
        ),
        SizedBox(height: t.space20),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 640;
            final freeCard = TierFreeCard(
              expand: wide,
              isCurrent:
                  widget.status.subscriptionTier == SubscriptionTier.free,
            );
            final liteCard = TierPaidCard(
              expand: wide,
              tier: SubscriptionTier.lite,
              plans: plans,
              interval: _interval,
              isCurrent:
                  widget.status.subscriptionTier == SubscriptionTier.lite,
              isLowerThanCurrent:
                  widget.status.subscriptionTier == SubscriptionTier.pro,
              onChoose: () => _onChoosePaid(SubscriptionTier.lite),
            );
            final proCard = TierPaidCard(
              expand: wide,
              tier: SubscriptionTier.pro,
              plans: plans,
              interval: _interval,
              isCurrent: widget.status.subscriptionTier == SubscriptionTier.pro,
              isLowerThanCurrent: false,
              onChoose: () => _onChoosePaid(SubscriptionTier.pro),
            );
            if (wide) {
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: freeCard),
                    SizedBox(width: t.space12),
                    Expanded(child: liteCard),
                    SizedBox(width: t.space12),
                    Expanded(child: proCard),
                  ],
                ),
              );
            }
            return Column(
              children: [
                proCard,
                SizedBox(height: t.space16),
                liteCard,
                SizedBox(height: t.space16),
                freeCard,
              ],
            );
          },
        ),
        SizedBox(height: t.space12),
        Text(
          l10n.subscriptionAutoRenewProvider('Stripe'),
          textAlign: TextAlign.center,
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }

  void _onChoosePaid(SubscriptionTier tier) {
    widget.onChoosePaid?.call(tier, _interval);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<CatalogInterval>('interval', _interval));
  }
}
