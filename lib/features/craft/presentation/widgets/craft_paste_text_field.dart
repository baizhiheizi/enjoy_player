/// Multiline text input for craft tools with paste affordance and themed border.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/features/craft/presentation/widgets/craft_field_border.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class CraftPasteTextField extends StatelessWidget {
  const CraftPasteTextField({
    required this.controller,
    required this.labelText,
    this.hintText,
    this.onChanged,
    this.minLines = 3,
    this.maxLines = 5,
    super.key,
  });

  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final int minLines;
  final int maxLines;

  Future<void> _paste(BuildContext context) async {
    final clip = await Clipboard.getData('text/plain');
    if (!context.mounted) return;
    final text = clip?.text;
    if (text != null && text.isNotEmpty) {
      controller.text = text;
      onChanged?.call(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = EnjoyThemeTokens.of(context);
    final l10n = AppLocalizations.of(context)!;

    return TextField(
      controller: controller,
      maxLines: maxLines,
      minLines: minLines,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        border: craftFieldBorder(tokens),
        enabledBorder: craftFieldBorder(tokens),
        focusedBorder: craftFieldBorder(tokens, focused: true),
        suffixIcon: EnjoyIconButton(
          icon: EnjoyIcons.paste,
          tooltip: l10n.craftPasteFromClipboard,
          variant: EnjoyButtonVariant.ghost,
          size: 32,
          onPressed: () => _paste(context),
        ),
      ),
      onChanged: onChanged,
    );
  }
}
