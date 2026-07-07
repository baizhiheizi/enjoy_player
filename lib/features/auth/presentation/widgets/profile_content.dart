/// Shared, chrome-free body for the signed-in Enjoy profile.
///
/// Used both by the standalone `/profile` route ([ProfileScreen]) and,
/// inline (no [Scaffold]/[AppBar]/pull-to-refresh), by the two-pane
/// Settings hub's Account detail pane — see
/// [SettingsLayoutTwoPane](../../../settings/presentation/widgets/settings_layout_two_pane.dart).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/application/app_language_catalog.dart';
import 'package:enjoy_player/core/presentation/language_labels.dart';
import 'package:enjoy_player/core/application/app_preferences_provider.dart';
import 'package:enjoy_player/core/interaction/haptics.dart';
import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/utils/avatar_url.dart';
import 'package:enjoy_player/core/theme/widgets/centered_max_width_scroll.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_card.dart';
import 'package:enjoy_player/core/utils/time_format.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_modal.dart';
import 'package:enjoy_player/core/theme/widgets/skeleton.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/application/profile_practice_stats_provider.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/domain/update_profile_request.dart';
import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:enjoy_player/features/library/application/learning_statistics_provider.dart';
import 'package:enjoy_player/features/library/domain/learning_statistics.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// The profile view/edit body: hero card, practice stats, account nav card,
/// preferences form, and sign-out button.
///
/// When [showRefreshIndicator] is `true` (the default, used by the
/// standalone `/profile` route), the content is a scrollable,
/// pull-to-refreshable list sized to its own [Scaffold] body. When `false`
/// (used inline by the two-pane Settings Account tab, which already lives
/// inside the hub's own scroll view), the content is a plain, unscrollable
/// [Column] with a small manual refresh button instead of
/// [RefreshIndicator] — avoiding a scrollable-inside-scrollable layout.
class ProfileContent extends ConsumerStatefulWidget {
  const ProfileContent({super.key, this.showRefreshIndicator = true});

  final bool showRefreshIndicator;

