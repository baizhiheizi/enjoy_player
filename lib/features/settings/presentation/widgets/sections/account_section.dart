/// Settings → Account (the `Settings` board's first rail row): one card with
/// the signed-in identity row (logo-ring avatar, name, email, tier chip) and
/// Edit profile / Subscription / Credits usage rows, then a neutral Sign out
/// below the card; a Sign in button when signed out.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/routing/route_paths.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_avatar.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_modal.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/presentation/widgets/profile_hero_card.dart'
    show subscriptionTierLabel;
import 'package:enjoy_player/features/credits/application/todays_credits_provider.dart';
import 'package:enjoy_player/features/settings/presentation/widgets/settings_row.dart';
import 'package:enjoy_player/features/subscription/application/subscription_status_provider.dart';
import 'package:enjoy_player/features/subscription/domain/subscription_status.dart';
import 'package:enjoy_player/features/subscription/application/current_tier_provider.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Logo-ring avatar shared by the account surfaces (settings pane, hub card).
class AccountAvatar extends StatelessWidget {
  const AccountAvatar({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    return Container(
      width: 46,
      height: 46,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(shape: BoxShape.circle, gradient: t.logo),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: t.paper, width: 2),
        ),
        child: EnjoyAvatar(name: name, size: 38),
      ),
    );
  }
}

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
    final tier = ref.watch(currentTierProvider);
    final tierLabel = subscriptionTierLabel(l10n, tier);
    final creditsUsed = ref.watch(todaysCreditsUsedProvider).valueOrNull;
    final dailyLimit =
        ref.watch(subscriptionStatusProvider).valueOrNull?.dailyCreditsLimit ??
        dailyCreditsLimitForTier(tier);
    final number = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toString(),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: ShapeDecoration(
            color: t.paper,
            shape: RoundedSuperellipseBorder(
              borderRadius: BorderRadius.circular(t.radiusCard),
              side: BorderSide(color: t.line),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: kSettingsRowHorizontalPadding,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    AccountAvatar(name: profile.name),
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
                            style: tt.bodySmall?.copyWith(
                              fontSize: 13,
                              color: t.ink3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: ShapeDecoration(
                        color: t.sunk,
                        shape: const StadiumBorder(),
                      ),
                      child: Text(
                        tierLabel,
                        style: tt.labelSmall?.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: t.ink2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SettingsRowDivider(insetForLeading: false),
              SettingsRow(
                leadingIcon: EnjoyIcons.manageAccount,
                title: l10n.profileEditEntry,
                onTap: () => context.push('/profile/edit'),
              ),
              const SettingsRowDivider(),
              SettingsRow(
                leadingIcon: EnjoyIcons.crown,
                title: l10n.profileSubscriptionTile,
                valueBadge: SettingsValuePill(label: tierLabel),
                onTap: () => context.push(kSubscriptionRoutePath),
              ),
              const SettingsRowDivider(),
              SettingsRow(
                leadingIcon: EnjoyIcons.receipt,
                title: l10n.profileCreditsUsageTile,
                valueBadge: creditsUsed == null
                    ? null
                    : SettingsValuePill(
                        label: l10n.settingsAccountCreditsTodayValue(
                          number.format(creditsUsed),
                          number.format(dailyLimit),
                        ),
                      ),
                onTap: () => context.push(kCreditsRoutePath),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: EnjoyButton.secondary(
            icon: EnjoyIcons.signOut,
            onPressed: () => _confirmAndSignOut(context, ref),
            child: Text(l10n.authSignOut),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmAndSignOut(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showEnjoyConfirmDialog(
      context: context,
      title: l10n.profileSignOutConfirmTitle,
      message: l10n.profileSignOutConfirmMessage,
      confirmLabel: l10n.authSignOut,
      useRootNavigator: true,
      destructive: true,
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(authCtrlProvider.notifier).signOut();
    if (context.mounted) context.go('/sign-in');
  }
}
