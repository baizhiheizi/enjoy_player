/// Displays current subscription tier, status, expiration, and credits limit.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:enjoy_player/core/errors/app_failure.dart';
import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_card.dart';
import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:enjoy_player/features/subscription/application/subscription_purchase_provider.dart';
import 'package:enjoy_player/features/subscription/application/subscription_status_provider.dart';
import 'package:enjoy_player/features/subscription/domain/auto_renew_billing.dart';
import 'package:enjoy_player/features/subscription/domain/subscription_status.dart';
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
      builder: (ctx) => AlertDialog(
        title: Text(l10n.subscriptionAutoRenewCancelConfirmTitle),
        content: Text(
          l10n.subscriptionAutoRenewCancelConfirmMessage(dateLabel),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.subscriptionAutoRenewCancelConfirmAction),
          ),
        ],
      ),
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
      AppNotice.error(
        context,
        e.message.isNotEmpty
            ? e.message
            : l10n.subscriptionAutoRenewCancelFailed,
      );
    } catch (_) {
      if (!context.mounted) return;
      AppNotice.error(context, l10n.subscriptionAutoRenewCancelFailed);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final tier = status.subscriptionTier;
    final isPro = tier == SubscriptionTier.pro;
    final tierLabel = isPro
        ? l10n.profileSubscriptionPro
        : l10n.profileSubscriptionFree;
    final ar = status.autoRenew;
    final cancelBusy = ref.watch(subscriptionPurchaseCtrlProvider).isLoading;

    return EnjoyCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(
              t.space20,
              t.space16,
              t.space20,
              t.space12,
            ),
            decoration: BoxDecoration(
              color: isPro
                  ? cs.primaryContainer.withValues(alpha: 0.35)
                  : cs.surfaceContainerHighest.withValues(alpha: 0.45),
              border: Border(
                bottom: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.25),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.badge_outlined,
                  size: 20,
                  color: isPro ? cs.primary : cs.onSurfaceVariant,
                ),
                SizedBox(width: t.space8),
                Expanded(
                  child: Text(
                    l10n.subscriptionStatusCardTitle,
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _TierBadge(label: tierLabel, isPro: isPro),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(t.space20),
            child: Column(
              children: [
                _StatusRow(
                  icon: Icons.layers_outlined,
                  label: l10n.subscriptionStatusTier,
                  child: _TierBadge(label: tierLabel, isPro: isPro),
                ),
                _DividerGap(tokens: t),
                _StatusRow(
                  icon: Icons.circle_outlined,
                  label: l10n.subscriptionStatusActive,
                  child: _TierBadge(
                    label: status.subscriptionActive
                        ? l10n.subscriptionActive
                        : l10n.subscriptionInactive,
                    isPro: status.subscriptionActive,
                  ),
                ),
                _DividerGap(tokens: t),
                _StatusRow(
                  icon: Icons.event_outlined,
                  label: l10n.subscriptionStatusExpiration,
                  child: Text(
                    _formatExpiration(context, status.subscriptionExpireDate),
                    style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
                _DividerGap(tokens: t),
                _StatusRow(
                  icon: Icons.bolt_rounded,
                  label: l10n.subscriptionStatusCreditsLimit,
                  child: Text(
                    l10n.subscriptionDailyCredits(
                      NumberFormat.decimalPattern().format(
                        status.dailyCreditsLimit,
                      ),
                    ),
                    style: tt.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isPro ? cs.primary : cs.onSurface,
                    ),
                  ),
                ),
                if (ar != null) ...[
                  _DividerGap(tokens: t),
                  _StatusRow(
                    icon: Icons.autorenew_rounded,
                    label: ar.autoRenew && !ar.cancelAtPeriodEnd
                        ? l10n.subscriptionAutoRenewOn
                        : l10n.subscriptionAutoRenewOff,
                    child: Text(
                      ar.interval == 'year'
                          ? l10n.subscriptionAutoRenewIntervalYear
                          : ar.interval == 'month'
                          ? l10n.subscriptionAutoRenewIntervalMonth
                          : ar.interval,
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (ar.amount != null) ...[
                    _DividerGap(tokens: t),
                    _StatusRow(
                      icon: Icons.payments_outlined,
                      label: ar.interval == 'year'
                          ? l10n.subscriptionAutoRenewPriceYear(
                              NumberFormat('0.00').format(ar.amount),
                            )
                          : l10n.subscriptionAutoRenewPriceMonth(
                              NumberFormat('0.00').format(ar.amount),
                            ),
                      child: Text(
                        ar.provider.isEmpty
                            ? ''
                            : l10n.subscriptionAutoRenewProvider(ar.provider),
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                  if (ar.isCancelable) ...[
                    SizedBox(height: t.space16),
                    EnjoyButton.secondary(
                      onPressed: cancelBusy
                          ? null
                          : () => _cancel(context, ref, ar),
                      child: Text(l10n.subscriptionAutoRenewCancel),
                    ),
                  ],
                ] else if (isPro) ...[
                  _DividerGap(tokens: t),
                  _StatusRow(
                    icon: Icons.autorenew_rounded,
                    label: l10n.subscriptionAutoRenewOff,
                    child: Text(
                      l10n.subscriptionPayOnceSubtitle,
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatExpiration(BuildContext context, String? iso) {
    final l10n = AppLocalizations.of(context)!;
    final formatted = _formatDate(context, iso);
    if (formatted == null) return l10n.subscriptionNeverExpires;
    return l10n.subscriptionExpiresOn(formatted);
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
}

class _DividerGap extends StatelessWidget {
  const _DividerGap({required this.tokens});

  final EnjoyThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: tokens.space12),
      child: Divider(
        height: 1,
        color: Theme.of(
          context,
        ).colorScheme.outlineVariant.withValues(alpha: 0.25),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.icon,
    required this.label,
    required this.child,
  });

  final IconData icon;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: cs.onSurfaceVariant),
        SizedBox(width: t.space8),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          flex: 3,
          child: Align(alignment: Alignment.centerRight, child: child),
        ),
      ],
    );
  }
}

class _TierBadge extends StatelessWidget {
  const _TierBadge({required this.label, required this.isPro});

  final String label;
  final bool isPro;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPro ? cs.primaryContainer : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: tt.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: isPro ? cs.onPrimaryContainer : cs.onSurfaceVariant,
        ),
      ),
    );
  }
}
