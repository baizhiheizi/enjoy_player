/// Voice picker dropdown for the synthesize tool (Azure Neural voices).
library;

import 'package:flutter/material.dart';

import 'package:enjoy_player/features/craft/domain/azure_voice.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class VoicePicker extends StatelessWidget {
  const VoicePicker({
    super.key,
    required this.language,
    required this.selectedVoice,
    required this.onChanged,
  });

  final String language;
  final String? selectedVoice;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final baseLang = language.split('-').first.toLowerCase();
    final voices = voicesForLanguage(baseLang);

    return Row(
      children: [
        Text(
          l10n.craftVoiceLabel,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: voices.isEmpty
              ? Text(
                  l10n.craftNoVoicesForLanguage,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                )
              : DropdownButton<String>(
                  value: selectedVoice,
                  isExpanded: true,
                  items: voices.map((v) {
                    return DropdownMenuItem(value: v.id, child: Text(v.label));
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) onChanged(v);
                  },
                ),
        ),
      ],
    );
  }
}