  @override
  ConsumerState<ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends ConsumerState<ProfileContent> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _goal;
  bool _saving = false;
  String? _hydratedForProfileId;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _goal = TextEditingController();
  }

  @override
  void dispose() {
    _name.dispose();
    _goal.dispose();
    super.dispose();
  }

  void _applyProfile(UserProfile p) {
    _name.text = p.name;
    _goal.text = p.goal?.toString() ?? '';
  }

  String _languageOptionLabel(AppLocalizations l10n, String tag) =>
      focusLanguageLabel(l10n, tag);

  Future<void> _refresh() async {
    ref.invalidate(profilePracticeStatsProvider);
    ref.invalidate(learningStatisticsProvider);
    await ref.read(authCtrlProvider.notifier).refreshProfile();
    final v = ref.read(authCtrlProvider).valueOrNull;
    if (v is AuthSignedIn && mounted) {
      _applyProfile(v.profile);
      setState(() => _hydratedForProfileId = v.profile.id);
    }
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

    setState(() => _saving = true);
    try {
      await ref.read(authCtrlProvider.notifier).signOut();
      if (!mounted) return;
      context.go('/sign-in');
    } finally {
      if (mounted) setState(() => _saving = false);
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
        if (_hydratedForProfileId != p.id) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _applyProfile(p);
            setState(() => _hydratedForProfileId = p.id);
          });
        }

        final children = [
          _ProfileHeroCard(profile: p),
          SizedBox(height: t.space16),
          _ProfileSectionHeader(
            title: l10n.profileSectionPractice,
            hint: l10n.profileSectionPracticeHint,
            icon: Icons.insights_outlined,
          ),
          _ProfilePracticeSection(
            stats: ref.watch(profilePracticeStatsProvider),
          ),
          SizedBox(height: t.space8),
          _ProfileSectionHeader(
            title: l10n.profileSectionAccount,
            hint: l10n.profileSectionAccountHint,
            icon: Icons.account_balance_wallet_outlined,
          ),
          _ProfileAccountCard(
            balance: p.balance,
            onCreditsTap: () => context.push('/credits'),
            onSubscriptionTap: () => context.push('/subscription'),
          ),
          SizedBox(height: t.space8),
          _ProfileSectionHeader(
            title: l10n.profileSectionPreferences,
            hint: l10n.profileSectionPreferencesHint,
            icon: Icons.tune_rounded,
          ),
          EnjoyCard(
            padding: EdgeInsets.all(t.space16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _name,
                    decoration: InputDecoration(
                      labelText: l10n.profileFieldName,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? l10n.profileFieldRequired
                        : null,
                  ),
                  SizedBox(height: t.space16),
                  TextFormField(
                    controller: _goal,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.profileFieldGoal,
                    ),
                  ),
                  SizedBox(height: t.space16),
                  ref
                      .watch(appPreferencesCtrlProvider)
                      .when(
                        data: (pref) {
                          final displayTag = localeToBcp47(
                            pref.effectiveDisplayLocale,
                          );
                          final learnTag = pref.effectiveLearningLanguage;
                          final nativeTag = pref.effectiveNativeLanguage;
                          final nativeAllowed = allowedNativeTags(learnTag);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              DropdownButtonFormField<String>(
                                key: ValueKey<String>(
                                  'profile-locale-$displayTag',
                                ),
                                initialValue: displayTag,
                                decoration: InputDecoration(
                                  labelText:
                                      l10n.profileFieldDisplayLanguage,
                                ),
                                items: [
                                  for (final loc in kAppDisplayLocales)
                                    DropdownMenuItem(
                                      value: localeToBcp47(loc),
                                      child: Text(
                                        _languageOptionLabel(
                                          l10n,
                                          localeToBcp47(loc),
                                        ),
                                      ),
                                    ),
                                ],
                                onChanged: _saving
                                    ? null
                                    : (v) async {
                                        if (v == null) return;
                                        await ref
                                            .read(
                                              appPreferencesCtrlProvider
                                                  .notifier,
                                            )
                                            .setLocale(
                                              displayLocaleFromRawOrDefault(
                                                v,
                                              ),
                                            );
                                      },
                              ),
                              SizedBox(height: t.space16),
                              DropdownButtonFormField<String>(
                                key: ValueKey<String>(
                                  'profile-learn-$learnTag',
                                ),
                                initialValue: learnTag,
                                decoration: InputDecoration(
                                  labelText:
                                      l10n.profileFieldLearningLanguage,
                                  helperText:
                                      l10n.profileLearningLanguageReadOnly,
                                ),
                                items: [
                                  for (final tag
                                      in kSupportedFocusLanguageTags)
                                    DropdownMenuItem(
                                      value: tag,
                                      child: Text(
                                        _languageOptionLabel(l10n, tag),
                                      ),
                                    ),
                                ],
                                onChanged: _saving
                                    ? null
                                    : (v) async {
                                        if (v == null) return;
                                        await ref
                                            .read(
                                              appPreferencesCtrlProvider
                                                  .notifier,
                                            )
                                            .setLearningLanguage(v);
                                      },
                              ),
                              SizedBox(height: t.space16),
                              DropdownButtonFormField<String>(
                                key: ValueKey<String>(
                                  'profile-native-$nativeTag',
                                ),
                                initialValue:
                                    nativeAllowed.any(
                                      (tag) => tagsEqual(tag, nativeTag),
                                    )
                                    ? nativeTag
                                    : nativeAllowed.first,
                                decoration: InputDecoration(
                                  labelText:
                                      l10n.profileFieldNativeLanguage,
                                  helperText:
                                      l10n.settingsNativeMustDifferHint,
                                ),
                                items: [
                                  for (final tag in nativeAllowed)
                                    DropdownMenuItem(
                                      value: tag,
                                      child: Text(
                                        _languageOptionLabel(l10n, tag),
                                      ),
                                    ),
                                ],
                                onChanged:
                                    _saving || nativeAllowed.length <= 1
                                    ? null
                                    : (v) async {
                                        if (v == null) return;
                                        await ref
                                            .read(
                                              appPreferencesCtrlProvider
                                                  .notifier,
                                            )
                                            .setNativeLanguage(v);
                                      },
                              ),
                            ],
                          );
                        },
                        loading: () => Padding(
                          padding: EdgeInsets.only(bottom: t.space16),
                          child: Skeleton.line(
                            width: double.infinity,
                            height: 56,
                          ),
                        ),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                  SizedBox(height: t.space24),
                  EnjoyButton.primary(
                    onPressed: _saving
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) {
                              return;
                            }
                            setState(() => _saving = true);
                            try {
                              final goalText = _goal.text.trim();
                              int? goal;
                              if (goalText.isNotEmpty) {
                                goal = int.tryParse(goalText);
                              }
                              await ref
                                  .read(authCtrlProvider.notifier)
                                  .updateProfile(
                                    UpdateProfileRequest(
                                      name: _name.text.trim(),
                                      goal: goal,
                                    ),
                                  );
                              final after = ref
                                  .read(authCtrlProvider)
                                  .valueOrNull;
                              if (after is AuthSignedIn) {
                                _applyProfile(after.profile);
                              }
                              if (context.mounted) {
                                AppNotice.success(
                                  context,
                                  l10n.profileSaveSuccess,
                                );
                              }
                            } finally {
                              if (mounted) {
                                setState(() => _saving = false);
                              }
                            }
                          },
                    child: _saving
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.profileSave),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: t.space32),
          _ProfileSignOutButton(saving: _saving, onPressed: _confirmAndSignOut),
        ];

        if (widget.showRefreshIndicator) {
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
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: l10n.profileRefreshTooltip,
                onPressed: _refresh,
              ),
            ),
            ...children,
          ],
        );
      },
      loading: () => const SkeletonProfile(),
      error: (e, _) => Center(child: Text('$e')),
    );
  }
}

