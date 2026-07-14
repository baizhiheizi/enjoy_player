import 'package:flutter/material.dart';

import 'package:enjoy_player/core/presentation/form_section_label.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/ai/domain/speech_byok_kind.dart';
import 'package:enjoy_player/features/ai/presentation/settings/widgets/byok_api_key_field.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

enum SpeechByokFormMode {
  /// Azure subscription key + region only (assessment).
  assessment,

  /// OpenAI Whisper or Azure Speech (ASR / TTS).
  speech,
}

/// Speech BYOK fields for assessment (Azure) or ASR/TTS (OpenAI vs Azure).
class SpeechByokForm extends StatefulWidget {
  const SpeechByokForm({
    super.key,
    required this.mode,
    required this.apiKeyController,
    required this.regionController,
    required this.hasExistingKey,
    this.kind = SpeechByokKind.openAiCompatible,
    this.baseUrlController,
    this.modelController,
    this.maskedApiKeyPreview,
    this.onKindChanged,
    this.modelLabelText,
    this.modelHintText,
  });

  final SpeechByokFormMode mode;
  final SpeechByokKind kind;
  final TextEditingController apiKeyController;
  final TextEditingController regionController;
  final TextEditingController? baseUrlController;
  final TextEditingController? modelController;
  final bool hasExistingKey;
  final String? maskedApiKeyPreview;
  final ValueChanged<SpeechByokKind>? onKindChanged;
  final String? modelLabelText;
  final String? modelHintText;

  bool get _isAzure =>
      mode == SpeechByokFormMode.assessment ||
      (mode == SpeechByokFormMode.speech && kind == SpeechByokKind.azureSpeech);

  @override
  State<SpeechByokForm> createState() => _SpeechByokFormState();
}

class _SpeechByokFormState extends State<SpeechByokForm> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final apiKeyLabel = widget._isAzure
        ? l10n.settingsAiProvidersSpeechSubscriptionKeyLabel
        : l10n.settingsAiProvidersApiKeyLabel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.mode == SpeechByokFormMode.speech) ...[
          FormSectionLabel(
            icon: Icons.route_outlined,
            text: l10n.settingsAiProvidersSpeechKindLabel,
          ),
          SizedBox(height: t.space8),
          SegmentedButton<SpeechByokKind>(
            segments: [
              ButtonSegment(
                value: SpeechByokKind.openAiCompatible,
                label: Text(l10n.settingsAiProvidersSpeechKindOpenAi),
              ),
              ButtonSegment(
                value: SpeechByokKind.azureSpeech,
                label: Text(l10n.settingsAiProvidersSpeechKindAzure),
              ),
            ],
            selected: {widget.kind},
            onSelectionChanged: (selected) {
              widget.onKindChanged?.call(selected.first);
            },
            style: SegmentedButton.styleFrom(
              visualDensity: VisualDensity.comfortable,
              selectedBackgroundColor: cs.primaryContainer.withValues(
                alpha: 0.55,
              ),
              selectedForegroundColor: cs.onPrimaryContainer,
              foregroundColor: cs.onSurfaceVariant,
              side: BorderSide(
                color: cs.outlineVariant.withValues(alpha: 0.32),
              ),
            ),
          ),
          SizedBox(height: t.space16),
        ],
        if (!widget._isAzure && widget.baseUrlController != null) ...[
          TextField(
            controller: widget.baseUrlController,
            decoration: InputDecoration(
              labelText: l10n.settingsAiProvidersBaseUrlLabel,
              hintText: l10n.settingsAiProvidersBaseUrlHint,
            ),
            keyboardType: TextInputType.url,
            autocorrect: false,
          ),
          SizedBox(height: t.space12),
        ],
        ByokApiKeyField(
          controller: widget.apiKeyController,
          hasExistingKey: widget.hasExistingKey,
          labelText: apiKeyLabel,
          maskedPreview: widget.maskedApiKeyPreview,
        ),
        if (!widget._isAzure && widget.modelController != null) ...[
          SizedBox(height: t.space12),
          TextField(
            controller: widget.modelController,
            decoration: InputDecoration(
              labelText:
                  widget.modelLabelText ??
                  l10n.settingsAiProvidersSpeechWhisperModelLabel,
              hintText:
                  widget.modelHintText ??
                  l10n.settingsAiProvidersSpeechWhisperModelHint,
            ),
          ),
        ],
        if (widget._isAzure) ...[
          SizedBox(height: t.space12),
          TextField(
            controller: widget.regionController,
            decoration: InputDecoration(
              labelText: l10n.settingsAiProvidersSpeechRegionLabel,
              hintText: l10n.settingsAiProvidersSpeechRegionHint,
            ),
            textCapitalization: TextCapitalization.none,
            autocorrect: false,
          ),
        ],
      ],
    );
  }
}
