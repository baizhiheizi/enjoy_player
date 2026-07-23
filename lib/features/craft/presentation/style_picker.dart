/// Style picker dropdown for the translate tool.
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/features/craft/domain/translation_style.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class StylePicker extends StatelessWidget {
  const StylePicker({super.key, required this.value, required this.onChanged});

  final TranslationStyle value;
  final void Function(TranslationStyle) onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Text(
          l10n.craftStyleLabel,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButton<TranslationStyle>(
            value: value,
            isExpanded: true,
            items: TranslationStyle.values.map((style) {
              return DropdownMenuItem(
                value: style,
                child: Text(_label(l10n, style)),
              );
            }).toList(),
            onChanged: (s) {
              if (s != null) onChanged(s);
            },
          ),
        ),
      ],
    );
  }

  String _label(AppLocalizations l10n, TranslationStyle style) {
    return switch (style) {
      TranslationStyle.auto => l10n.craftStyleAuto,
      TranslationStyle.literal => l10n.craftStyleLiteral,
      TranslationStyle.natural => l10n.craftStyleNatural,
      TranslationStyle.casual => l10n.craftStyleCasual,
      TranslationStyle.formal => l10n.craftStyleFormal,
      TranslationStyle.simplified => l10n.craftStyleSimplified,
      TranslationStyle.detailed => l10n.craftStyleDetailed,
      TranslationStyle.custom => l10n.craftStyleCustom,
    };
  }
}
