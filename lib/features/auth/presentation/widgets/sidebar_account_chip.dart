/// Sidebar account entry: sign-in or profile shortcut.
library;

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_avatar.dart';
import 'package:enjoy_player/core/presentation/loading_icon.dart';
import 'package:enjoy_player/core/utils/avatar_url.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:enjoy_player/features/subscription/application/current_tier_provider.dart';
import 'package:enjoy_player/features/update/application/update_controller.dart';
import 'package:enjoy_player/features/update/presentation/update_notification_dot.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class SidebarAccountChip extends ConsumerWidget {
  const SidebarAccountChip({super.key, this.selected = false});

  /// Pressed-plate state, driven by the shell from the active route.
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = EnjoyThemeTokens.of(context);
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final auth = ref.watch(authCtrlProvider);
    final radius = BorderRadius.circular(13);

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: auth.when(
        data: (state) {
          if (authFlowInProgress(state)) {
            return _AccountRow(
              selected: false,
              radius: radius,
              leading: SizedBox(
                width: 34,
                height: 34,
                child: Center(child: LoadingIcon(size: 18, color: cs.primary)),
              ),
              title: state is AuthAwaitingOtp
                  ? l10n.authOtpTitle
                  : l10n.authWebSignInWaiting,
              titleMaxLines: 2,
              onTap: () => context.push(
                state is AuthAwaitingOtp ? '/sign-in/email' : '/sign-in',
              ),
            );
          }
          if (state is AuthSignedIn) {
            final p = state.profile;
            final avatarUrl = rasterAvatarUrl(p.avatarUrl);
            final tier = ref.watch(currentTierProvider);
            final isFree = tier == SubscriptionTier.free;
            final updateBadge = ref.watch(updateAvailableBadgeProvider);
            final tierName = switch (tier) {
              SubscriptionTier.pro => l10n.profileSubscriptionPro,
              SubscriptionTier.lite => l10n.subscriptionTierLiteName,
              SubscriptionTier.free => l10n.subscriptionTierFreeName,
            };
            return _AccountRow(
              selected: selected,
              radius: radius,
              leading: Stack(
                clipBehavior: Clip.none,
                children: [
                  EnjoyAvatar(name: p.name, imageUrl: avatarUrl, size: 34),
                  if (updateBadge)
                    const Positioned(
                      right: -2,
                      top: -2,
                      child: UpdateNotificationDot(size: 9),
                    ),
                ],
              ),
              title: p.name,
              subtitle: l10n.sidebarPlanSubtitle(tierName),
              trailing: isFree
                  ? _SidebarUpgradeButton(
                      label: l10n.subscriptionUpgradeShort,
                      onPressed: () => context.push('/subscription'),
                    )
                  : Icon(EnjoyIcons.chevronRight, size: 14, color: t.ink3),
              onTap: () => context.go('/profile'),
            );
          }
          return _AccountRow(
            selected: selected,
            radius: radius,
            leading: Container(
              width: 34,
              height: 34,
              decoration: ShapeDecoration(
                color: t.brandSoft,
                shape: const CircleBorder(),
              ),
              child: Icon(EnjoyIcons.signIn, color: t.brandInk, size: 16),
            ),
            title: l10n.settingsAccountSignIn,
            titleStyle: tt.labelLarge?.copyWith(fontWeight: FontWeight.w600),
            onTap: () => context.push('/sign-in'),
          );
        },
        loading: () => const SizedBox(
          height: 44,
          child: Center(child: LoadingIcon(size: 18)),
        ),
        error: (Object e, StackTrace s) => const SizedBox.shrink(),
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.leading,
    required this.title,
    required this.onTap,
    required this.selected,
    required this.radius,
    this.subtitle,
    this.trailing,
    this.titleMaxLines = 1,
    this.titleStyle,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;
  final bool selected;
  final BorderRadius radius;
  final int titleMaxLines;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    return EnjoyPressable(
      onTap: onTap,
      borderRadius: radius,
      pressedScale: 0.985,
      selected: selected,
      child: AnimatedContainer(
        duration: t.motionFast,
        curve: Curves.easeOutCubic,
        constraints: const BoxConstraints(minHeight: 54),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: ShapeDecoration(
          color: selected ? t.paper : Colors.transparent,
          shape: RoundedSuperellipseBorder(borderRadius: radius),
          shadows: selected ? t.shadowCard : const [],
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: titleMaxLines,
                    overflow: TextOverflow.ellipsis,
                    style:
                        titleStyle ??
                        tt.labelLarge?.copyWith(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: t.ink,
                        ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tt.labelSmall?.copyWith(
                        fontSize: 12,
                        color: t.ink3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ],
        ),
      ),
    );
  }
}

class _SidebarUpgradeButton extends StatelessWidget {
  const _SidebarUpgradeButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    return EnjoyPressable(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(t.radiusFull),
      showHoverWash: false,
      hoverScale: 1.03,
      child: Container(
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: ShapeDecoration(
          gradient: t.brand,
          shape: const StadiumBorder(),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            height: 1,
          ),
        ),
      ),
    );
  }
}
