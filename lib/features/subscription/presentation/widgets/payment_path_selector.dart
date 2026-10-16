/// Auto-renew / pay-once path selector and its option card for the unified
/// purchase modal.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_card.dart';
import 'package:enjoy_player/features/subscription/domain/subscription_plan.dart';
import 'package:enjoy_player/features/subscription/presentation/widgets/purchase_amount_format.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Payment path chosen inside the unified modal.
enum PaymentPath { autoRenew, prepaid }

/// Side-by-side (wide) or stacked (compact) choice between the two payment
/// paths.
class PaymentPathSelector extends StatelessWidget {
  const PaymentPathSelector({
    required this.selected,
    required this.intervalLabel,
    required this.plan,
    required this.unitPrice,
    required this.onChanged,
    super.key,
  });

  final PaymentPath selected;
  final String intervalLabel;
  final SubscriptionPlan? plan;
  final double? unitPrice;
  final ValueChanged<PaymentPath>? onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 520;
        final prepaidUnitPrice = unitPrice;
        final autoRenewCard = PaymentOptionCard(
          selected: selected == PaymentPath.autoRenew,
          onTap: onChanged == null
              ? null
              : () => onChanged!(PaymentPath.autoRenew),
          title: l10n.subscriptionPurchaseModalOptionAutoRenew,
          subtitle: l10n.subscriptionPurchaseModalOptionAutoRenewSubtitle,
          footnote: l10n.subscriptionPurchaseModalOptionAutoRenewFootnote,
          leadingIcon: EnjoyIcons.sync,
          emphasis: true,
          price: _autoRenewPriceLabel(l10n, plan),
          intervalLabel: intervalLabel,
        );
        final prepaidCard = PaymentOptionCard(
          selected: selected == PaymentPath.prepaid,
          onTap: onChanged == null
              ? null
              : () => onChanged!(PaymentPath.prepaid),
          title: l10n.subscriptionPurchaseModalOptionPrepaid,
          subtitle: l10n.subscriptionPurchaseModalOptionPrepaidSubtitle,
          footnote: l10n.subscriptionPurchaseModalOptionPrepaidFootnote,
          leadingIcon: EnjoyIcons.eventAvailable,
          price: prepaidUnitPrice != null
              ? l10n.subscriptionAutoRenewPriceMonth(
                  formatUsdAmount(prepaidUnitPrice),
                )
              : '—',
          intervalLabel: null,
        );

        if (wide) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: autoRenewCard),
                const SizedBox(width: 12),
                Expanded(child: prepaidCard),
              ],
            ),
          );
        }
        return Column(
          children: [autoRenewCard, const SizedBox(height: 12), prepaidCard],
        );
      },
    );
  }

  String _autoRenewPriceLabel(AppLocalizations l10n, SubscriptionPlan? plan) {
    if (plan == null) return '—';
    final formatted = formatUsdAmount(plan.amount);
    return plan.isYearly
        ? l10n.subscriptionAutoRenewPriceYear(formatted)
        : l10n.subscriptionAutoRenewPriceMonth(formatted);
  }
}

/// Selectable card for one [PaymentPath]; [emphasis] marks the recommended
/// auto-renew path with primary-colored price and border.
class PaymentOptionCard extends StatelessWidget {
  const PaymentOptionCard({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.footnote,
    required this.leadingIcon,
    required this.price,
    required this.intervalLabel,
    required this.onTap,
    this.emphasis = false,
    super.key,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final String footnote;
  final IconData leadingIcon;
  final String price;
  final String? intervalLabel;
  final bool emphasis;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final color = selected ? cs.primary : cs.outlineVariant;
    final bg = selected
        ? cs.primaryContainer.withValues(alpha: 0.45)
        : cs.surfaceContainerHighest.withValues(alpha: 0.45);

    final card = EnjoyCard(
      padding: EdgeInsets.all(t.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                selected ? EnjoyIcons.radioOn : EnjoyIcons.radioOff,
                color: selected ? cs.primary : cs.onSurfaceVariant,
              ),
              SizedBox(width: t.space12),
              Icon(leadingIcon, size: 18, color: cs.onSurfaceVariant),
              SizedBox(width: t.space8),
              Expanded(
                child: Text(
                  title,
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          SizedBox(height: t.space8),
          Padding(
            padding: EdgeInsets.only(left: t.space32),
            child: Text(
              subtitle,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          SizedBox(height: t.space12),
          Padding(
            padding: EdgeInsets.only(left: t.space32),
            child: Text(
              emphasis
                  ? '$price${intervalLabel != null ? ' · $intervalLabel' : ''}'
                  : price,
              style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: emphasis ? cs.primary : null,
              ),
            ),
          ),
          SizedBox(height: t.space8),
          Padding(
            padding: EdgeInsets.only(left: t.space32),
            child: Text(
              footnote,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );

    return Semantics(
      button: true,
      selected: selected,
      label: title,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: bg,
          shape: RoundedSuperellipseBorder(
            borderRadius: BorderRadius.circular(t.radiusLg),
            side: BorderSide(color: color, width: selected ? 1.6 : 1),
          ),
        ),
        child: ClipRSuperellipse(
          borderRadius: BorderRadius.circular(t.radiusLg),
          child: EnjoyPressable(
            borderRadius: BorderRadius.circular(t.radiusLg),
            onTap: onTap,
            child: Padding(padding: const EdgeInsets.all(2), child: card),
          ),
        ),
      ),
    );
  }
}
