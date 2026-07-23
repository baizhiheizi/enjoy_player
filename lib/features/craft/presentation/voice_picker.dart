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
    final theme = Theme.of(context);
    final baseLang = language.split('-').first.toLowerCase();
    final voices = voicesForLanguage(baseLang);
    // DropdownButton asserts if [value] is non-null and missing from [items]
    // (e.g. session kept a zh voice while Express target is en).
    final effectiveVoice =
        selectedVoice != null && voices.any((v) => v.id == selectedVoice)
        ? selectedVoice
        : null;

    return Row(
      children: [
        Icon(
          Icons.record_voice_over_rounded,
          size: 18,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          l10n.craftVoiceLabel,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: voices.isEmpty
              ? Text(
                  l10n.craftNoVoicesForLanguage,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: effectiveVoice,
                    hint: Text(
                      defaultVoiceForLanguage(baseLang)?.label ??
                          l10n.craftVoiceLabel,
                      overflow: TextOverflow.ellipsis,
                    ),
                    isExpanded: true,
                    borderRadius: BorderRadius.circular(12),
                    items: voices.map((v) {
                      return DropdownMenuItem(
                        value: v.id,
                        child: Text(v.label, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) onChanged(v);
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
