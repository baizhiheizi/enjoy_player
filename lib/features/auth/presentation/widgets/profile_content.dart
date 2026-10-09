/// Shared, chrome-free body for the signed-in Enjoy profile.
///
/// Used exclusively by the Profile tab ([ProfileScreen]). Preferences are
/// now on a separate screen reached via the Preferences entry tile.
library;

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/layout/enjoy_page_kind.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/core/presentation/language_labels.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_icon_tile.dart';
import 'package:enjoy_player/features/credits/application/credits_summary_provider.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_card.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_modal.dart';
import 'package:enjoy_player/core/theme/widgets/skeleton.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/application/profile_practice_stats_provider.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:enjoy_player/features/auth/presentation/widgets/profile_hero_card.dart';
import 'package:enjoy_player/features/credits/application/todays_credits_provider.dart';
import 'package:enjoy_player/features/library/application/learning_statistics_provider.dart';
import 'package:enjoy_player/features/settings/presentation/widgets/settings_row.dart';
import 'package:enjoy_player/features/subscription/application/current_tier_provider.dart';
import 'package:enjoy_player/features/subscription/application/subscription_status_provider.dart';
import 'package:enjoy_player/features/subscription/domain/subscription_status.dart';
import 'package:enjoy_player/features/update/application/update_controller.dart';
import 'package:enjoy_player/features/update/presentation/update_notification_dot.dart';
import 'package:enjoy_player/features/vocabulary/application/vocabulary_providers.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// The profile view body: hero card, practice stats, account nav card,
/// unlabeled learning/config sections, and sign-out button.
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
    ref.invalidate(vocabularyStatsProvider);
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
        final status = ref.watch(subscriptionStatusProvider).valueOrNull;
        final dailyLimit =
            status?.dailyCreditsLimit ?? _fallbackDailyLimit(tier);

        final creditsUsedAsync = ref.watch(todaysCreditsUsedProvider);
        final creditsUsed = creditsUsedAsync.valueOrNull;
        final dueCount = ref.watch(vocabularyStatsProvider).due;

        final permanent = ref
            .watch(creditsSummaryProvider)
            .valueOrNull
            ?.permanentAvailable;
        final learning = p.learningLanguage;
        final prefsValue = [
          if (p.goal != null) '${p.goal} ${l10n.profileMinutesUnit}',
          if (learning != null && learning.isNotEmpty)
            focusLanguageLabel(l10n, learning),
        ].join(' · ');

        final children = <Widget>[
          ProfileHeroCard(profile: p),
          const SizedBox(height: 20),
          _ProfileTopCards(
            practice: ProfilePracticeCard(
              stats: ref.watch(profilePracticeStatsProvider).valueOrNull,
            ),
            credits: ProfileCreditsCard(
              used: creditsUsed,
              limit: dailyLimit,
              permanent: permanent,
              showUpgrade: tier == SubscriptionTier.free,
            ),
          ),
          const SizedBox(height: 20),
          _ProfileNavSection(
            rows: [
              SettingsRow(
                leadingIcon: EnjoyIcons.book,
                leadingIconTone: EnjoyIconTileTone.brand,
                title: l10n.vocabularyProfileEntry,
                subtitle: l10n.vocabularyProfileEntryHint,
                valueBadge: dueCount > 0
                    ? _RowValue(l10n.vocabularyReviewDueValue(dueCount))
                    : null,
                onTap: () => context.push('/vocabulary'),
                responsive: false,
              ),
              SettingsRow(
                leadingIcon: EnjoyIcons.crown,
                leadingIconTone: EnjoyIconTileTone.brand,
                title: l10n.profileSubscriptionTile,
                subtitle: l10n.profileSubscriptionSubtitle,
                valueBadge: _RowValue(subscriptionTierLabel(l10n, tier)),
                onTap: () => context.push('/subscription'),
                responsive: false,
              ),
              SettingsRow(
                leadingIcon: EnjoyIcons.receipt,
                title: l10n.profileCreditsUsageTile,
                subtitle: l10n.profileCreditsUsageSubtitle,
                onTap: () => context.push('/credits'),
                responsive: false,
              ),
              SettingsRow(
                leadingIcon: EnjoyIcons.tune,
                title: l10n.profileSectionPreferences,
                subtitle: l10n.profileSectionPreferencesHint,
                valueBadge: prefsValue.isEmpty ? null : _RowValue(prefsValue),
                onTap: () => context.push('/profile/preferences'),
                responsive: false,
              ),
              SettingsRow(
                leadingIcon: EnjoyIcons.manageAccount,
                title: l10n.profileEditEntry,
                subtitle: l10n.profileEditEntryHint,
                onTap: () => context.push('/profile/edit'),
                responsive: false,
              ),
              SettingsRow(
                leadingIcon: EnjoyIcons.settings,
                title: l10n.settingsTitle,
                subtitle: l10n.profileSettingsHint,
                valueBadge: ref.watch(updateAvailableBadgeProvider)
                    ? UpdateNotificationDot(
                        semanticsLabel: l10n.updateAvailableBadgeSemantics,
                      )
                    : null,
                onTap: () => context.push('/settings'),
                responsive: false,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: EnjoyButton.secondary(
              onPressed: _signingOut ? null : _confirmAndSignOut,
              child: Text(l10n.authSignOut, style: TextStyle(color: t.danger)),
            ),
          ),
        ];

        return LayoutBuilder(
          builder: (context, constraints) {
            final metrics = EnjoyPageMetrics.of(
              context,
              kind: EnjoyPageKind.hub,
              paneWidth: constraints.maxWidth,
            );
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: metrics.padding(top: 44, bottom: 72),
                children: children,
              ),
            );
          },
        );
      },
      loading: () => const SkeletonProfile(),
      error: (e, _) => Center(child: Text(l10n.errorGenericLoadFailed)),
    );
  }
}

/// Practice and Credits today side by side; stacked on narrow panes.
class _ProfileTopCards extends StatelessWidget {
  const _ProfileTopCards({required this.practice, required this.credits});

  final Widget practice;
  final Widget credits;

  static const double _kSplitMinWidth = 640;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _kSplitMinWidth) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [practice, const SizedBox(height: 20), credits],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: practice),
              const SizedBox(width: 20),
              Expanded(child: credits),
            ],
          ),
        );
      },
    );
  }
}

class _RowValue extends StatelessWidget {
  const _RowValue(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        fontSize: 13,
        color: EnjoyThemeTokens.of(context).ink3,
      ),
    );
  }
}

/// Zero-padding [EnjoyCard] of [SettingsRow]s separated by [SettingsRowDivider].
class _ProfileNavSection extends StatelessWidget {
  const _ProfileNavSection({required this.rows});

  final List<SettingsRow> rows;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      if (i > 0) children.add(const SettingsRowDivider());
      children.add(rows[i]);
    }
    return EnjoyCard(
      padding: EdgeInsets.zero,
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

/// Tier-based fallback for the daily credit limit when the live subscription
/// status has not loaded yet. Matches the entitlements in
/// [SubscriptionStatus.dailyCreditsLimit].
int _fallbackDailyLimit(SubscriptionTier tier) {
  switch (tier) {
    case SubscriptionTier.pro:
      return 60000;
    case SubscriptionTier.lite:
      return 12000;
    case SubscriptionTier.free:
      return 1000;
  }
}
