/// Developer row body — API base URL editors + AI playground (debug builds only).
///
/// Extracted 1:1 from `settings_screen.dart`'s Developer block
/// (`_ApiBaseUrlEditor`/`_AiApiBaseUrlEditor`). Non-release-build gating
/// (FR-005) is enforced by the caller, not this widget.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/presentation/loading_icon.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/data/api/api_client_provider.dart';
import 'package:enjoy_player/features/settings/presentation/widgets/settings_row.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class DeveloperSectionBody extends StatelessWidget {
  const DeveloperSectionBody({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.symmetric(
              horizontal: t.space20,
              vertical: t.space8,
            ),
            childrenPadding: EdgeInsets.fromLTRB(
              t.space20,
              t.space16,
              t.space16,
              t.space16,
            ),
            leading: const _ExpansionLeading(icon: Icons.dns_outlined),
            title: Text(
              l10n.settingsApiBaseUrl,
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              l10n.settingsApiBaseUrlHint,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            children: const [_ApiBaseUrlEditor()],
          ),
        ),
        const SettingsRowDivider(insetForLeading: false),
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.symmetric(
              horizontal: t.space20,
              vertical: t.space8,
            ),
            childrenPadding: EdgeInsets.fromLTRB(
              t.space20,
              t.space16,
              t.space16,
              t.space16,
            ),
            leading: const _ExpansionLeading(icon: Icons.smart_toy_outlined),
            title: Text(
              l10n.settingsAiApiBaseUrl,
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              l10n.settingsAiApiBaseUrlHint,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            children: const [_AiApiBaseUrlEditor()],
          ),
        ),
        const SettingsRowDivider(insetForLeading: false),
        SettingsRow(
          leadingIcon: Icons.science_outlined,
          title: l10n.settingsAiPlaygroundTileTitle,
          subtitle: l10n.settingsAiPlaygroundTileSubtitle,
          onTap: () => context.push('/settings/ai-playground'),
        ),
      ],
    );
  }
}

class _ExpansionLeading extends StatelessWidget {
  const _ExpansionLeading({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 44,
      height: 44,
      child: Center(
        child: Icon(icon, color: cs.primary.withValues(alpha: 0.92), size: 22),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          enabled: _loaded && !_saving,
          decoration: InputDecoration(hintText: l10n.settingsApiBaseUrlHint),
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
                      AppNotice.success(context, l10n.settingsApiBaseUrlSave);
                    }
                  } finally {
                    if (mounted) setState(() => _saving = false);
                  }
                },
          child: _saving
              ? const LoadingIcon(size: 20)
              : Text(l10n.settingsApiBaseUrlSave),
        ),
      ],
    );
  }
}

class _AiApiBaseUrlEditor extends ConsumerStatefulWidget {
  const _AiApiBaseUrlEditor();

  @override
  ConsumerState<_AiApiBaseUrlEditor> createState() =>
      _AiApiBaseUrlEditorState();
}

class _AiApiBaseUrlEditorState extends ConsumerState<_AiApiBaseUrlEditor> {
  late final TextEditingController _controller;
  bool _loaded = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final url = await ref.read(aiApiBaseUrlProvider.future);
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          enabled: _loaded && !_saving,
          decoration: InputDecoration(hintText: l10n.settingsAiApiBaseUrlHint),
          keyboardType: TextInputType.url,
          autocorrect: false,
        ),
        SizedBox(height: t.space12),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: (!_loaded || _saving)
                    ? null
                    : () async {
                        setState(() => _saving = true);
                        try {
                          await ref
                              .read(aiApiBaseUrlProvider.notifier)
                              .setBaseUrl(_controller.text);
                          if (context.mounted) {
                            AppNotice.success(
                              context,
                              l10n.settingsAiApiBaseUrlSave,
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _saving = false);
                        }
                      },
                child: _saving
                    ? const LoadingIcon(size: 20)
                    : Text(l10n.settingsAiApiBaseUrlSave),
              ),
            ),
            SizedBox(width: t.space8),
            Expanded(
              child: OutlinedButton(
                onPressed: (!_loaded || _saving)
                    ? null
                    : () async {
                        setState(() => _saving = true);
                        try {
                          await ref
                              .read(aiApiBaseUrlProvider.notifier)
                              .clearOverride();
                          final url = await ref.read(
                            aiApiBaseUrlProvider.future,
                          );
                          if (mounted) {
                            _controller.text = url;
                          }
                          if (context.mounted) {
                            AppNotice.success(
                              context,
                              l10n.settingsAiApiBaseUrlCleared,
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _saving = false);
                        }
                      },
                child: Text(l10n.settingsAiApiBaseUrlUseDefault),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
