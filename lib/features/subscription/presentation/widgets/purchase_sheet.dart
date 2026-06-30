/// Desktop purchase sheet: external checkout and balance conversion.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/errors/app_failure.dart';
import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/platform/subscription_purchase_capability.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_modal.dart';
import 'package:enjoy_player/features/subscription/application/subscription_purchase_provider.dart';
import 'package:enjoy_player/features/subscription/domain/payment_processor.dart';
import 'package:enjoy_player/features/subscription/domain/purchase_request.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

Future<void> showSubscriptionPurchaseSheet(
  BuildContext context, {
  double? accountBalance,
}) {
  if (!supportsExternalSubscriptionPurchase()) return Future.value();
  return showEnjoySheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _PurchaseSheetBody(accountBalance: accountBalance),
  );
}

class _PurchaseSheetBody extends ConsumerStatefulWidget {
  const _PurchaseSheetBody({this.accountBalance});

  final double? accountBalance;

  @override
  ConsumerState<_PurchaseSheetBody> createState() => _PurchaseSheetBodyState();
}

class _PurchaseSheetBodyState extends ConsumerState<_PurchaseSheetBody>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  int _months = 1;
  PaymentProcessor _processor = PaymentProcessor.stripe;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  double get _totalPrice => _months * kSubscriptionMonthlyPriceUsd;

  bool get _hasBalance => (widget.accountBalance ?? 0) > 0;

  Future<void> _purchaseExternal() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await ref
          .read(subscriptionPurchaseCtrlProvider.notifier)
          .purchaseExternal(months: _months, processor: _processor);
      if (!mounted) return;
      Navigator.pop(context);
      AppNotice.info(context, l10n.subscriptionRedirectingToPayment);
    } catch (e) {
      if (!mounted) return;
      final message = switch (e) {
        StateError(:final message) when message == 'missing_pay_url' =>
          l10n.subscriptionPaymentUrlMissing,
        StateError(:final message) when message == 'launch_failed' =>
          l10n.subscriptionPaymentLaunchFailed,
        StateError(:final message) when message == 'invalid_pay_url' =>
          l10n.subscriptionPaymentUrlMissing,
        AppFailure(:final message) => message,
        _ => l10n.subscriptionPurchaseFailed,
      };
      AppNotice.error(context, message);
    }
  }

  Future<void> _confirmBalancePurchase() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showEnjoyAlertDialog<bool>(
      context: context,
      title: Text(l10n.subscriptionConfirmBalanceTitle),
      content: Text(l10n.subscriptionConfirmBalanceMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.subscriptionConfirmPurchase),
        ),
      ],
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref
          .read(subscriptionPurchaseCtrlProvider.notifier)
          .purchaseWithBalance();
      if (!mounted) return;
      Navigator.pop(context);
      AppNotice.success(context, l10n.subscriptionPurchaseSuccess);
    } catch (e) {
      if (!mounted) return;
      final message = e is AppFailure ? e.message : l10n.subscriptionPurchaseFailed;
      AppNotice.error(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final purchaseState = ref.watch(subscriptionPurchaseCtrlProvider);
    final busy = purchaseState.isLoading;

    return Padding(
      padding: EdgeInsets.only(
        left: t.space20,
        right: t.space20,
        top: t.space12,
        bottom: MediaQuery.viewInsetsOf(context).bottom + t.space24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          SizedBox(height: t.space16),
          Text(
            l10n.subscriptionPurchaseTitle,
            style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: t.space4),
          Text(
            l10n.subscriptionPurchaseSelectDuration,
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          SizedBox(height: t.space16),
          TabBar(
            controller: _tabs,
            tabs: [
              Tab(text: l10n.subscriptionPurchasePaymentTab),
              Tab(text: l10n.subscriptionPurchaseBalanceTab),
            ],
          ),
          SizedBox(height: t.space16),
          SizedBox(
            height: 320,
            child: TabBarView(
              controller: _tabs,
              children: [
                _PaymentTab(
                  months: _months,
                  processor: _processor,
                  totalPrice: _totalPrice,
                  busy: busy,
                  onMonthsChanged: (v) => setState(() => _months = v),
                  onProcessorChanged: (v) => setState(() => _processor = v),
                  onPurchase: busy ? null : _purchaseExternal,
                ),
                _BalanceTab(
                  hasBalance: _hasBalance,
                  busy: busy,
                  onPurchase: busy ? null : _confirmBalancePurchase,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentTab extends StatelessWidget {
  const _PaymentTab({
    required this.months,
    required this.processor,
    required this.totalPrice,
    required this.busy,
    required this.onMonthsChanged,
    required this.onProcessorChanged,
    required this.onPurchase,
  });

  final int months;
  final PaymentProcessor processor;
  final double totalPrice;
  final bool busy;
  final ValueChanged<int> onMonthsChanged;
  final ValueChanged<PaymentProcessor> onProcessorChanged;
  final VoidCallback? onPurchase;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return ListView(
      children: [
        DropdownButtonFormField<int>(
          initialValue: months,
          decoration: InputDecoration(labelText: l10n.subscriptionPurchaseDuration),
          items: [
            for (var i = 1; i <= 12; i++)
              DropdownMenuItem(
                value: i,
                child: Text(
                  i == 1
                      ? l10n.subscriptionPurchaseOneMonth
                      : l10n.subscriptionPurchaseMonths(i),
                ),
              ),
          ],
          onChanged: busy ? null : (v) => onMonthsChanged(v ?? 1),
        ),
        SizedBox(height: t.space16),
        Text(l10n.subscriptionPurchasePaymentMethod, style: tt.titleSmall),
        RadioListTile<PaymentProcessor>(
          value: PaymentProcessor.stripe,
          groupValue: processor,
          onChanged: busy
              ? null
              : (v) {
                  if (v != null) onProcessorChanged(v);
                },
          title: Text(l10n.subscriptionProcessorStripe),
        ),
        RadioListTile<PaymentProcessor>(
          value: PaymentProcessor.mixin,
          groupValue: processor,
          onChanged: busy
              ? null
              : (v) {
                  if (v != null) onProcessorChanged(v);
                },
          title: Text(l10n.subscriptionProcessorMixin),
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
                  l10n.subscriptionTotalPrice(totalPrice.toStringAsFixed(2)),
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: t.space16),
        EnjoyButton.primary(
          onPressed: onPurchase,
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

class _BalanceTab extends StatelessWidget {
  const _BalanceTab({
    required this.hasBalance,
    required this.busy,
    required this.onPurchase,
  });

  final bool hasBalance;
  final bool busy;
  final VoidCallback? onPurchase;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;

    return ListView(
      children: [
        Text(
          hasBalance
              ? l10n.subscriptionBalancePurchaseDescription
              : l10n.subscriptionBalanceZeroMessage,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
        SizedBox(height: t.space24),
        EnjoyButton.secondary(
          onPressed: hasBalance ? onPurchase : null,
          child: busy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.subscriptionPurchaseWithBalance),
        ),
      ],
    );
  }
}
