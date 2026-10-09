/// Profile cards (the `Profile` board): the hero card (logo-ring avatar,
/// Literata name, plan chip, Enjoy ID, Edit profile / Upgrade), the Practice
/// card and the Credits today card.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';
import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/typography.dart';
import 'package:enjoy_player/core/theme/widgets/editorial_header.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_avatar.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_card.dart';
import 'package:enjoy_player/core/utils/avatar_url.dart';
import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:enjoy_player/features/library/domain/learning_statistics.dart';
import 'package:enjoy_player/features/subscription/application/current_tier_provider.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

const double _kAvatarSize = 92;
const double _kHeroStackBelow = 600;

/// `10482231` → `1048 2231`; non-numeric ids are left alone.
String formatEnjoyId(String id) {
  if (!RegExp(r'^\d+$').hasMatch(id)) return id;
  final groups = <String>[];
  for (var i = 0; i < id.length; i += 4) {
    groups.add(id.substring(i, (i + 4).clamp(0, id.length)));
  }
  return groups.join(' ');
}

String subscriptionTierLabel(AppLocalizations l10n, SubscriptionTier? tier) =>
    switch (tier) {
      SubscriptionTier.pro => l10n.profileSubscriptionPro,
      SubscriptionTier.lite => l10n.subscriptionTierLiteName,
      SubscriptionTier.free || null => l10n.profileSubscriptionFree,
    };

class ProfileHeroCard extends ConsumerWidget {
  const ProfileHeroCard({required this.profile, super.key});

  final UserProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tier = ref.watch(currentTierProvider);
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    final p = profile;

    final avatar = Container(
      width: _kAvatarSize,
      height: _kAvatarSize,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(shape: BoxShape.circle, gradient: t.logo),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: t.paper, width: 3),
        ),
        child: EnjoyAvatar(
          name: p.name,
          imageUrl: rasterAvatarUrl(p.avatarUrl),
          size: _kAvatarSize - 12,
        ),
      ),
    );

    final identity = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              p.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: enjoyDisplayStyle(
                context,
                size: 36,
                color: t.ink,
                height: 1.1,
                letterSpacing: -0.72,
              ),
            ),
            Container(
              constraints: const BoxConstraints(minHeight: 24),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: ShapeDecoration(
                color: tier == SubscriptionTier.free ? t.sunk : t.brandSoft,
                shape: const StadiumBorder(),
              ),
              child: Text(
                subscriptionTierLabel(l10n, tier),
                style: tt.labelSmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: tier == SubscriptionTier.free ? t.ink2 : t.brandInk,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              l10n.profileFieldEnjoyId,
              style: tt.bodySmall?.copyWith(fontSize: 13, color: t.ink3),
            ),
            Text(
              formatEnjoyId(p.id),
              style: enjoyMonoStyle(context, size: 13, color: t.ink2),
            ),
            Tooltip(
              message: l10n.profileCopied,
              child: EnjoyPressable(
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: p.id));
                  if (context.mounted) {
                    AppNotice.success(context, l10n.profileCopied);
                  }
                },
                borderRadius: BorderRadius.circular(7),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(EnjoyIcons.copy, size: 14, color: t.ink3),
                ),
              ),
            ),
          ],
        ),
      ],
    );

    final actions = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        EnjoyButton.secondary(
          onPressed: () => context.push('/profile/edit'),
          child: Text(l10n.profileEditEntry),
        ),
        if (tier == SubscriptionTier.free)
          EnjoyButton.brand(
            onPressed: () => context.push('/subscription'),
            child: Text(l10n.subscriptionUpgrade),
          ),
      ],
    );

    return EnjoyCard(
      radius: t.radiusSheet,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < _kHeroStackBelow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  avatar,
                  const SizedBox(height: 18),
                  identity,
                  const SizedBox(height: 20),
                  actions,
                ],
              );
            }
            return Row(
              children: [
                avatar,
                const SizedBox(width: 22),
                Expanded(child: identity),
                const SizedBox(width: 16),
                actions,
              ],
            );
          },
        ),
      ),
    );
  }
}

/// `12 min`, `1h 48m`, `6h 02m` — the figure and its unit separately.
(String, String?) profileDurationParts(AppLocalizations l10n, int ms) {
  final minutes = ms ~/ 60000;
  if (minutes < 60) return ('$minutes', l10n.profileMinutesUnit);
  final h = minutes ~/ 60;
  final m = (minutes % 60).toString().padLeft(2, '0');
  return ('${h}h ${m}m', null);
}

