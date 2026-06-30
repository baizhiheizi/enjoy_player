/// Displays current subscription tier, status, expiration, and credits limit.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_card.dart';
import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:enjoy_player/features/subscription/domain/subscription_status.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class SubscriptionStatusCard extends StatelessWidget {
  const SubscriptionStatusCard({required this.status, super.key});

  final SubscriptionStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final tier = status.subscriptionTier;
    final tierLabel = tier == SubscriptionTier.pro
        ? l10n.profileSubscriptionPro
        : l10n.profileSubscriptionFree;

    return EnjoyCard(
      padding: EdgeInsets.all(t.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.subscriptionStatusCardTitle,
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: t.space4),
          Text(
            l10n.subscriptionCurrentPlan,
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          SizedBox(height: t.space16),
          _StatusRow(
            label: l10n.subscriptionStatusTier,
            child: _TierBadge(label: tierLabel, isPro: tier == SubscriptionTier.pro),
          ),
          SizedBox(height: t.space12),
          _StatusRow(
            label: l10n.subscriptionStatusActive,
            child: _TierBadge(
              label: status.subscriptionActive
                  ? l10n.subscriptionActive
                  : l10n.subscriptionInactive,
              isPro: status.subscriptionActive,
            ),
          ),
          SizedBox(height: t.space12),
          _StatusRow(
            label: l10n.subscriptionStatusExpiration,
            child: Text(
              _formatExpiration(context, status.subscriptionExpireDate),
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          SizedBox(height: t.space12),
          _StatusRow(
            label: l10n.subscriptionStatusCreditsLimit,
            child: Text(
              l10n.subscriptionDailyCredits(
                NumberFormat.decimalPattern().format(status.dailyCreditsLimit),
              ),
              style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  String _formatExpiration(BuildContext context, String? iso) {
    final l10n = AppLocalizations.of(context)!;
    if (iso == null || iso.isEmpty) {
      return l10n.subscriptionNeverExpires;
    }
    try {
      final date = DateTime.parse(iso).toLocal();
      return l10n.subscriptionExpiresOn(
        DateFormat.yMMMMd(Localizations.localeOf(context).toString()).format(
          date,
        ),
      );
    } catch (_) {
      return iso;
    }
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(flex: 3, child: Align(alignment: Alignment.centerRight, child: child)),
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
