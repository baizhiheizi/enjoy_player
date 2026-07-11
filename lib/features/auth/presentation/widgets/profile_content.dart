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
import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/centered_max_width_scroll.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_card.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_modal.dart';
import 'package:enjoy_player/core/theme/widgets/skeleton.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/application/profile_practice_stats_provider.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/domain/update_profile_request.dart';
import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:enjoy_player/features/auth/presentation/widgets/profile_account_card.dart';
import 'package:enjoy_player/features/auth/presentation/widgets/profile_hero_card.dart';
import 'package:enjoy_player/features/auth/presentation/widgets/profile_section_header.dart';
import 'package:enjoy_player/features/auth/presentation/widgets/profile_sign_out_button.dart';
import 'package:enjoy_player/features/auth/presentation/widgets/profile_stats.dart';
import 'package:enjoy_player/features/library/application/learning_statistics_provider.dart';
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

        final children = <Widget>[
          ProfileHeroCard(profile: p),
          SizedBox(height: t.space16),
          ProfileSectionHeader(
            title: l10n.profileSectionPractice,
            hint: l10n.profileSectionPracticeHint,
            icon: Icons.insights_outlined,
          ),
          ProfilePracticeSection(
            stats: ref.watch(profilePracticeStatsProvider),
          ),
          SizedBox(height: t.space8),
          ProfileSectionHeader(
            title: l10n.profileSectionAccount,
            hint: l10n.profileSectionAccountHint,
            icon: Icons.account_balance_wallet_outlined,
          ),
          ProfileAccountCard(
            balance: p.balance,
            onCreditsTap: () => context.push('/credits'),
            onSubscriptionTap: () => context.push('/subscription'),
          ),
          SizedBox(height: t.space8),
          ProfileSectionHeader(
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
                                  labelText: l10n.profileFieldDisplayLanguage,
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
                                              displayLocaleFromRawOrDefault(v),
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
                                  labelText: l10n.profileFieldLearningLanguage,
                                  helperText:
                                      l10n.profileLearningLanguageReadOnly,
                                ),
                                items: [
                                  for (final tag in kSupportedFocusLanguageTags)
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
                                  labelText: l10n.profileFieldNativeLanguage,
                                  helperText: l10n.settingsNativeMustDifferHint,
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
                                onChanged: _saving || nativeAllowed.length <= 1
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
          ProfileSignOutButton(saving: _saving, onPressed: _confirmAndSignOut),
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
      error: (e, _) => Center(child: Text(l10n.errorGenericLoadFailed)),
    );
  }
}
