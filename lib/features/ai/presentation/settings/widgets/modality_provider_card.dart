import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/presentation/loading_icon.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_modal.dart';
import 'package:enjoy_player/core/validation/byok_secret_mask.dart';
import 'package:enjoy_player/data/api/byok_secret_store.dart';
import 'package:enjoy_player/features/ai/application/ai_modality_config_controller.dart';
import 'package:enjoy_player/features/ai/domain/ai_provider.dart';
import 'package:enjoy_player/features/ai/domain/ai_service_config.dart';
import 'package:enjoy_player/features/ai/domain/llm_api_spec.dart';
import 'package:enjoy_player/features/ai/domain/modality_byok_config.dart';
import 'package:enjoy_player/features/ai/domain/modality_kind.dart';
import 'package:enjoy_player/features/ai/domain/speech_byok_kind.dart';
import 'package:enjoy_player/features/ai/presentation/settings/byok_validation_messages.dart';
import 'package:enjoy_player/features/ai/presentation/settings/widgets/llm_byok_form.dart';
import 'package:enjoy_player/features/ai/presentation/settings/widgets/speech_byok_form.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

class ModalityProviderCard extends ConsumerStatefulWidget {
  const ModalityProviderCard({
    super.key,
    required this.modality,
    required this.title,
    required this.subtitle,
    required this.config,
  });

  final ModalityKind modality;
  final String title;
  final String subtitle;
  final AIServiceConfig config;

  @override
  ConsumerState<ModalityProviderCard> createState() =>
      _ModalityProviderCardState();
}

class _ModalityProviderCardState extends ConsumerState<ModalityProviderCard> {
  late AIProvider _provider;
  late LlmApiSpec _apiSpec;
  late SpeechByokKind _speechKind;
  String? _presetId;
  final _baseUrlController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _modelController = TextEditingController();
  final _regionController = TextEditingController();
  bool _hasExistingKey = false;
  String? _maskedApiKeyPreview;
  bool _saving = false;

  bool get _supportsByokForm =>
      widget.modality == ModalityKind.llm ||
      widget.modality == ModalityKind.assessment ||
      widget.modality == ModalityKind.asr ||
      widget.modality == ModalityKind.tts;

  SpeechByokFormMode? get _speechFormMode => switch (widget.modality) {
    ModalityKind.assessment => SpeechByokFormMode.assessment,
    ModalityKind.asr || ModalityKind.tts => SpeechByokFormMode.speech,
    _ => null,
  };

  IconData get _modalityIcon => switch (widget.modality) {
    ModalityKind.llm => Icons.auto_awesome_outlined,
    ModalityKind.asr => Icons.graphic_eq_rounded,
    ModalityKind.tts => Icons.record_voice_over_outlined,
    ModalityKind.assessment => Icons.verified_outlined,
  };

  @override
  void initState() {
    super.initState();
    _applyConfig(widget.config);
    unawaited(_loadKeyHint());
  }

