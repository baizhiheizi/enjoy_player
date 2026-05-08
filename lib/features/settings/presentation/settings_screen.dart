/// Settings with grouped sections (modern minimal layout).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/data/api/api_client_provider.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/hotkeys/presentation/hotkeys_settings_section.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          _SectionLabel(text: l10n.settingsSectionAccount),
          Consumer(
            builder: (context, ref, _) {
              final auth = ref.watch(authCtrlProvider);
              return auth.when(
                data: (state) {
                  if (state is AuthSignedIn) {
                    return ListTile(
                      leading: Icon(Icons.person_outline_rounded, color: cs.primary),
                      title: Text(state.profile.name, style: tt.titleMedium),
                      subtitle: Text(
                        state.profile.email,
                        style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push('/profile'),
                    );
                  }
                  return ListTile(
                    leading: Icon(Icons.login_rounded, color: cs.primary),
                    title: Text(l10n.settingsAccountSignIn, style: tt.titleMedium),
                    subtitle: Text(
                      l10n.settingsAccountSignedOut,
                      style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    onTap: () => context.push('/sign-in'),
                  );
                },
                loading: () => ListTile(
                  leading: const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  title: Text(AppLocalizations.of(context)!.loading),
                ),
                error: (Object e, StackTrace s) => const SizedBox.shrink(),
              );
            },
          ),
          SizedBox(height: t.space8),
          _SectionLabel(text: l10n.settingsSectionAppearance),
          ListTile(
            leading: Icon(Icons.palette_outlined, color: cs.primary),
            title: Text(l10n.settingsThemeRowTitle, style: tt.titleMedium),
            subtitle: Text(
              l10n.settingsThemeDarkLocked,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          SizedBox(height: t.space8),
          _SectionLabel(text: l10n.hotkeysSectionKeyboard),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: t.space16),
            child: const HotkeysSettingsSection(),
          ),
          SizedBox(height: t.space8),
          _SectionLabel(text: l10n.settingsSectionAdvanced),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _ApiBaseUrlEditor(),
          ),
          SizedBox(height: t.space8),
          _SectionLabel(text: l10n.settingsSectionAbout),
          ListTile(
            leading: Icon(Icons.info_outline_rounded, color: cs.primary),
            title: Text(l10n.appTitle, style: tt.titleMedium),
            subtitle: Text(
              l10n.settingsAboutSubtitle,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.4),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(t.space16, t.space24, t.space16, 0),
            child: Text(
              l10n.settingsPlaceholder,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApiBaseUrlEditor extends ConsumerStatefulWidget {
  const _ApiBaseUrlEditor();

  @override
  ConsumerState<_ApiBaseUrlEditor> createState() => _ApiBaseUrlEditorState();
}

class _ApiBaseUrlEditorState extends ConsumerState<_ApiBaseUrlEditor> {
  late final TextEditingController _controller;
  bool _loaded = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final url = await ref.read(apiBaseUrlProvider.future);
      if (mounted) {
        _controller.text = url;
        setState(() => _loaded = true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          enabled: _loaded && !_saving,
          decoration: InputDecoration(
            labelText: l10n.settingsApiBaseUrl,
            hintText: l10n.settingsApiBaseUrlHint,
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.url,
          autocorrect: false,
        ),
        SizedBox(height: t.space12),
        FilledButton(
          onPressed: (!_loaded || _saving)
              ? null
              : () async {
                  setState(() => _saving = true);
                  try {
                    await ref
                        .read(apiBaseUrlProvider.notifier)
                        .setBaseUrl(_controller.text);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.settingsApiBaseUrlSave)),
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
              : Text(l10n.settingsApiBaseUrlSave),
        ),
        SizedBox(height: t.space8),
        Text(
          l10n.settingsApiBaseUrlHint,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(t.space16, t.space24, t.space16, t.space8),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 1.05,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
      ),
    );
  }
}
