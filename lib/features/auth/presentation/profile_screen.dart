/// View and edit the signed-in Enjoy profile.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/auth/domain/update_profile_request.dart';
import 'package:enjoy_player/features/auth/domain/user_profile.dart';
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
  late final TextEditingController _learning;
  late final TextEditingController _native;
  bool _saving = false;
  String? _hydratedForProfileId;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _goal = TextEditingController();
    _learning = TextEditingController();
    _native = TextEditingController();
  }

  @override
  void dispose() {
    _name.dispose();
    _goal.dispose();
    _learning.dispose();
    _native.dispose();
    super.dispose();
  }

  void _applyProfile(UserProfile p) {
    _name.text = p.name;
    _goal.text = p.goal?.toString() ?? '';
    _learning.text = p.learningLanguage ?? '';
    _native.text = p.nativeLanguage ?? '';
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
              TextButton(
                onPressed: _saving
                    ? null
                    : () async {
                        setState(() => _saving = true);
                        try {
                          await ref.read(authCtrlProvider.notifier).signOut();
                          if (context.mounted) context.go('/');
                        } finally {
                          if (mounted) setState(() => _saving = false);
                        }
                      },
                child: Text(l10n.authSignOut),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
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
                Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundImage:
                          p.avatarUrl != null && p.avatarUrl!.isNotEmpty
                              ? NetworkImage(p.avatarUrl!)
                              : null,
                      child: p.avatarUrl == null || p.avatarUrl!.isEmpty
                          ? Icon(Icons.person_rounded, size: 40, color: cs.primary)
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
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                          ),
                          SizedBox(height: t.space8),
                          _SubscriptionChip(tier: p.subscriptionTier),
                        ],
                      ),
                    ),
                  ],
                ),
                if (p.balance != null) ...[
                  SizedBox(height: t.space12),
                  Text(
                    l10n.profileBalance(p.balance!.toStringAsFixed(2)),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                SizedBox(height: t.space24),
                Form(
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
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? l10n.profileFieldRequired : null,
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
                      TextFormField(
                        controller: _learning,
                        decoration: InputDecoration(
                          labelText: l10n.profileFieldLearningLanguage,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: t.space16),
                      TextFormField(
                        controller: _native,
                        decoration: InputDecoration(
                          labelText: l10n.profileFieldNativeLanguage,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: t.space24),
                      FilledButton(
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
                                  await ref.read(authCtrlProvider.notifier).updateProfile(
                                        UpdateProfileRequest(
                                          name: _name.text.trim(),
                                          goal: goal,
                                          learningLanguage: _learning.text.trim().isEmpty
                                              ? null
                                              : _learning.text.trim(),
                                          nativeLanguage: _native.text.trim().isEmpty
                                              ? null
                                              : _native.text.trim(),
                                        ),
                                      );
                                  final after = ref.read(authCtrlProvider).valueOrNull;
                                  if (after is AuthSignedIn) {
                                    _applyProfile(after.profile);
                                  }
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(l10n.profileSaveSuccess)),
                                    );
                                  }
                                } finally {
                                  if (mounted) setState(() => _saving = false);
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
              ],
            ),
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.profileTitle)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(l10n.profileTitle)),
        body: Center(child: Text('$e')),
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
