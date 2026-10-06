/// Settings → Account (the `Settings` board's first rail row): the signed-in
/// identity row (logo-ring avatar, name, email, tier chip) with Sign out, or
/// a Sign in row when signed out.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_avatar.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_modal.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/presentation/widgets/profile_hero_card.dart'
    show subscriptionTierLabel;
import 'package:enjoy_player/features/subscription/application/current_tier_provider.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class AccountSection extends ConsumerWidget {
  const AccountSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    final auth = ref.watch(authCtrlProvider).valueOrNull;

    if (auth is! AuthSignedIn) {
      return Align(
        alignment: Alignment.centerLeft,
        child: EnjoyButton.secondary(
          onPressed: () => context.go('/sign-in'),
          child: Text(l10n.settingsAccountSignIn),
        ),
      );
    }

    final profile = auth.profile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              width: 46,
              height: 46,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: t.logo,
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: t.paper, width: 2),
                ),
                child: EnjoyAvatar(name: profile.name, size: 38),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: t.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    profile.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tt.bodySmall?.copyWith(fontSize: 13, color: t.ink3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              height: 24,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: Alignment.center,
              decoration: ShapeDecoration(
                color: t.sunk,
                shape: const StadiumBorder(),
              ),
              child: Text(
                subscriptionTierLabel(l10n, ref.watch(currentTierProvider)),
                style: tt.labelSmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: t.ink2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: EnjoyButton.secondary(
            onPressed: () => _confirmAndSignOut(context, ref),
            child: Text(l10n.authSignOut, style: TextStyle(color: t.danger)),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmAndSignOut(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showEnjoyAlertDialog<bool>(
      context: context,
      useRootNavigator: true,
      title: Text(l10n.profileSignOutConfirmTitle),
      content: Text(l10n.profileSignOutConfirmMessage),
      actionsBuilder: (ctx) => [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            l10n.authSignOut,
            style: TextStyle(color: Theme.of(ctx).colorScheme.error),
          ),
        ),
      ],
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(authCtrlProvider.notifier).signOut();
    if (context.mounted) context.go('/sign-in');
  }
}
