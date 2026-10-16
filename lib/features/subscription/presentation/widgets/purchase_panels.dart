/// Per-path call-to-action blocks beneath the unified modal's path selector.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/features/subscription/domain/payment_processor.dart';
import 'package:enjoy_player/features/subscription/domain/subscription_plan.dart';
import 'package:enjoy_player/features/subscription/presentation/widgets/payment_processor_option.dart';
import 'package:enjoy_player/features/subscription/presentation/widgets/purchase_amount_format.dart';
import 'package:enjoy_player/features/subscription/presentation/widgets/subscription_duration_selector.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Auto-renew call to action: provider caption plus the subscribe button.
/// Stays disabled while [busy], while [blocked] by an existing active
/// auto-renew, or while [plan] has not resolved.
class AutoRenewPanel extends StatelessWidget {
  const AutoRenewPanel({
    required this.busy,
    required this.blocked,
    required this.plan,
    required this.onSubscribe,
    super.key,
  });

  final bool busy;
  final bool blocked;
  final SubscriptionPlan? plan;
  final VoidCallback? onSubscribe;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final disabled = busy || blocked || plan == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(t.radiusMd),
          ),
          child: Padding(
            padding: EdgeInsets.all(t.space12),
            child: Text(
              l10n.subscriptionAutoRenewProvider('Stripe'),
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
        ),
        SizedBox(height: t.space12),
        EnjoyButton.brand(
          onPressed: disabled ? null : onSubscribe,
          child: busy
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: t.space12),
                    Text(l10n.subscriptionRedirectingToPayment),
                  ],
                )
              : Text(l10n.subscriptionPurchaseModalSubscribeAutoRenewCta),
        ),
      ],
    );
  }
}

/// Pay-once call to action: duration and processor pickers, the computed
/// total, and the continue button.
class PrepaidPanel extends StatelessWidget {
  const PrepaidPanel({
    required this.months,
    required this.processor,
    required this.busy,
    required this.unitPrice,
    required this.totalPrice,
    required this.onMonthsChanged,
    required this.onProcessorChanged,
    required this.onContinue,
    super.key,
  });

  final int months;
  final PaymentProcessor processor;
  final bool busy;
  final double? unitPrice;
  final double? totalPrice;
  final ValueChanged<int> onMonthsChanged;
  final ValueChanged<PaymentProcessor> onProcessorChanged;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final total = totalPrice;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SubscriptionDurationSelector(
          months: months,
          enabled: !busy,
          onMonthsChanged: onMonthsChanged,
        ),
        SizedBox(height: t.space16),
        Text(l10n.subscriptionPurchasePaymentMethod, style: tt.titleSmall),
        SizedBox(height: t.space8),
        PaymentProcessorOption(
          processor: PaymentProcessor.stripe,
          selected: processor == PaymentProcessor.stripe,
          enabled: !busy,
          onSelected: () => onProcessorChanged(PaymentProcessor.stripe),
        ),
        SizedBox(height: t.space8),
        PaymentProcessorOption(
          processor: PaymentProcessor.mixin,
          selected: processor == PaymentProcessor.mixin,
          enabled: !busy,
          onSelected: () => onProcessorChanged(PaymentProcessor.mixin),
        ),
        SizedBox(height: t.space12),
        DecoratedBox(
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(t.radiusMd),
          ),
          child: Padding(
            padding: EdgeInsets.all(t.space16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.subscriptionTotalPriceLabel),
                Text(
                  l10n.subscriptionTotalPrice(
                    total != null ? formatUsdAmount(total) : '—',
                  ),
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: t.space16),
        EnjoyButton.brand(
          onPressed: onContinue,
          child: busy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.subscriptionContinueToPayment),
        ),
      ],
    );
  }
}
