/// Developer row body — API base URL editors + AI playground (debug builds only).
///
/// Extracted 1:1 from `settings_screen.dart`'s Developer block. Non-release-
/// build gating (FR-005) is enforced by the caller, not this widget.
library;

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/presentation/loading_icon.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_icon_tile.dart';
import 'package:enjoy_player/data/api/api_client_provider.dart';
import 'package:enjoy_player/features/settings/presentation/widgets/settings_row.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class DeveloperSectionBody extends ConsumerWidget {
  const DeveloperSectionBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DeveloperExpansionTile(
          icon: EnjoyIcons.server,
          title: l10n.settingsApiBaseUrl,
          subtitle: l10n.settingsApiBaseUrlHint,
          children: [
            _BaseUrlEditor(
              hint: l10n.settingsApiBaseUrlHint,
              saveLabel: l10n.settingsApiBaseUrlSave,
              loadUrl: () => ref.read(apiBaseUrlProvider.future),
              saveUrl: (url) =>
                  ref.read(apiBaseUrlProvider.notifier).setBaseUrl(url),
            ),
          ],
        ),
        const SettingsRowDivider(),
        _DeveloperExpansionTile(
          icon: EnjoyIcons.robot,
          title: l10n.settingsAiApiBaseUrl,
          subtitle: l10n.settingsAiApiBaseUrlHint,
          children: [
            _BaseUrlEditor(
              hint: l10n.settingsAiApiBaseUrlHint,
              saveLabel: l10n.settingsAiApiBaseUrlSave,
              loadUrl: () => ref.read(aiApiBaseUrlProvider.future),
              saveUrl: (url) =>
                  ref.read(aiApiBaseUrlProvider.notifier).setBaseUrl(url),
              resetAction: _BaseUrlResetAction(
                label: l10n.settingsAiApiBaseUrlUseDefault,
                notice: l10n.settingsAiApiBaseUrlCleared,
                run: () async {
                  await ref.read(aiApiBaseUrlProvider.notifier).clearOverride();
                },
              ),
            ),
          ],
        ),
        const SettingsRowDivider(),
        SettingsRow(
          leadingIcon: EnjoyIcons.lab,
          title: l10n.settingsAiPlaygroundTileTitle,
          subtitle: l10n.settingsAiPlaygroundTileSubtitle,
          onTap: () => context.push('/settings/ai-playground'),
        ),
      ],
    );
  }
}

class _DeveloperExpansionTile extends StatelessWidget {
  const _DeveloperExpansionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(
          horizontal: kSettingsRowHorizontalPadding,
          vertical: t.space4,
        ),
        childrenPadding: EdgeInsets.fromLTRB(
          kSettingsRowHorizontalPadding,
          t.space8,
          kSettingsRowHorizontalPadding,
          t.space16,
        ),
        minTileHeight: 56,
        leading: _ExpansionLeading(icon: icon),
        title: Text(
          title,
          style: tt.titleMedium?.copyWith(
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        children: children,
      ),
    );
  }
}

class _ExpansionLeading extends StatelessWidget {
  const _ExpansionLeading({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return EnjoyIconTile(icon: icon, size: kSettingsRowLeadingSize);
  }
}

class _BaseUrlResetAction {
  const _BaseUrlResetAction({
    required this.label,
    required this.notice,
    required this.run,
  });

  final String label;
  final String notice;
  final Future<void> Function() run;
}

class _BaseUrlEditor extends ConsumerStatefulWidget {
  const _BaseUrlEditor({
    required this.hint,
    required this.saveLabel,
    required this.loadUrl,
    required this.saveUrl,
    this.resetAction,
  });

  final String hint;
  final String saveLabel;
  final Future<String> Function() loadUrl;
  final Future<void> Function(String url) saveUrl;

  /// Use-default/reset affordance; null on variants without an override.
  final _BaseUrlResetAction? resetAction;

  @override
  ConsumerState<_BaseUrlEditor> createState() => _BaseUrlEditorState();
}

class _BaseUrlEditorState extends ConsumerState<_BaseUrlEditor> {
  late final TextEditingController _controller;
  bool _loaded = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final url = await widget.loadUrl();
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

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.saveUrl(_controller.text);
      if (mounted) {
        AppNotice.success(context, widget.saveLabel);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _reset() async {
    final action = widget.resetAction!;
    setState(() => _saving = true);
    try {
      await action.run();
      final url = await widget.loadUrl();
      if (mounted) {
        _controller.text = url;
      }
      if (mounted) {
        AppNotice.success(context, action.notice);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final action = widget.resetAction;
    final saveButton = FilledButton(
      onPressed: (!_loaded || _saving) ? null : _save,
      child: _saving ? const LoadingIcon(size: 20) : Text(widget.saveLabel),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          enabled: _loaded && !_saving,
          decoration: InputDecoration(hintText: widget.hint),
          keyboardType: TextInputType.url,
          autocorrect: false,
        ),
        SizedBox(height: t.space12),
        if (action == null)
          saveButton
        else
          Row(
            children: [
              Expanded(child: saveButton),
              SizedBox(width: t.space8),
              Expanded(
                child: OutlinedButton(
                  onPressed: (!_loaded || _saving) ? null : _reset,
                  child: Text(action.label),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
