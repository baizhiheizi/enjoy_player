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
  const SidebarAccountChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = EnjoyThemeTokens.of(context);
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final auth = ref.watch(authCtrlProvider);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        t.space8 + 2,
        t.space4,
        t.space8 + 2,
        t.space12,
      ),
      child: auth.when(
        data: (state) {
          if (authFlowInProgress(state)) {
            return _AccountRow(
              leading: SizedBox(
                width: 30,
                height: 30,
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
            final tierBadgeLabel = switch (tier) {
              SubscriptionTier.pro => l10n.profileSubscriptionPro,
              SubscriptionTier.lite => l10n.subscriptionTierLiteName,
              SubscriptionTier.free => null,
            };
            return _AccountRow(
              leading: Stack(
                clipBehavior: Clip.none,
                children: [
                  EnjoyAvatar(name: p.name, imageUrl: avatarUrl, size: 30),
                  if (updateBadge)
                    const Positioned(
                      right: -2,
                      top: -2,
                      child: UpdateNotificationDot(size: 9),
                    ),
                ],
              ),
              title: p.name,
              titleAccessory: tierBadgeLabel == null
                  ? null
                  : EnjoyTierBadge(
                      label: tierBadgeLabel,
                      muted: tier == SubscriptionTier.lite,
                    ),
              subtitle: l10n.settingsAccountOpenProfile,
              trailing: isFree
                  ? _SidebarUpgradeButton(
                      label: l10n.subscriptionUpgradeShort,
                      onPressed: () => context.push('/subscription'),
                    )
                  : Icon(EnjoyIcons.chevronRight, size: 14, color: t.textFaint),
              onTap: () => context.go('/profile'),
            );
          }
          return _AccountRow(
            leading: Container(
              width: 30,
              height: 30,
              decoration: ShapeDecoration(
                color: t.accentSoft,
                shape: const CircleBorder(),
              ),
              child: Icon(EnjoyIcons.signIn, color: t.accentInk, size: 16),
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
    this.subtitle,
    this.titleAccessory,
    this.trailing,
    this.titleMaxLines = 1,
    this.titleStyle,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? titleAccessory;
  final Widget? trailing;
  final VoidCallback onTap;
  final int titleMaxLines;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return EnjoyPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(t.radiusMd),
      pressedScale: 0.985,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: t.space8 + 2,
          vertical: t.space8,
        ),
        child: Row(
          children: [
            leading,
            SizedBox(width: t.space12 - 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          maxLines: titleMaxLines,
                          overflow: TextOverflow.ellipsis,
                          style:
                              titleStyle ??
                              tt.labelLarge?.copyWith(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      if (titleAccessory != null) ...[
                        SizedBox(width: t.space4 + 2),
                        titleAccessory!,
                      ],
                    ],
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tt.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontFeatures: const [],
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null) ...[SizedBox(width: t.space8), trailing!],
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
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: ShapeDecoration(
          gradient: t.aurora,
          shape: const StadiumBorder(),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