class _ProfileSectionHeader extends StatelessWidget {
  const _ProfileSectionHeader({
    required this.title,
    required this.hint,
    required this.icon,
  });

  final String title;
  final String hint;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(0, t.space8, 0, t.space8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Icon(icon, size: 20, color: cs.primary),
            ),
          ),
          SizedBox(width: t.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: tt.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: t.space4),
                Text(
                  hint,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.9),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({required this.profile});

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
                        _SubscriptionChip(tier: p.subscriptionTier),
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

class _ProfilePracticeSection extends ConsumerWidget {
  const _ProfilePracticeSection({required this.stats});

  final AsyncValue<LearningStatistics> stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return stats.when(
      data: (data) => _ProfileStatsRow(stats: data),
      loading: () => SizedBox(
        height: 100,
        child: Row(
          children: [
            Expanded(child: _ProfileStatSkeleton(tokens: t)),
            SizedBox(width: t.space12),
            Expanded(child: _ProfileStatSkeleton(tokens: t)),
            SizedBox(width: t.space12),
            Expanded(child: _ProfileStatSkeleton(tokens: t)),
          ],
        ),
      ),
      error: (_, _) => DecoratedBox(
        decoration: BoxDecoration(
          color: cs.errorContainer.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(t.radiusLg),
          border: Border.all(color: cs.error.withValues(alpha: 0.25)),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: t.space16,
            vertical: t.space12,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.error,
                  style: tt.bodySmall?.copyWith(color: cs.onErrorContainer),
                ),
              ),
              TextButton(
                onPressed: () {
                  ref.invalidate(profilePracticeStatsProvider);
                  ref.invalidate(learningStatisticsProvider);
                },
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileStatSkeleton extends StatelessWidget {
  const _ProfileStatSkeleton({required this.tokens});

  final EnjoyThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    return EnjoyCard(
      padding: EdgeInsets.all(tokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Skeleton.line(width: 48, height: 12),
          SizedBox(height: tokens.space12),
          Skeleton.line(width: 72, height: 22),
          SizedBox(height: tokens.space8),
          Skeleton.line(width: 56, height: 12),
        ],
      ),
    );
  }
}

class _ProfileAccountCard extends StatelessWidget {
  const _ProfileAccountCard({
    required this.balance,
    required this.onCreditsTap,
    required this.onSubscriptionTap,
  });

  final double? balance;
  final VoidCallback onCreditsTap;
  final VoidCallback onSubscriptionTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final balanceText = balance?.toStringAsFixed(2);
    final isNegative = balance != null && balance! < 0;

