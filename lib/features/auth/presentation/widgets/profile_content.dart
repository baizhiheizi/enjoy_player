/// Shared, chrome-free body for the signed-in Enjoy profile.
///
/// Used exclusively by the Profile tab ([ProfileScreen]). Preferences are
/// now on a separate screen reached via the Preferences entry tile.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/centered_max_width_scroll.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_card.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_modal.dart';
import 'package:enjoy_player/core/theme/widgets/skeleton.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/application/profile_practice_stats_provider.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:enjoy_player/features/auth/presentation/widgets/profile_account_card.dart';
import 'package:enjoy_player/features/auth/presentation/widgets/profile_hero_card.dart';
import 'package:enjoy_player/features/auth/presentation/widgets/profile_sign_out_button.dart';
import 'package:enjoy_player/features/auth/presentation/widgets/profile_stats.dart';
import 'package:enjoy_player/features/credits/application/todays_credits_provider.dart';
import 'package:enjoy_player/features/library/application/learning_statistics_provider.dart';
import 'package:enjoy_player/features/subscription/application/current_tier_provider.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// The profile view body: hero card, practice stats, account nav card,
/// preferences entry, settings entry, and sign-out button.
///
/// Used exclusively by the Profile tab ([ProfileScreen]). The content is a
/// scrollable, pull-to-refreshable list sized to the shell body.
class ProfileContent extends ConsumerStatefulWidget {
  const ProfileContent({super.key});

  @override
  ConsumerState<ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends ConsumerState<ProfileContent> {
  bool _signingOut = false;

  Future<void> _refresh() async {
    ref.invalidate(profilePracticeStatsProvider);
    ref.invalidate(learningStatisticsProvider);
    ref.invalidate(todaysCreditsUsedProvider);
    await ref.read(authCtrlProvider.notifier).refreshProfile();
  }

  Future<void> _confirmAndSignOut() async {
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
    if (confirmed != true || !mounted) return;

    setState(() => _signingOut = true);
    try {
      await ref.read(authCtrlProvider.notifier).signOut();
      if (!mounted) return;
      context.go('/sign-in');
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final auth = ref.watch(authCtrlProvider);

    return auth.when(
      data: (state) {
        if (state is! AuthSignedIn) {
          return Center(child: Text(l10n.authSignInTitle));
        }
        final p = state.profile;

        final tier = ref.watch(currentTierProvider);
        final dailyLimit = tier == SubscriptionTier.pro ? 60000 : 1000;

        final creditsUsedAsync = ref.watch(todaysCreditsUsedProvider);
        final creditsUsed = creditsUsedAsync.valueOrNull;

        final children = <Widget>[
          ProfileHeroCard(profile: p),
          SizedBox(height: t.space16),
          ProfilePracticeSection(
            stats: ref.watch(profilePracticeStatsProvider),
          ),
          SizedBox(height: t.space8),
          ProfileAccountCard(
            creditsUsedToday: creditsUsed,
            dailyLimit: dailyLimit,
            onCreditsTap: () => context.push('/credits'),
            onSubscriptionTap: () => context.push('/subscription'),
          ),
          SizedBox(height: t.space16),
          EnjoyCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.tune_rounded),
              title: Text(l10n.profileSectionPreferences),
              subtitle: Text(l10n.profileSectionPreferencesHint),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push('/profile/preferences'),
            ),
          ),
          SizedBox(height: t.space8),
          EnjoyCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: Text(l10n.settingsTitle),
              subtitle: Text(l10n.settingsSubtitle),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push('/settings'),
            ),
          ),
          SizedBox(height: t.space32),
          ProfileSignOutButton(
            saving: _signingOut,
            onPressed: _confirmAndSignOut,
          ),
        ];

        final contentMaxWidth = t.contentMaxWidth + 96;
        return RefreshIndicator(
          onRefresh: _refresh,
          child: CenteredMaxWidthListView(
            maxWidth: contentMaxWidth,
            padding: EdgeInsets.fromLTRB(
              t.space24,
              t.space16,
              t.space24,
              t.space32,
            ),
            children: children,
          ),
        );
      },
      loading: () => const SkeletonProfile(),
      error: (e, _) => Center(child: Text(l10n.errorGenericLoadFailed)),
    );
  }
}
