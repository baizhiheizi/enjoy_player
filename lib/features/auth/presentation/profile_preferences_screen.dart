/// Edit profile preferences: name, daily goal, display/learning/native language.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/application/app_language_catalog.dart';
import 'package:enjoy_player/core/application/app_preferences_provider.dart';
import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/presentation/language_labels.dart';
import 'package:enjoy_player/core/presentation/loading_icon.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/domain/update_profile_request.dart';
import 'package:enjoy_player/features/auth/domain/user_profile.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class ProfilePreferencesScreen extends ConsumerStatefulWidget {
  const ProfilePreferencesScreen({super.key});

  @override
  ConsumerState<ProfilePreferencesScreen> createState() =>
      _ProfilePreferencesScreenState();
}

class _ProfilePreferencesScreenState
    extends ConsumerState<ProfilePreferencesScreen> {
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final auth = ref.watch(authCtrlProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileSectionPreferences)),
      body: auth.when(
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

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              t.space24,
              t.space16,
              t.space24,
              t.space32,
            ),
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
                  SizedBox(height: t.space24),
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
                          child: const LinearProgressIndicator(),
                        ),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                  SizedBox(height: t.space32),
                  EnjoyButton.primary(
                    onPressed: _saving
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) return;
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
                              if (mounted) setState(() => _saving = false);
                            }
                          },
                    child: _saving
                        ? const LoadingIcon(size: 22)
                        : Text(l10n.profileSave),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.errorGenericLoadFailed)),
      ),
    );
  }
}