    return EnjoyCard(
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (balance != null && balanceText != null)
            Semantics(
              label: l10n.profileBalance(balanceText),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: t.space20,
                  vertical: t.space16,
                ),
                child: Row(
                  children: [
                    if (isNegative) ...[
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 20,
                        color: cs.error,
                      ),
                      SizedBox(width: t.space12),
                    ],
                    Expanded(
                      child: Text(
                        l10n.profileBalance(balanceText),
                        style: tt.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isNegative ? cs.error : null,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (balance != null && balanceText != null)
            Divider(
              height: 1,
              indent: t.space20,
              endIndent: t.space20,
              color: cs.outlineVariant.withValues(alpha: 0.18),
            ),
          _ProfileNavTile(
            leadingIcon: Icons.workspace_premium_outlined,
            title: l10n.profileSubscriptionTile,
            subtitle: l10n.profileSubscriptionSubtitle,
            onTap: onSubscriptionTap,
          ),
          Divider(
            height: 1,
            indent: t.space20,
            endIndent: t.space20,
            color: cs.outlineVariant.withValues(alpha: 0.18),
          ),
          _ProfileNavTile(
            leadingIcon: Icons.receipt_long_rounded,
            title: l10n.profileCreditsUsageTile,
            subtitle: l10n.profileCreditsUsageSubtitle,
            onTap: onCreditsTap,
          ),
        ],
      ),
    );
  }
}

class _ProfileNavTile extends StatelessWidget {
  const _ProfileNavTile({
    required this.leadingIcon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData leadingIcon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: Haptics.wrapTap(context, onTap),
        borderRadius: BorderRadius.circular(t.radiusLg),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return cs.primary.withValues(alpha: 0.08);
          }
          return null;
        }),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: t.space20,
              vertical: t.space12,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: Icon(leadingIcon, size: 22, color: cs.primary),
                  ),
                ),
                SizedBox(width: t.space16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: tt.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: t.space4),
                      Text(
                        subtitle,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileSignOutButton extends StatelessWidget {
  const _ProfileSignOutButton({required this.saving, required this.onPressed});

  final bool saving;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: l10n.authSignOut,
      child: TextButton.icon(
        onPressed: saving ? null : onPressed,
        icon: Icon(Icons.logout_rounded, color: cs.error, size: 20),
        label: Text(
          l10n.authSignOut,
          style: TextStyle(color: cs.error, fontWeight: FontWeight.w600),
        ),
        style: TextButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          foregroundColor: cs.error,
        ),
      ),
    );
  }
}

class _ProfileStatsRow extends StatelessWidget {
  const _ProfileStatsRow({required this.stats});

  final LearningStatistics stats;

  static const _narrowBreakpoint = 360.0;
  static const _tileWidth = 132.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    final tiles = [
      _ProfileStatTile(
        periodLabel: l10n.profileStatTodayTitle,
        durationLabel: formatPracticeDurationMs(
          stats.today.recordingDurationMs,
        ),
        recordingsLabel: l10n.transcriptLineRecordingCount(
          stats.today.recordingCount,
        ),
        icon: Icons.wb_sunny_outlined,
        accentColor: cs.primary,
        textTheme: tt,
        tokens: t,
      ),
      _ProfileStatTile(
        periodLabel: l10n.profileStatWeekTitle,
        durationLabel: formatPracticeDurationMs(stats.week.recordingDurationMs),
        recordingsLabel: l10n.transcriptLineRecordingCount(
          stats.week.recordingCount,
        ),
        icon: Icons.date_range_outlined,
        accentColor: cs.secondary,
        textTheme: tt,
        tokens: t,
      ),
      _ProfileStatTile(
        periodLabel: l10n.profileStatMonthTitle,
        durationLabel: formatPracticeDurationMs(
          stats.month.recordingDurationMs,
        ),
        recordingsLabel: l10n.transcriptLineRecordingCount(
          stats.month.recordingCount,
        ),
        icon: Icons.calendar_month_outlined,
        accentColor: cs.tertiary,
        textTheme: tt,
        tokens: t,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _narrowBreakpoint) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < tiles.length; i++) ...[
                  if (i > 0) SizedBox(width: t.space12),
                  SizedBox(width: _tileWidth, child: tiles[i]),
                ],
              ],
            ),
          );
        }

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < tiles.length; i++) ...[
                if (i > 0) SizedBox(width: t.space12),
                Expanded(child: tiles[i]),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ProfileStatTile extends StatelessWidget {
  const _ProfileStatTile({
    required this.periodLabel,
    required this.durationLabel,
    required this.recordingsLabel,
    required this.icon,
    required this.accentColor,
    required this.textTheme,
    required this.tokens,
  });

  final String periodLabel;
  final String durationLabel;
  final String recordingsLabel;
  final IconData icon;
  final Color accentColor;
  final TextTheme textTheme;
  final EnjoyThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return EnjoyCard(
      padding: EdgeInsets.all(tokens.space16),
      child: Semantics(
        container: true,
        label: '$periodLabel, $durationLabel, $recordingsLabel',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(tokens.radiusMd),
                  ),
                  child: Icon(icon, size: 18, color: accentColor),
                ),
                SizedBox(width: tokens.space8),
                Expanded(
                  child: Text(
                    periodLabel,
                    style: textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: tokens.space12),
            Text(
              durationLabel,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: tokens.space4),
            Text(
              recordingsLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubscriptionChip extends StatelessWidget {
  const _SubscriptionChip({required this.tier});

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
