/// View and edit the signed-in Enjoy profile.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/application/app_language_catalog.dart';
import 'package:enjoy_player/core/application/app_preferences_provider.dart';
import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_card.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/application/profile_practice_stats_provider.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/domain/update_profile_request.dart';
import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:enjoy_player/core/theme/widgets/skeleton.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
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

  String _languageOptionLabel(AppLocalizations l10n, String tag) {
    if (tagsEqual(tag, 'en-US')) return l10n.settingsLanguageOptionEnUs;
    return l10n.settingsLanguageOptionZhCn;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final auth = ref.watch(authCtrlProvider);
    final cs = Theme.of(context).colorScheme;

    return auth.when(
      data: (state) {
        if (state is! AuthSignedIn) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.profileTitle)),
            body: Center(child: Text(l10n.authSignInTitle)),
          );
        }
        final p = state.profile;
        if (_hydratedForProfileId != p.id) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _applyProfile(p);
            setState(() => _hydratedForProfileId = p.id);
          });
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.profileTitle),
            actions: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: t.space8),
                child: Align(
                  alignment: Alignment.center,
                  child: EnjoyButton.destructive(
                    onPressed: _saving
                        ? null
                        : () async {
                            setState(() => _saving = true);
                            try {
                              await ref
                                  .read(authCtrlProvider.notifier)
                                  .signOut();
                              if (context.mounted) context.go('/');
                            } finally {
                              if (mounted) setState(() => _saving = false);
                            }
                          },
                    child: Text(l10n.authSignOut),
                  ),
                ),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(profilePracticeStatsProvider);
              await ref.read(authCtrlProvider.notifier).refreshProfile();
              final v = ref.read(authCtrlProvider).valueOrNull;
              if (v is AuthSignedIn && mounted) {
                _applyProfile(v.profile);
                setState(() => _hydratedForProfileId = v.profile.id);
              }
            },
            child: ListView(
              padding: EdgeInsets.all(t.space24),
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(t.space20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(t.radiusLg),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        cs.primary.withValues(alpha: 0.2),
                        t.gradientEnd.withValues(alpha: 0.12),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundImage:
                            p.avatarUrl != null && p.avatarUrl!.isNotEmpty
                            ? NetworkImage(p.avatarUrl!)
                            : null,
                        child: p.avatarUrl == null || p.avatarUrl!.isEmpty
                            ? Icon(
                                Icons.person_rounded,
                                size: 40,
                                color: cs.primary,
                              )
                            : null,
                      ),
                      SizedBox(width: t.space16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(
                              p.email,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: cs.onSurfaceVariant),
                            ),
                            SizedBox(height: t.space8),
                            _SubscriptionChip(tier: p.subscriptionTier),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                ref
                    .watch(profilePracticeStatsProvider)
                    .when(
                      data: (stats) => Padding(
                        padding: EdgeInsets.only(top: t.space16),
                        child: _ProfileStatsRow(stats: stats),
                      ),
                      loading: () => Padding(
                        padding: EdgeInsets.only(top: t.space16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Skeleton.line(
                                width: double.infinity,
                                height: 56,
                              ),
                            ),
                            SizedBox(width: t.space12),
                            Expanded(
                              child: Skeleton.line(
                                width: double.infinity,
                                height: 56,
                              ),
                            ),
                            SizedBox(width: t.space12),
                            Expanded(
                              child: Skeleton.line(
                                width: double.infinity,
                                height: 56,
                              ),
                            ),
                          ],
                        ),
                      ),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                if (p.balance != null) ...[
                  SizedBox(height: t.space12),
                  Text(
                    l10n.profileBalance(p.balance!.toStringAsFixed(2)),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                SizedBox(height: t.space8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.receipt_long_rounded, color: cs.primary),
                  title: Text(l10n.profileCreditsUsageTile),
                  subtitle: Text(
                    l10n.profileCreditsUsageSubtitle,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: cs.onSurfaceVariant,
                  ),
                  onTap: () => context.push('/credits'),
                ),
                SizedBox(height: t.space24),
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
                            border: const OutlineInputBorder(),
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
                            border: const OutlineInputBorder(),
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
                                final nativeAllowed = allowedNativeTags(
                                  learnTag,
                                );
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    DropdownButtonFormField<String>(
                                      key: ValueKey<String>(
                                        'profile-locale-$displayTag',
                                      ),
                                      initialValue: displayTag,
                                      decoration: InputDecoration(
                                        labelText:
                                            l10n.profileFieldDisplayLanguage,
                                        border: const OutlineInputBorder(),
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
                                        helperText: l10n
                                            .profileLearningLanguageReadOnly,
                                        border: const OutlineInputBorder(),
                                      ),
                                      items: [
                                        DropdownMenuItem(
                                          value: learnTag,
                                          child: Text(
                                            _languageOptionLabel(
                                              l10n,
                                              learnTag,
                                            ),
                                          ),
                                        ),
                                      ],
                                      onChanged: null,
                                    ),
                                    SizedBox(height: t.space16),
                                    DropdownButtonFormField<String>(
                                      key: ValueKey<String>(
                                        'profile-native-$nativeTag',
                                      ),
                                      initialValue:
                                          nativeAllowed.any(
                                            (t) => tagsEqual(t, nativeTag),
                                          )
                                          ? nativeTag
                                          : nativeAllowed.first,
                                      decoration: InputDecoration(
                                        labelText:
                                            l10n.profileFieldNativeLanguage,
                                        helperText:
                                            l10n.settingsNativeMustDifferHint,
                                        border: const OutlineInputBorder(),
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
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(l10n.profileSave),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.profileTitle)),
        body: const SkeletonProfile(),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(l10n.profileTitle)),
        body: Center(child: Text('$e')),
      ),
    );
  }
}

class _ProfileStatsRow extends StatelessWidget {
  const _ProfileStatsRow({required this.stats});

  final ProfilePracticeStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _ProfileStatTile(
            value: stats.libraryItemCount.toString(),
            title: l10n.profileStatLibraryTitle,
            subtitle: l10n.profileStatLibrarySubtitle,
            textTheme: tt,
            tokens: t,
          ),
        ),
        SizedBox(width: t.space12),
        Expanded(
          child: _ProfileStatTile(
            value: stats.echoSessionCount.toString(),
            title: l10n.profileStatEchoTitle,
            subtitle: l10n.profileStatEchoSubtitle,
            textTheme: tt,
            tokens: t,
          ),
        ),
        SizedBox(width: t.space12),
        Expanded(
          child: _ProfileStatTile(
            value: stats.recordedPracticeMinutes.toString(),
            title: l10n.profileStatRecordTitle,
            subtitle: l10n.profileStatRecordSubtitle,
            textTheme: tt,
            tokens: t,
          ),
        ),
      ],
    );
  }
}

class _ProfileStatTile extends StatelessWidget {
  const _ProfileStatTile({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.textTheme,
    required this.tokens,
  });

  final String value;
  final String title;
  final String subtitle;
  final TextTheme textTheme;
  final EnjoyThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    return EnjoyCard(
      padding: EdgeInsets.all(tokens.space12),
      child: Semantics(
        container: true,
        label: '$title, $value, $subtitle',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: tokens.space4),
            Text(
              title,
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
    final label = tier == SubscriptionTier.pro
        ? l10n.profileSubscriptionPro
        : l10n.profileSubscriptionFree;
    return Chip(
      label: Text(label),
      backgroundColor: cs.secondaryContainer,
      side: BorderSide.none,
    );
  }
}