  @override
  void didUpdateWidget(covariant ModalityProviderCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config != widget.config) {
      _applyConfig(widget.config);
      unawaited(_loadKeyHint());
    }
  }

  void _applyConfig(AIServiceConfig config) {
    _provider = config.provider;
    final llm = config.llmByok;
    _apiSpec = llm?.apiSpec ?? LlmApiSpec.openAiCompatible;
    _presetId = llm?.presetId;
    _baseUrlController.text = llm?.baseUrl ?? '';
    _modelController.text = llm?.model ?? '';

    final speech = config.speechByok;
    _speechKind = speech?.kind ?? SpeechByokKind.openAiCompatible;
    if (speech != null && speech.baseUrl != null) {
      _baseUrlController.text = speech.baseUrl!;
    }
    if (speech != null && speech.model != null) {
      _modelController.text = speech.model!;
    }
    _regionController.text = speech?.region ?? '';
    _apiKeyController.clear();
  }

  Future<void> _loadKeyHint() async {
    final store = ref.read(byokSecretStoreProvider);
    final hasKey = await store.hasApiKey(widget.modality);
    String? preview;
    if (hasKey) {
      final key = await store.readApiKey(widget.modality);
      if (key != null && key.isNotEmpty) {
        preview = maskByokApiKey(key);
      }
    }
    if (mounted) {
      setState(() {
        _hasExistingKey = hasKey;
        _maskedApiKeyPreview = preview;
      });
    }
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    _modelController.dispose();
    _regionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final speechMode = _speechFormMode;

    return Material(
      elevation: 0,
      color: cs.surfaceContainerLow.withValues(alpha: 0.9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(t.radiusXl),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.22)),
      ),
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cs.surfaceContainerHigh.withValues(alpha: 0.34),
              cs.surfaceContainerLow.withValues(alpha: 0.04),
            ],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(t.space20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ModalityIcon(icon: _modalityIcon),
                  SizedBox(width: t.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.title,
                                style: tt.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                            SizedBox(width: t.space8),
                            _ProviderPill(
                              label: _provider == AIProvider.enjoy
                                  ? l10n.settingsAiProvidersEnjoyAi
                                  : l10n.settingsAiProvidersByok,
                              selected: _provider == AIProvider.byok,
                            ),
                          ],
                        ),
                        SizedBox(height: t.space4),
                        Text(
                          widget.subtitle,
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: t.space16),
              SegmentedButton<AIProvider>(
                segments: [
                  ButtonSegment(
                    value: AIProvider.enjoy,
                    icon: const Icon(Icons.cloud_done_outlined),
                    label: Text(l10n.settingsAiProvidersEnjoyAi),
                  ),
                  ButtonSegment(
                    value: AIProvider.byok,
                    icon: const Icon(Icons.key_outlined),
                    label: Text(l10n.settingsAiProvidersByok),
                  ),
                ],
                selected: {_provider},
                onSelectionChanged: _saving
                    ? null
                    : (selected) => setState(() => _provider = selected.first),
                style: SegmentedButton.styleFrom(
                  visualDensity: VisualDensity.comfortable,
                  selectedBackgroundColor: cs.primaryContainer.withValues(
                    alpha: 0.55,
                  ),
                  selectedForegroundColor: cs.onPrimaryContainer,
                  foregroundColor: cs.onSurfaceVariant,
                  side: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.38),
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: t.motionFast,
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: _provider == AIProvider.byok
                    ? Padding(
                        key: const ValueKey('byok-form'),
                        padding: EdgeInsets.only(top: t.space16),
                        child: _ByokPanel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (widget.modality == ModalityKind.llm)
                                LlmByokForm(
                                  apiSpec: _apiSpec,
                                  baseUrlController: _baseUrlController,
                                  apiKeyController: _apiKeyController,
                                  modelController: _modelController,
                                  hasExistingKey: _hasExistingKey,
                                  presetId: _presetId,
                                  maskedApiKeyPreview: _maskedApiKeyPreview,
                                  onSpecChanged: (spec) => setState(() {
                                    _apiSpec = spec;
                                    _presetId = null;
                                  }),
                                  onPresetSelected: (preset) => setState(() {
                                    _apiSpec = preset.apiSpec;
                                    _presetId = preset.id;
                                    _baseUrlController.text = preset.baseUrl;
                                    _modelController.text = preset.model;
                                  }),
                                ),
                              if (speechMode != null)
                                SpeechByokForm(
                                  mode: speechMode,
                                  kind: _speechKind,
                                  apiKeyController: _apiKeyController,
                                  regionController: _regionController,
                                  baseUrlController: _baseUrlController,
                                  modelController: _modelController,
                                  hasExistingKey: _hasExistingKey,
                                  maskedApiKeyPreview: _maskedApiKeyPreview,
                                  onKindChanged: (kind) =>
                                      setState(() => _speechKind = kind),
                                  modelLabelText:
                                      widget.modality == ModalityKind.tts
                                      ? l10n.settingsAiProvidersSpeechTtsModelLabel
                                      : null,
                                  modelHintText:
                                      widget.modality == ModalityKind.tts
                                      ? l10n.settingsAiProvidersSpeechTtsModelHint
                                      : null,
                                ),
                              if (!_supportsByokForm)
                                Text(
                                  l10n.settingsAiProvidersComingSoon,
                                  style: tt.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      )
                    : const SizedBox.shrink(key: ValueKey('enjoy-empty')),
              ),
              SizedBox(height: t.space16),
              Divider(
                height: 1,
                color: cs.outlineVariant.withValues(alpha: 0.2),
              ),
              SizedBox(height: t.space12),
              Row(
                children: [
                  Icon(
                    _provider == AIProvider.enjoy
                        ? Icons.cloud_done_outlined
                        : Icons.lock_outline_rounded,
                    size: 18,
                    color: cs.onSurfaceVariant,
                  ),
                  SizedBox(width: t.space8),
                  Expanded(
                    child: Text(
                      _provider == AIProvider.enjoy
                          ? l10n.settingsAiProvidersEnjoyAi
                          : l10n.settingsAiProvidersPrivacyNotice,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                  ),
                  if (widget.config.provider == AIProvider.byok) ...[
                    SizedBox(width: t.space12),
                    TextButton(
                      onPressed: _saving ? null : _confirmRemove,
                      child: Text(l10n.settingsAiProvidersRemoveByok),
                    ),
                  ],
                  SizedBox(width: t.space8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 132),
                    child: EnjoyButton.primary(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const LoadingIcon(size: 20)
                          : Text(l10n.settingsAiProvidersSave),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  AIServiceConfig _buildByokConfig() {
    return switch (widget.modality) {
      ModalityKind.llm => AIServiceConfig(
        provider: AIProvider.byok,
        llmByok: LlmByokConfig(
          apiSpec: _apiSpec,
          baseUrl: _baseUrlController.text.trim(),
          model: _modelController.text.trim(),
          presetId: _presetId,
        ),
      ),
      ModalityKind.assessment => AIServiceConfig(
        provider: AIProvider.byok,
        speechByok: SpeechByokConfig(
          kind: SpeechByokKind.azureSpeech,
          region: _regionController.text.trim(),
        ),
      ),
      ModalityKind.asr => AIServiceConfig(
        provider: AIProvider.byok,
        speechByok: _speechKind == SpeechByokKind.azureSpeech
            ? SpeechByokConfig(
                kind: SpeechByokKind.azureSpeech,
                region: _regionController.text.trim(),
              )
            : SpeechByokConfig(
                kind: SpeechByokKind.openAiCompatible,
                baseUrl: _baseUrlController.text.trim(),
                model: _modelController.text.trim(),
              ),
      ),
      ModalityKind.tts => AIServiceConfig(
        provider: AIProvider.byok,
        speechByok: _speechKind == SpeechByokKind.azureSpeech
            ? SpeechByokConfig(
                kind: SpeechByokKind.azureSpeech,
                region: _regionController.text.trim(),
              )
            : SpeechByokConfig(
                kind: SpeechByokKind.openAiCompatible,
                baseUrl: _baseUrlController.text.trim(),
                model: _modelController.text.trim(),
              ),
      ),
    };
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _saving = true);
    try {
      final config = _provider == AIProvider.enjoy
          ? const AIServiceConfig(provider: AIProvider.enjoy)
          : _buildByokConfig();

      final apiKey = _apiKeyController.text.trim();
      final result = await ref
          .read(aiModalityConfigCtrlProvider.notifier)
          .saveModality(
            modality: widget.modality,
            config: config,
            apiKey: apiKey.isEmpty ? null : apiKey,
          );

      if (!mounted) return;
      if (!result.isValid) {
        AppNotice.error(
          context,
          formatByokValidationErrors(l10n, result.errors),
        );
        return;
      }

      _apiKeyController.clear();
      await _loadKeyHint();
      if (!mounted) return;
      AppNotice.success(context, l10n.settingsAiProvidersSaveSuccess);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmRemove() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showEnjoyAlertDialog<bool>(
      context: context,
      title: Text(l10n.settingsAiProvidersRemoveByokTitle),
      content: Text(l10n.settingsAiProvidersRemoveByokBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.settingsAiProvidersCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.settingsAiProvidersRemoveByok),
        ),
      ],
    );
    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    try {
      await ref
          .read(aiModalityConfigCtrlProvider.notifier)
          .removeByok(widget.modality);
      if (!mounted) return;
      setState(() {
        _provider = AIProvider.enjoy;
        _apiKeyController.clear();
        _regionController.clear();
        _hasExistingKey = false;
        _maskedApiKeyPreview = null;
      });
      AppNotice.success(context, l10n.settingsAiProvidersRemoveByokSuccess);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _ModalityIcon extends StatelessWidget {
  const _ModalityIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(t.radiusMd),
        color: cs.primaryContainer.withValues(alpha: 0.38),
        border: Border.all(color: cs.primary.withValues(alpha: 0.18)),
      ),
      child: Icon(icon, color: cs.primary, size: 22),
    );
  }
}

class _ProviderPill extends StatelessWidget {
  const _ProviderPill({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: selected
            ? cs.primaryContainer.withValues(alpha: 0.5)
            : cs.surfaceContainerHighest.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(t.radiusFull),
        border: Border.all(
          color: selected
              ? cs.primary.withValues(alpha: 0.34)
              : cs.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: t.space12,
          vertical: t.space4,
        ),
        child: Text(
          label,
          style: tt.labelMedium?.copyWith(
            color: selected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ByokPanel extends StatelessWidget {
  const _ByokPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final cs = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(t.radiusLg),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.18)),
      ),
      child: Padding(padding: EdgeInsets.all(t.space16), child: child),
    );
  }
}