class ProfilePracticeCard extends StatelessWidget {
  const ProfilePracticeCard({super.key, required this.stats});

  final LearningStatistics? stats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    final s = stats;
    final totalMs =
        (s?.today.recordingDurationMs ?? 0) +
        (s?.week.recordingDurationMs ?? 0) +
        (s?.month.recordingDurationMs ?? 0);
    final cells = [
      (l10n.profileStatTodayTitle, s?.today.recordingDurationMs),
      (l10n.profileStatWeekTitle, s?.week.recordingDurationMs),
      (l10n.profileStatMonthTitle, s?.month.recordingDurationMs),
    ];
    return EnjoyCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(child: EnjoyOverline(l10n.profileSectionPractice)),
                Flexible(
                  child: Text(
                    l10n.profileSyncedFromAccount,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tt.bodySmall?.copyWith(
                      fontSize: 12.5,
                      color: t.ink3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (label, ms) in cells)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ProfileFigure(
                          parts: ms == null
                              ? ('—', null)
                              : profileDurationParts(l10n, ms),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          label,
                          style: tt.bodySmall?.copyWith(
                            fontSize: 12.5,
                            color: t.ink3,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            if (totalMs == 0) ...[
              const SizedBox(height: 14),
              Text(
                l10n.profilePracticeEmptyHint,
                style: tt.bodySmall?.copyWith(fontSize: 12.5, color: t.ink3),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProfileFigure extends StatelessWidget {
  const _ProfileFigure({required this.parts});

  final (String, String?) parts;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final (value, unit) = parts;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: value),
          if (unit != null)
            TextSpan(
              text: ' $unit',
              style: TextStyle(fontSize: 16, color: t.ink3),
            ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: enjoyDisplayStyle(context, size: 32, color: t.ink, height: 1),
    );
  }
}

class ProfileCreditsCard extends StatelessWidget {
  const ProfileCreditsCard({
    super.key,
    required this.used,
    required this.limit,
    required this.permanent,
    this.tier,
  });

  static const _kLowCreditsFraction = 0.9;

  final int? used;
  final int limit;
  final int? permanent;
  final SubscriptionTier? tier;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final number = NumberFormat.decimalPattern(locale);
    final fraction = used == null || limit <= 0
        ? 0.0
        : (used! / limit).clamp(0.0, 1.0);
    final isLow =
        used != null &&
        limit > 0 &&
        fraction >= ProfileCreditsCard._kLowCreditsFraction;
    final upgradeVisible = isLow && tier == SubscriptionTier.free;
    final extra = permanent;
    return EnjoyCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(child: EnjoyOverline(l10n.profileCreditsToday)),
                if (upgradeVisible) ...[
                  EnjoyButton.brand(
                    size: EnjoyButtonSize.small,
                    onPressed: () => context.push('/subscription'),
                    child: Text(l10n.subscriptionUpgradeShort),
                  ),
                  const SizedBox(width: 12),
                ],
                EnjoyPressable(
                  onTap: () => context.push('/credits'),
                  showHoverWash: false,
                  child: Text(
                    l10n.profileCreditsUsageLink,
                    style: tt.labelMedium?.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: t.brandInk,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: used == null ? '—' : number.format(used)),
                  TextSpan(
                    text: ' / ${number.format(limit)}',
                    style: tt.bodyMedium?.copyWith(fontSize: 14, color: t.ink3),
                  ),
                ],
              ),
              style: enjoyDisplayStyle(
                context,
                size: 32,
                color: t.ink,
                height: 1,
              ),
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 8,
                child: Stack(
                  children: [
                    Positioned.fill(child: ColoredBox(color: t.sunk)),
                    FractionallySizedBox(
                      widthFactor: fraction,
                      heightFactor: 1,
                      child: DecoratedBox(
                        decoration: isLow
                            ? BoxDecoration(
                                color: t.danger,
                                borderRadius: BorderRadius.circular(4),
                              )
                            : BoxDecoration(
                                gradient: t.logo,
                                borderRadius: BorderRadius.circular(4),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isLow
                  ? l10n.profileCreditsRunningLow
                  : extra != null && extra > 0
                  ? l10n.profileCreditsResetsWithPermanent(number.format(extra))
                  : l10n.profileCreditsResetsDaily,
              style: tt.bodySmall?.copyWith(
                fontSize: 12.5,
                color: isLow ? t.danger : t.ink3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
