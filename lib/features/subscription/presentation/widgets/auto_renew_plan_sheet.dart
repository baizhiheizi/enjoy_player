/// Sheet to pick monthly/yearly auto-renew and start Stripe checkout.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:enjoy_player/core/errors/app_failure.dart';
import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/platform/subscription_purchase_capability.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_card.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_modal.dart';
import 'package:enjoy_player/features/subscription/application/subscription_plans_provider.dart';
import 'package:enjoy_player/features/subscription/application/subscription_purchase_provider.dart';
import 'package:enjoy_player/features/subscription/application/subscription_status_provider.dart';
import 'package:enjoy_player/features/subscription/domain/subscription_plan.dart';
import 'package:enjoy_player/features/subscription/presentation/widgets/mobile_purchase_unavailable.dart';
import 'package:enjoy_player/features/subscription/presentation/widgets/purchase_sheet.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

Future<void> showAutoRenewPlanSheet(BuildContext context) async {
  if (showsMobilePurchaseUnavailable()) {
    await showMobilePurchaseUnavailableDialog(context);
    return;
  }
  if (!supportsExternalSubscriptionPurchase()) return;
  if (!context.mounted) return;
  await showEnjoySheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => const _AutoRenewPlanSheetBody(),
  );
}

class _AutoRenewPlanSheetBody extends ConsumerStatefulWidget {
  const _AutoRenewPlanSheetBody();

  @override
  ConsumerState<_AutoRenewPlanSheetBody> createState() =>
      _AutoRenewPlanSheetBodyState();
}

class _AutoRenewPlanSheetBodyState
    extends ConsumerState<_AutoRenewPlanSheetBody> {
  String? _selectedPlanId;

  Future<void> _subscribe(SubscriptionPlan plan) async {
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
      AppNotice.error(
        context,
        e.message.isNotEmpty ? e.message : l10n.subscriptionPurchaseFailed,
      );
    } catch (e) {
      if (!mounted) return;
      final msg = switch (e.toString()) {
        final s
            when s.contains('missing_pay_url') ||
                s.contains('invalid_pay_url') =>
          l10n.subscriptionPaymentUrlMissing,
        final s when s.contains('launch_failed') =>
          l10n.subscriptionPaymentLaunchFailed,
        _ => l10n.subscriptionPurchaseFailed,
      };
      AppNotice.error(context, msg);
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
    final showPrepaid = status == null || !status.hasActiveAutoRenewPlan;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          t.space20,
          t.space16,
          t.space20,
          t.space24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.subscriptionAutoRenewTitle,
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            SizedBox(height: t.space16),
            plansAsync.when(
              data: (plans) {
                if (plans.isEmpty) {
                  return Text(l10n.subscriptionAutoRenewPlansUnavailable);
                }
                final selectedId = _selectedPlanId ?? plans.first.id;
                return Column(
                  children: [
                    for (final plan in plans) ...[
                      _PlanTile(
                        plan: plan,
                        selected: selectedId == plan.id,
                        onTap: busy
                            ? null
                            : () => setState(() => _selectedPlanId = plan.id),
                      ),
                      SizedBox(height: t.space8),
                    ],
                    SizedBox(height: t.space12),
                    EnjoyButton.primary(
                      onPressed: busy
                          ? null
                          : () async {
                              final plan = plans.firstWhere(
                                (p) => p.id == selectedId,
                                orElse: () => plans.first,
                              );
                              await _subscribe(plan);
                            },
                      child: Text(
                        busy
                            ? l10n.subscriptionRedirectingToPayment
                            : l10n.subscriptionAutoRenewSubscribe,
                      ),
                    ),
                    if (showPrepaid) ...[
                      SizedBox(height: t.space12),
                      TextButton(
                        onPressed: busy
                            ? null
                            : () async {
                                Navigator.pop(context);
                                if (!context.mounted) return;
                                await showSubscriptionPurchaseSheet(context);
                              },
                        child: Text(l10n.subscriptionPayOnceTitle),
                      ),
                      Text(
                        l10n.subscriptionPayOnceSubtitle,
                        style: tt.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Text(l10n.subscriptionAutoRenewPlansUnavailable),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.plan,
    required this.selected,
    required this.onTap,
  });

  final SubscriptionPlan plan;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final amount = NumberFormat('0.00').format(plan.amount);
    final title = plan.isYearly
        ? l10n.subscriptionAutoRenewYearly
        : l10n.subscriptionAutoRenewMonthly;
    final price = plan.isYearly
        ? l10n.subscriptionAutoRenewPriceYear(amount)
        : l10n.subscriptionAutoRenewPriceMonth(amount);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(t.radiusLg),
        child: EnjoyCard(
          padding: EdgeInsets.all(t.space16),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? cs.primary : cs.onSurfaceVariant,
              ),
              SizedBox(width: t.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(price, style: Theme.of(context).textTheme.bodyMedium),
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
