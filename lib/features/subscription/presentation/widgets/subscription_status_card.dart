/// Current membership card: tier, renewal, credits — cancel stays low-emphasis.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:enjoy_player/core/errors/app_failure.dart';
import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/typography.dart';
import 'package:enjoy_player/core/theme/widgets/editorial_header.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_card.dart';
import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:enjoy_player/features/subscription/application/subscription_purchase_provider.dart';
import 'package:enjoy_player/features/subscription/application/subscription_status_provider.dart';
import 'package:enjoy_player/features/subscription/domain/auto_renew_billing.dart';
import 'package:enjoy_player/features/subscription/domain/subscription_status.dart';
import 'package:enjoy_player/features/subscription/presentation/widgets/auto_renew_plan_sheet.dart';
import 'package:enjoy_player/features/subscription/presentation/widgets/mobile_purchase_unavailable.dart';
import 'package:enjoy_player/features/subscription/presentation/widgets/tier_catalog.dart';
import 'package:enjoy_player/features/subscription/presentation/credits_failure_actions.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class SubscriptionStatusCard extends ConsumerWidget {
  const SubscriptionStatusCard({required this.status, super.key});

  final SubscriptionStatus status;

  Future<void> _cancel(
    BuildContext context,
    WidgetRef ref,
    AutoRenewBilling ar,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final dateLabel =
        _formatDate(context, ar.currentPeriodEnd) ??
        _formatDate(context, status.subscriptionExpireDate) ??
        l10n.subscriptionNeverExpires;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          title: Text(l10n.subscriptionAutoRenewCancelConfirmTitle),
          content: Text(
            l10n.subscriptionAutoRenewCancelConfirmMessage(dateLabel),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: cs.error),
              child: Text(l10n.subscriptionAutoRenewCancelConfirmAction),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.subscriptionAutoRenewCancelKeep),
            ),
          ],
        );
      },
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref
          .read(subscriptionPurchaseCtrlProvider.notifier)
          .cancelAutoRenew();
      ref.invalidate(subscriptionStatusProvider);
      if (!context.mounted) return;
      AppNotice.success(
        context,
        l10n.subscriptionAutoRenewCancelSuccess(dateLabel),
      );
    } on AppFailure catch (e) {
      if (!context.mounted) return;
      final msg = e is CreditsFailure
          ? creditsFailureMessage(e, l10n)
          : e.message.isNotEmpty
          ? e.message
          : l10n.subscriptionAutoRenewCancelFailed;
      AppNotice.error(context, msg);
    } catch (_) {
      if (!context.mounted) return;
      AppNotice.error(context, l10n.subscriptionAutoRenewCancelFailed);
    }
  }

  Future<void> _extendToPro(BuildContext context) async {
    if (await guardMobilePurchase(context)) return;
    if (!context.mounted) return;
    await showUnifiedPurchaseSheet(
      context,
      tier: SubscriptionTier.pro,
      interval: CatalogInterval.month,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isPaid = status.isPaidTier;
    final ar = status.autoRenew;
    final cancelBusy = ref.watch(subscriptionPurchaseCtrlProvider).isLoading;
    final creditsLabel = l10n.subscriptionDailyCredits(
      NumberFormat.decimalPattern().format(status.dailyCreditsLimit),
    );

    if (isPaid) {
      return _PaidMembershipCard(
        status: status,
        autoRenew: ar,
        creditsLabel: creditsLabel,
        cancelBusy: cancelBusy,
        onCancel: ar != null && ar.isCancelable
            ? () => _cancel(context, ref, ar)
            : null,
        onExtend: status.hasActiveAutoRenewPlan
            ? null
            : () {
                unawaited(_extendToPro(context));
              },
      );
    }

    return _PlanSummaryStrip(
      plan: l10n.profileSubscriptionFree,
      active: status.subscriptionActive,
      expiration:
          _formatDate(context, status.subscriptionExpireDate) ??
          l10n.subscriptionNeverExpires,
      creditsLabel: creditsLabel,
    );
  }
}

/// Flat four-cell summary card (the `Subscription` board's status strip).
class _PlanSummaryStrip extends StatelessWidget {
  const _PlanSummaryStrip({
    required this.plan,
    required this.active,
    required this.expiration,
    required this.creditsLabel,
    this.trailing,
  });

