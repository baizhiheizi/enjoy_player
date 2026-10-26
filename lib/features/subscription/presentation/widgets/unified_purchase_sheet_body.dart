/// Stateful body of the unified purchase modal: owns the selected payment
/// path, prepaid duration and processor, and dispatches both purchase flows.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/errors/app_failure.dart';
import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:enjoy_player/features/subscription/application/subscription_plans_provider.dart';
import 'package:enjoy_player/features/subscription/application/subscription_purchase_provider.dart';
import 'package:enjoy_player/features/subscription/application/subscription_status_provider.dart';
import 'package:enjoy_player/features/subscription/domain/payment_processor.dart';
import 'package:enjoy_player/features/subscription/domain/purchase_request.dart';
import 'package:enjoy_player/features/subscription/domain/subscription_plan.dart';
import 'package:enjoy_player/features/subscription/presentation/credits_failure_actions.dart';
import 'package:enjoy_player/features/subscription/presentation/widgets/payment_path_selector.dart';
import 'package:enjoy_player/features/subscription/presentation/widgets/purchase_panels.dart';
import 'package:enjoy_player/features/subscription/presentation/widgets/plans_unavailable_view.dart';
import 'package:enjoy_player/features/subscription/presentation/widgets/purchase_sheet_helpers.dart';
import 'package:enjoy_player/features/subscription/presentation/widgets/tier_catalog.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class UnifiedPurchaseSheetBody extends ConsumerStatefulWidget {
  const UnifiedPurchaseSheetBody({
    required this.initialTier,
    required this.initialInterval,
    super.key,
  });

  final SubscriptionTier initialTier;
  final CatalogInterval initialInterval;

  @override
  ConsumerState<UnifiedPurchaseSheetBody> createState() =>
      UnifiedPurchaseSheetBodyState();
}

class UnifiedPurchaseSheetBodyState
    extends ConsumerState<UnifiedPurchaseSheetBody> {
  late PaymentPath _path;
  late int _months;
  late PaymentProcessor _processor;

  @override
  void initState() {
    super.initState();
    _path = PaymentPath.autoRenew;
    _months = widget.initialInterval == CatalogInterval.year ? 12 : 1;
    _processor = PaymentProcessor.stripe;
  }

  double? _prepaidTotal(List<SubscriptionPlan> plans) {
    final unit = prepaidUnitPriceForTier(plans, widget.initialTier.name);
    if (unit == null) return null;
    return _months * unit;
  }

  Future<void> _startAutoRenew(SubscriptionPlan plan) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await ref
          .read(subscriptionPurchaseCtrlProvider.notifier)
          .startAutoRenewExternal(planId: plan.id);
      if (!mounted) return;
      Navigator.pop(context);
      AppNotice.info(context, l10n.subscriptionRedirectingToPayment);
    } on SubscriptionConflictFailure catch (e) {
      if (!mounted) return;
      AppNotice.error(
        context,
        e.message.isNotEmpty ? e.message : l10n.subscriptionAutoRenewConflict,
      );
    } on AppFailure catch (e) {
      if (!mounted) return;
      final msg = e is CreditsFailure
          ? creditsFailureMessage(e, l10n)
          : e.message.isNotEmpty
          ? e.message
          : l10n.subscriptionPurchaseFailed;
      AppNotice.error(context, msg);
    } catch (e) {
      if (!mounted) return;
      final msg = switch (e) {
        StateError(:final message) when message == 'missing_pay_url' =>
          l10n.subscriptionPaymentUrlMissing,
        StateError(:final message) when message == 'launch_failed' =>
          l10n.subscriptionPaymentLaunchFailed,
        StateError(:final message) when message == 'invalid_pay_url' =>
          l10n.subscriptionPaymentUrlMissing,
        _ => l10n.subscriptionPurchaseFailed,
      };
      AppNotice.error(context, msg);
    }
  }

  Future<void> _startPrepaidPurchase() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await ref
          .read(subscriptionPurchaseCtrlProvider.notifier)
          .purchaseExternal(
            months: _months,
            processor: _processor,
            tier: widget.initialTier.name,
          );
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    final plansAsync = ref.watch(subscriptionPlansProvider);
    final busy = ref.watch(subscriptionPurchaseCtrlProvider).isLoading;
    final status = ref.watch(subscriptionStatusProvider).valueOrNull;
    final hasActiveAutoRenew = status?.hasActiveAutoRenewPlan ?? false;

    final interval = widget.initialInterval;
    final intervalLabel = interval == CatalogInterval.year
        ? l10n.subscriptionAutoRenewYearly
        : l10n.subscriptionAutoRenewMonthly;
    final tierLabel = widget.initialTier == SubscriptionTier.lite
        ? l10n.subscriptionTierLiteName
        : l10n.subscriptionTierProName;

    final selectedPlan = plansAsync.maybeWhen(
      data: (plans) => plans.isEmpty
          ? null
          : resolveCatalogPlan(plans, interval, widget.initialTier),
      orElse: () => null,
    );
    final plansLoadedNonEmpty = plansAsync.maybeWhen(
      data: (plans) => plans.isNotEmpty,
      orElse: () => false,
    );

    final unitPrice = plansAsync.maybeWhen(
      data: (plans) => prepaidUnitPriceForTier(plans, widget.initialTier.name),
      orElse: () => null,
    );
    final prepaidTotal = plansAsync.maybeWhen(
      data: (plans) => _prepaidTotal(plans),
      orElse: () => null,
    );

    return SafeArea(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            t.space20,
            t.space16,
            t.space20,
            t.space24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.subscriptionPurchaseModalUnifiedTitle(
                          tierLabel,
                          intervalLabel,
                        ),
                        style: tt.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: t.space4),
                Text(
                  l10n.subscriptionPurchaseModalUnifiedDescription,
                  style: tt.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: t.space16),
                if (hasActiveAutoRenew) ...[
                  const ActiveAutoRenewWarning(),
                  SizedBox(height: t.space16),
                ],
                plansAsync.when(
                  data: (plans) {
                    if (plans.isEmpty) {
                      return PlansUnavailableView(
                        onRetry: () =>
                            ref.invalidate(subscriptionPlansProvider),
                      );
                    }
                    return PaymentPathSelector(
                      selected: _path,
                      intervalLabel: intervalLabel,
                      plan: selectedPlan,
                      unitPrice: unitPrice,
                      onChanged: busy
                          ? null
                          : (path) => setState(() => _path = path),
                    );
                  },
                  loading: () => const PlansLoadingPlaceholder(),
                  error: (_, _) => PlansUnavailableView(
                    onRetry: () => ref.invalidate(subscriptionPlansProvider),
                  ),
                ),
                SizedBox(height: t.space16),
                if (plansLoadedNonEmpty)
                  if (_path == PaymentPath.autoRenew)
                    AutoRenewPanel(
                      busy: busy,
                      blocked: hasActiveAutoRenew,
                      plan: selectedPlan,
                      onSubscribe: busy || selectedPlan == null
                          ? null
                          : () => _startAutoRenew(selectedPlan),
                    )
                  else
                    PrepaidPanel(
                      months: _months,
                      processor: _processor,
                      busy: busy,
                      unitPrice: unitPrice,
                      totalPrice: prepaidTotal,
                      onMonthsChanged: (m) => setState(() => _months = m),
                      onProcessorChanged: (p) => setState(() => _processor = p),
                      onContinue: busy || unitPrice == null
                          ? null
                          : _startPrepaidPurchase,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
