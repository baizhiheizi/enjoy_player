/// Profile gradient hero card (avatar, name, email, Pro upgrade CTA).
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/utils/avatar_url.dart';
import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class ProfileHeroCard extends StatelessWidget {
  const ProfileHeroCard({required this.profile, super.key});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final p = profile;

    return ClipRRect(
      borderRadius: BorderRadius.circular(t.radiusXl),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              t.gradientStart.withValues(alpha: 0.94),
              t.gradientEnd.withValues(alpha: 0.9),
            ],
          ),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.28)),
        ),
        child: Padding(
          padding: EdgeInsets.all(t.space20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 32,
                backgroundImage: p.avatarUrl != null && p.avatarUrl!.isNotEmpty
                    ? NetworkImage(rasterAvatarUrl(p.avatarUrl!)!)
                    : null,
                child: p.avatarUrl == null || p.avatarUrl!.isEmpty
                    ? Icon(Icons.person_rounded, size: 36, color: cs.primary)
                    : null,
              ),
              SizedBox(width: t.space16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            p.name,
                            style: tt.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.35,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: t.space8),
                        SubscriptionChip(tier: p.subscriptionTier),
                      ],
                    ),
                    SizedBox(height: t.space4),
                    Text(
                      p.email,
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.82),
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (p.subscriptionTier != SubscriptionTier.pro) ...[
                SizedBox(width: t.space12),
                FilledButton.tonal(
                  onPressed: () => context.push('/subscription'),
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: t.space16,
                      vertical: t.space12,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(l10n.subscriptionUpgradeShort),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Pill chip showing the Pro / Free tier on the hero card.
class SubscriptionChip extends StatelessWidget {
  const SubscriptionChip({required this.tier, super.key});

  final SubscriptionTier? tier;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final label = tier == SubscriptionTier.pro
        ? l10n.profileSubscriptionPro
        : l10n.profileSubscriptionFree;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: tt.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: cs.onSecondaryContainer,
        ),
      ),
    );
  }
}