  final String plan;
  final bool active;
  final String expiration;
  final String creditsLabel;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    return EnjoyCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cells = <Widget>[
              _SummaryCell(
                overline: l10n.subscriptionSummaryCurrentPlan,
                child: Wrap(
                  spacing: 10,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      plan,
                      style: enjoyDisplayStyle(
                        context,
                        size: 26,
                        color: t.ink,
                        height: 1.2,
                      ),
                    ),
                    ?trailing,
                  ],
                ),
              ),
              _SummaryCell(
                overline: l10n.subscriptionSummaryStatus,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: active ? t.original : t.ink3,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        active
                            ? l10n.subscriptionActive
                            : l10n.subscriptionInactive,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.titleMedium?.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: t.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _SummaryCell(
                overline: l10n.subscriptionSummaryExpiration,
                child: Text(
                  expiration,
                  style: tt.titleMedium?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: t.ink,
                  ),
                ),
              ),
              _SummaryCell(
                overline: l10n.subscriptionSummaryDailyCredits,
                child: Text(
                  creditsLabel,
                  style: enjoyMonoStyle(context, size: 15, color: t.ink),
                ),
              ),
            ];
            if (constraints.maxWidth < 560) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (i, cell) in cells.indexed) ...[
                    if (i > 0) const SizedBox(height: 16),
                    cell,
                  ],
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (i, cell) in cells.indexed) ...[
                  if (i > 0) const SizedBox(width: 24),
                  Expanded(child: cell),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  const _SummaryCell({required this.overline, required this.child});

  final String overline;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [EnjoyOverline(overline), const SizedBox(height: 14), child],
    );
  }
}

class _PaidMembershipCard extends StatelessWidget {
  const _PaidMembershipCard({
    required this.status,
    required this.autoRenew,
    required this.creditsLabel,
    required this.cancelBusy,
    required this.onCancel,
    required this.onExtend,
  });

  final SubscriptionStatus status;
  final AutoRenewBilling? autoRenew;
  final String creditsLabel;
  final bool cancelBusy;
  final VoidCallback? onCancel;
  final VoidCallback? onExtend;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    final ar = autoRenew;
    final renewing = status.hasActiveAutoRenewPlan;
    final endingSoon = ar != null && ar.cancelAtPeriodEnd;
    final isLite = status.isLite;

    final periodDate =
        _formatDate(context, ar?.currentPeriodEnd) ??
        _formatDate(context, status.subscriptionExpireDate);
    final tierTitle = isLite
        ? l10n.subscriptionTierLiteName
        : l10n.subscriptionProMemberTitle;
    final tierBadge = isLite
        ? l10n.subscriptionTierLiteName
        : l10n.profileSubscriptionPro;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PlanSummaryStrip(
          plan: tierTitle,
          active: status.subscriptionActive,
          expiration:
              periodDate ??
              (renewing
                  ? l10n.subscriptionNeverExpires
                  : l10n.subscriptionNeverExpires),
          creditsLabel: creditsLabel,
          trailing: _SoftChip(
            label: renewing ? l10n.subscriptionAutoRenewOn : tierBadge,
            emphasized: false,
          ),
        ),
        if (endingSoon)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              l10n.subscriptionAutoRenewEndingSoon,
              style: tt.bodySmall?.copyWith(color: t.ink3),
            ),
          ),
        if (onExtend != null) ...[
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: EnjoyButton.brand(
              onPressed: onExtend,
              child: Text(l10n.subscriptionExtend),
            ),
          ),
        ],
        if (onCancel != null) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: EnjoyButton.ghost(
              onPressed: cancelBusy ? null : onCancel,
              child: Text(
                cancelBusy
                    ? l10n.subscriptionAutoRenewCancelConfirmAction
                    : l10n.subscriptionAutoRenewCancel,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

String? _formatDate(BuildContext context, String? iso) {
  if (iso == null || iso.isEmpty) return null;
  try {
    final date = DateTime.parse(iso).toLocal();
    return DateFormat.yMMMMd(
      Localizations.localeOf(context).toString(),
    ).format(date);
  } catch (_) {
    return iso;
  }
}

class _SoftChip extends StatelessWidget {
  const _SoftChip({required this.label, required this.emphasized});

  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        color: emphasized ? t.ink : t.sunk,
        shape: const StadiumBorder(),
      ),
      child: Text(
        label,
        style: tt.labelSmall?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: emphasized ? t.paper : t.ink2,
        ),
      ),
    );
  }
}
