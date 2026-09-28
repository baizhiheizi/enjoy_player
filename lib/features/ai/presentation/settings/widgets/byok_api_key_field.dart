import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:flutter/material.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// API key field with masked saved state and explicit edit toggle.
class ByokApiKeyField extends StatefulWidget {
  const ByokApiKeyField({
    super.key,
    required this.controller,
    required this.hasExistingKey,
    required this.labelText,
    this.maskedPreview,
  });

  final TextEditingController controller;
  final bool hasExistingKey;
  final String labelText;
  final String? maskedPreview;

  @override
  State<ByokApiKeyField> createState() => _ByokApiKeyFieldState();
}

class _ByokApiKeyFieldState extends State<ByokApiKeyField> {
  bool _showApiKey = false;
  bool _editing = false;

  @override
  void didUpdateWidget(covariant ByokApiKeyField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.hasExistingKey) {
      _editing = true;
    } else if (!oldWidget.hasExistingKey && widget.hasExistingKey) {
      _editing = false;
      widget.controller.clear();
    }
  }

  @override
  void initState() {
    super.initState();
    _editing = !widget.hasExistingKey;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (widget.hasExistingKey && !_editing) {
      final preview =
          widget.maskedPreview ?? l10n.settingsAiProvidersApiKeySavedMask;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.labelText, style: tt.labelLarge),
          SizedBox(height: t.space8),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: cs.outlineVariant),
              borderRadius: BorderRadius.circular(t.radiusMd),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: t.space12,
                vertical: t.space12,
              ),
              child: Row(
                children: [
                  Icon(EnjoyIcons.lock, size: 18, color: cs.onSurfaceVariant),
                  SizedBox(width: t.space8),
                  Expanded(
                    child: Text(
                      preview,
                      style: tt.bodyMedium?.copyWith(
                        fontFamily: 'monospace',
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _editing = true),
                    child: Text(l10n.settingsAiProvidersApiKeyEdit),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return TextField(
      controller: widget.controller,
      obscureText: !_showApiKey,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hasExistingKey
            ? l10n.settingsAiProvidersApiKeyExistingHint
            : null,
        suffixIcon: IconButton(
          icon: Icon(_showApiKey ? EnjoyIcons.eyeOff : EnjoyIcons.eye),
          tooltip: _showApiKey
              ? l10n.settingsAiProvidersHideApiKey
              : l10n.settingsAiProvidersShowApiKey,
          onPressed: () => setState(() => _showApiKey = !_showApiKey),
        ),
      ),
      autofillHints: const [AutofillHints.password],
    );
  }
}
