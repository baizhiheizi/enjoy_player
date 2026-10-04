/// Profile hero card (aurora-ringed avatar, serif name, Enjoy ID, Pro CTA).
library;

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/interaction/enjoy_tappable.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/typography.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_avatar.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_card.dart';
import 'package:enjoy_player/core/utils/avatar_url.dart';
import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:enjoy_player/features/subscription/application/current_tier_provider.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class ProfileHeroCard extends ConsumerWidget {
  const ProfileHeroCard({required this.profile, super.key});

  final UserProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tier = ref.watch(currentTierProvider);
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final p = profile;

    final light = Theme.of(context).brightness == Brightness.light;
    final avatarUrl = rasterAvatarUrl(p.avatarUrl);
    final radius = BorderRadius.circular(t.radiusXl);

    return EnjoyTappableSurface(
      borderRadius: radius,
      semanticsLabel: l10n.profileEditEntry,
      enableHoverScale: false,
      onTap: () => context.push('/profile/edit'),
      child: DecoratedBox(
        decoration: enjoyCardDecoration(
          context,
          radius: t.radiusXl,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.alphaBlend(
                t.auroraStart.withValues(alpha: light ? 0.08 : 0.14),
                t.card,
              ),
              t.card,
              Color.alphaBlend(
                t.auroraEnd.withValues(alpha: light ? 0.10 : 0.16),
                t.card,
              ),
            ],
            stops: const [0, 0.55, 1],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(t.space20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: t.aurora,
                ),
                child: Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: t.card,
                  ),
                  child: EnjoyAvatar(
                    name: p.name,
                    imageUrl: avatarUrl,
                    size: 62,
                  ),
                ),
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
                            style: enjoyDisplayStyle(
                              context,
                              size: 30,
                              color: cs.onSurface,
                              height: 1.1,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: t.space8),
                        SubscriptionChip(tier: tier),
                      ],
                    ),
                    SizedBox(height: t.space4),
                    Text(
                      p.id,
                      style: enjoyMonoStyle(
                        context,
                        size: 11.5,
                        weight: FontWeight.w400,
                        color: t.textFaint,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (tier == SubscriptionTier.free) ...[
                SizedBox(width: t.space12),
                EnjoyButton.brand(
                  size: EnjoyButtonSize.small,
                  icon: EnjoyIcons.crown,
                  onPressed: () => context.push('/subscription'),
                  child: Text(l10n.subscriptionUpgradeShort),
                ),
              ] else
                Icon(EnjoyIcons.chevronRight, size: 16, color: t.textFaint),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pill chip showing the current tier on the hero card.
class SubscriptionChip extends StatelessWidget {
  const SubscriptionChip({required this.tier, super.key});

  final SubscriptionTier? tier;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = switch (tier) {
      SubscriptionTier.pro => l10n.profileSubscriptionPro,
      SubscriptionTier.lite => l10n.subscriptionTierLiteName,
      SubscriptionTier.free || null => l10n.profileSubscriptionFree,
    };

    return EnjoyTierBadge(
      label: label,
      muted: tier == null || tier == SubscriptionTier.free,
    );
  }
}
