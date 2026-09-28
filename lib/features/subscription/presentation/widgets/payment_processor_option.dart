/// Selectable payment processor row with brand method icons.
library;

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/subscription/domain/payment_processor.dart';
import 'package:enjoy_player/features/subscription/presentation/widgets/payment_method_icons.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

typedef _MethodEntry = ({PaymentMethodIcon? icon, String label});

class PaymentProcessorOption extends StatelessWidget {
  const PaymentProcessorOption({
    required this.processor,
    required this.selected,
    required this.onSelected,
    required this.enabled,
    super.key,
  });

  final PaymentProcessor processor;
  final bool selected;
  final VoidCallback? onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final title = switch (processor) {
      PaymentProcessor.stripe => l10n.subscriptionProcessorStripe,
      PaymentProcessor.mixin => l10n.subscriptionProcessorMixin,
    };

    final methods = switch (processor) {
      PaymentProcessor.stripe => <_MethodEntry>[
        (
          icon: const PaymentMethodIcon(PaymentMethodIconKind.mastercard),
          label: l10n.subscriptionPaymentMethodCard,
        ),
        (
          icon: const PaymentMethodIcon(PaymentMethodIconKind.wechat),
          label: l10n.subscriptionPaymentMethodWechat,
        ),
        (
          icon: const PaymentMethodIcon(PaymentMethodIconKind.alipay),
          label: l10n.subscriptionPaymentMethodAlipay,
        ),
        (
          icon: const PaymentMethodIcon(PaymentMethodIconKind.googlePay),
          label: l10n.subscriptionPaymentMethodGooglePay,
        ),
      ],
      PaymentProcessor.mixin => <_MethodEntry>[
        (
          icon: const PaymentMethodIcon(PaymentMethodIconKind.usdt),
          label: l10n.subscriptionPaymentMethodUsdt,
        ),
        (
          icon: const PaymentMethodIcon(PaymentMethodIconKind.usdc),
          label: l10n.subscriptionPaymentMethodUsdc,
        ),
        (
          icon: const PaymentMethodIcon(PaymentMethodIconKind.btc),
          label: l10n.subscriptionPaymentMethodBtc,
        ),
        (
          icon: const PaymentMethodIcon(PaymentMethodIconKind.eth),
          label: l10n.subscriptionPaymentMethodEth,
        ),
        (
          icon: const PaymentMethodIcon(PaymentMethodIconKind.doge),
          label: l10n.subscriptionPaymentMethodDoge,
        ),
        (icon: null, label: l10n.subscriptionPaymentMethodAndMore),
      ],
    };

    return Material(
      color: selected
          ? cs.primaryContainer.withValues(alpha: 0.35)
          : cs.surfaceContainerHighest.withValues(alpha: 0.55),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(t.radiusMd),
        side: BorderSide(
          color: selected
              ? cs.primary.withValues(alpha: 0.65)
              : cs.outlineVariant.withValues(alpha: 0.35),
          width: selected ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onSelected : null,
        child: Padding(
          padding: EdgeInsets.all(t.space12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: t.space4),
                child: Icon(
                  selected ? EnjoyIcons.radioOn : EnjoyIcons.radioOff,
                  size: 20,
                  color: selected ? cs.primary : cs.onSurfaceVariant,
                ),
              ),
              SizedBox(width: t.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: t.space8),
                    Wrap(
                      spacing: t.space12,
                      runSpacing: t.space8,
                      children: [
                        for (final method in methods)
                          PaymentMethodChip(
                            icon: method.icon,
                            label: method.label,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
