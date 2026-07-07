/// Free vs Pro plan comparison with platform-aware upgrade actions.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/platform/subscription_purchase_capability.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_card.dart';
import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:enjoy_player/features/subscription/domain/subscription_status.dart';
import 'package:enjoy_player/features/subscription/presentation/widgets/mobile_purchase_unavailable.dart';
import 'package:enjoy_player/features/subscription/presentation/widgets/purchase_sheet.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class TierComparison extends StatelessWidget {
  const TierComparison({
    required this.status,
    super.key,
  });

  final SubscriptionStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    final currentTier = status.subscriptionTier;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.compare_arrows_rounded, size: 22, color: Theme.of(context).colorScheme.primary),
            SizedBox(width: t.space8),
            Flexible(
              child: Text(
                l10n.subscriptionTierComparisonTitle,
                style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        SizedBox(height: t.space16),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 640;
            final freeCard = _PlanCard(
              title: l10n.subscriptionTierFreeName,
              description: l10n.subscriptionTierFreeDescription,
              price: l10n.subscriptionTierFreePrice,
              dailyCredits: l10n.subscriptionTierFreeDailyCredits,
              features: _freeFeatures(l10n),
              isCurrent: currentTier == SubscriptionTier.free,
              stretchVertically: wide,
              actionLabel: currentTier == SubscriptionTier.free
                  ? l10n.subscriptionCurrentPlan
                  : l10n.subscriptionUpgrade,
              onAction: currentTier == SubscriptionTier.free
                  ? null
                  : () => _handleUpgrade(context),
            );
            final proCard = _PlanCard(
              title: l10n.subscriptionTierProName,
              description: l10n.subscriptionTierProDescription,
              price: l10n.subscriptionTierProPrice,
              dailyCredits: l10n.subscriptionTierProDailyCredits,
              features: _proFeatures(l10n),
              isCurrent: currentTier == SubscriptionTier.pro,
              emphasize: true,
              showRecommended: currentTier == SubscriptionTier.free,
              stretchVertically: wide,
              actionLabel: currentTier == SubscriptionTier.pro
                  ? l10n.subscriptionExtend
                  : l10n.subscriptionUpgrade,
              onAction: () => _handleUpgrade(context),
            );

            if (wide) {
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: freeCard),
                    SizedBox(width: t.space16),
                    Expanded(child: proCard),
                  ],
                ),
              );
            }
            return Column(
              children: [
                freeCard,
                SizedBox(height: t.space16),
                proCard,
              ],
            );
          },
        ),
      ],
    );
  }

  List<String> _freeFeatures(AppLocalizations l10n) => [
    l10n.subscriptionFeatureFreeTranslation,
    l10n.subscriptionFeatureFreeSmartTranslation,
    l10n.subscriptionFeatureFreeDictionary,
    l10n.subscriptionFeatureFreeAsr,
    l10n.subscriptionFeatureFreeTts,
    l10n.subscriptionFeatureFreeAssessment,
  ];

  List<String> _proFeatures(AppLocalizations l10n) => [
    l10n.subscriptionFeatureProTranslation,
    l10n.subscriptionFeatureProSmartTranslation,
    l10n.subscriptionFeatureProDictionary,
    l10n.subscriptionFeatureProAsr,
    l10n.subscriptionFeatureProTts,
    l10n.subscriptionFeatureProAssessment,
  ];

  Future<void> _handleUpgrade(BuildContext context) async {
    if (showsMobilePurchaseUnavailable()) {
      await showMobilePurchaseUnavailableDialog(context);
      return;
    }
    if (!supportsExternalSubscriptionPurchase()) return;
    if (!context.mounted) return;
    await showSubscriptionPurchaseSheet(context);
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.description,
    required this.price,
    required this.dailyCredits,
    required this.features,
    required this.isCurrent,
    required this.actionLabel,
    this.emphasize = false,
    this.showRecommended = false,
    this.stretchVertically = false,
    this.onAction,
  });

  final String title;
  final String description;
  final String price;
  final String dailyCredits;
  final List<String> features;
  final bool isCurrent;
  final bool emphasize;
  final bool showRecommended;
  final bool stretchVertically;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final card = EnjoyCard(
      padding: EdgeInsets.all(t.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: stretchVertically ? MainAxisSize.max : MainAxisSize.min,
        children: [
            SizedBox(
              height: 28,
              child: Align(
                alignment: Alignment.centerLeft,
                child: showRecommended
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [cs.primary, cs.tertiary],
                          ),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          l10n.subscriptionRecommendedPlan,
                          style: tt.labelSmall?.copyWith(
                            color: cs.onPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : isCurrent
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: cs.secondaryContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          l10n.subscriptionCurrentPlan,
                          style: tt.labelSmall?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
            SizedBox(height: t.space8),
            Row(
              children: [
                if (emphasize) ...[
                  Icon(Icons.auto_awesome_rounded, size: 20, color: cs.primary),
                  SizedBox(width: t.space4),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            SizedBox(height: t.space4),
            Text(
              description,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            SizedBox(height: t.space16),
            Text(
              price,
              style: tt.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: emphasize ? cs.primary : null,
              ),
            ),
            SizedBox(height: t.space4),
            Text(
              dailyCredits,
              style: tt.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: emphasize ? FontWeight.w600 : null,
              ),
            ),
            SizedBox(height: t.space16),
            for (final feature in features) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: emphasize ? cs.primary : cs.onSurfaceVariant,
                  ),
                  SizedBox(width: t.space8),
                  Expanded(child: Text(feature, style: tt.bodyMedium)),
                ],
              ),
              SizedBox(height: t.space8),
            ],
            if (stretchVertically) const Spacer(),
            if (!stretchVertically) SizedBox(height: t.space16),
            if (onAction == null)
              EnjoyButton.secondary(
                onPressed: null,
                child: Text(actionLabel),
              )
            else
              EnjoyButton.primary(
                onPressed: onAction,
                child: Text(actionLabel),
              ),
          ],
        ),
    );

    if (!emphasize) return card;

    return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(t.radiusLg + 2),
          gradient: LinearGradient(
            colors: [
              cs.primary.withValues(alpha: 0.85),
              cs.tertiary.withValues(alpha: 0.75),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: cs.primary.withValues(alpha: 0.22),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
      child: Padding(
        padding: const EdgeInsets.all(1.5),
        child: card,
      ),
    );
  }
}
