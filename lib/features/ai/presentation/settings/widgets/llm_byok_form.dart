import 'package:flutter/material.dart';

import 'package:enjoy_player/core/presentation/form_section_label.dart';
import 'package:enjoy_player/core/presentation/loading_icon.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/ai/data/byok/byok_openai_models.dart';
import 'package:enjoy_player/features/ai/domain/llm_api_spec.dart';
import 'package:enjoy_player/features/ai/presentation/settings/llm_presets.dart';
import 'package:enjoy_player/features/ai/presentation/settings/widgets/byok_api_key_field.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class LlmByokForm extends StatefulWidget {
  const LlmByokForm({
    super.key,
    required this.apiSpec,
    required this.baseUrlController,
    required this.apiKeyController,
    required this.modelController,
    required this.hasExistingKey,
    this.presetId,
    this.onSpecChanged,
    this.onPresetSelected,
    this.maskedApiKeyPreview,
  });

  final LlmApiSpec apiSpec;
  final TextEditingController baseUrlController;
  final TextEditingController apiKeyController;
  final TextEditingController modelController;
  final bool hasExistingKey;
  final String? presetId;
  final ValueChanged<LlmApiSpec>? onSpecChanged;
  final ValueChanged<LlmPreset>? onPresetSelected;
  final String? maskedApiKeyPreview;

  @override
  State<LlmByokForm> createState() => _LlmByokFormState();
}

class _LlmByokFormState extends State<LlmByokForm> {
  bool _fetchingModels = false;
  String? _fetchModelsError;
  List<String> _fetchedModels = const [];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final presets = presetsForSpec(widget.apiSpec);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormSectionLabel(
          icon: Icons.hub_outlined,
          text: l10n.settingsAiProvidersLlmSpecLabel,
        ),
        SizedBox(height: t.space8),
        SegmentedButton<LlmApiSpec>(
          segments: [
            ButtonSegment(
              value: LlmApiSpec.openAiCompatible,
              label: Text(l10n.settingsAiProvidersLlmSpecOpenAi),
            ),
            ButtonSegment(
              value: LlmApiSpec.anthropicCompatible,
              label: Text(l10n.settingsAiProvidersLlmSpecAnthropic),
            ),
            ButtonSegment(
              value: LlmApiSpec.googleCompatible,
              label: Text(l10n.settingsAiProvidersLlmSpecGoogle),
            ),
          ],
          selected: {widget.apiSpec},
          onSelectionChanged: (selected) {
            final spec = selected.first;
            widget.onSpecChanged?.call(spec);
          },
          style: SegmentedButton.styleFrom(
            visualDensity: VisualDensity.comfortable,
            selectedBackgroundColor: cs.primaryContainer.withValues(
              alpha: 0.55,
            ),
            selectedForegroundColor: cs.onPrimaryContainer,
            foregroundColor: cs.onSurfaceVariant,
            side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.32)),
          ),
        ),
        SizedBox(height: t.space16),
        if (presets.isNotEmpty) ...[
          FormSectionLabel(
            icon: Icons.bolt_outlined,
            text: l10n.settingsAiProvidersPresetsLabel,
          ),
          SizedBox(height: t.space8),
          Wrap(
            spacing: t.space8,
            runSpacing: t.space8,
            children: [
              for (final preset in presets)
                FilterChip(
                  label: Text(preset.label),
                  selected: widget.presetId == preset.id,
                  onSelected: (_) => widget.onPresetSelected?.call(preset),
                  showCheckmark: false,
                  side: BorderSide(
                    color: widget.presetId == preset.id
                        ? cs.primary.withValues(alpha: 0.38)
                        : cs.outlineVariant.withValues(alpha: 0.22),
                  ),
                  backgroundColor: cs.surfaceContainerHighest.withValues(
                    alpha: 0.22,
                  ),
                  selectedColor: cs.primaryContainer.withValues(alpha: 0.48),
                ),
            ],
          ),
          SizedBox(height: t.space16),
        ],
        TextFormField(
          key: const Key('llm_byok_base_url'),
          controller: widget.baseUrlController,
          decoration: InputDecoration(
            labelText: l10n.settingsAiProvidersBaseUrlLabel,
            hintText: l10n.settingsAiProvidersBaseUrlHint,
          ),
          keyboardType: TextInputType.url,
          autofillHints: const [AutofillHints.url],
        ),
        SizedBox(height: t.space12),
        ByokApiKeyField(
          controller: widget.apiKeyController,
          hasExistingKey: widget.hasExistingKey,
          labelText: l10n.settingsAiProvidersApiKeyLabel,
          maskedPreview: widget.maskedApiKeyPreview,
        ),
        SizedBox(height: t.space12),
        TextFormField(
          controller: widget.modelController,
          decoration: InputDecoration(
            labelText: l10n.settingsAiProvidersModelLabel,
          ),
        ),
        if (widget.apiSpec == LlmApiSpec.openAiCompatible) ...[
          SizedBox(height: t.space12),
          DecoratedBox(
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(t.radiusMd),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.18),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(t.space12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.settingsAiProvidersFetchedModelsLabel,
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                  ),
                  SizedBox(width: t.space12),
                  OutlinedButton.icon(
                    onPressed: _fetchingModels ? null : _fetchModels,
                    icon: _fetchingModels
                        ? const LoadingIcon(size: 16)
                        : const Icon(Icons.list_outlined),
                    label: Text(l10n.settingsAiProvidersFetchModels),
                  ),
                ],
              ),
            ),
          ),
          if (_fetchModelsError != null) ...[
            SizedBox(height: t.space8),
            Text(
              _fetchModelsError!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
          if (_fetchedModels.isNotEmpty) ...[
            SizedBox(height: t.space8),
            DropdownButtonFormField<String>(
              initialValue: _fetchedModels.contains(widget.modelController.text)
                  ? widget.modelController.text
                  : null,
              decoration: InputDecoration(
                labelText: l10n.settingsAiProvidersFetchedModelsLabel,
              ),
              items: [
                for (final id in _fetchedModels)
                  DropdownMenuItem(value: id, child: Text(id)),
              ],
              onChanged: (value) {
                if (value != null) {
                  widget.modelController.text = value;
                }
              },
            ),
          ],
        ],
      ],
    );
  }

  Future<void> _fetchModels() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _fetchingModels = true;
      _fetchModelsError = null;
    });

    try {
      final models = await fetchOpenAiCompatibleModels(
        baseUrl: widget.baseUrlController.text,
        apiKey: widget.apiKeyController.text,
      );
      if (!mounted) return;
      setState(() {
        _fetchedModels = models;
        if (models.isEmpty) {
          _fetchModelsError = l10n.settingsAiProvidersFetchModelsEmpty;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _fetchModelsError = l10n.settingsAiProvidersFetchModelsFailed;
        _fetchedModels = const [];
      });
    } finally {
      if (mounted) {
        setState(() => _fetchingModels = false);
      }
    }
  }
}
