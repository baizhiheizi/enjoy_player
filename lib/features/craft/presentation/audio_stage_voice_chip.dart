import 'package:flutter/material.dart';

import 'package:enjoy_player/core/interaction/enjoy_pressable.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_card.dart';
import 'package:enjoy_player/features/craft/domain/azure_voice.dart';
import 'package:enjoy_player/features/craft/presentation/voice_picker.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Maps an Azure voice id to its display label, falling back to the id itself.
String? voiceDisplayLabel(String? voiceId) {
  if (voiceId == null || voiceId.isEmpty) return null;
  for (final v in kAzureVoices) {
    if (v.id == voiceId) return v.label;
  }
  return voiceId;
}

class AudioStageVoiceChip extends StatelessWidget {
  const AudioStageVoiceChip({
    super.key,
    required this.expanded,
    required this.synthLanguage,
    required this.selectedVoice,
    required this.voiceLabel,
    required this.theme,
    required this.onToggle,
    required this.onVoiceChanged,
  });

  final bool expanded;
  final String synthLanguage;
  final String? selectedVoice;
  final String? voiceLabel;
  final ThemeData theme;
  final VoidCallback onToggle;
  final void Function(String) onVoiceChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final scheme = theme.colorScheme;
    return EnjoyCard(
      elevated: false,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EnjoyPressable(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(t.radiusMd),
            pressedScale: 0.995,
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: t.space8,
                horizontal: t.space12,
              ),
              child: Row(
                children: [
                  Icon(EnjoyIcons.speak, size: 18, color: t.brandInk),
                  SizedBox(width: t.space8),
                  Text(
                    l10n.craftVoiceLabel,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: t.space8),
                  Expanded(
                    child: Text(
                      voiceLabel ?? l10n.craftVoiceLabel,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                  ),
                  SizedBox(width: t.space4),
                  Icon(
                    expanded ? EnjoyIcons.chevronUp : EnjoyIcons.chevronDown,
                    size: 18,
                    color: t.ink3,
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            Padding(
              padding: EdgeInsets.fromLTRB(t.space12, 0, t.space12, t.space12),
              child: VoicePicker(
                language: synthLanguage,
                selectedVoice: selectedVoice,
                onChanged: onVoiceChanged,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
