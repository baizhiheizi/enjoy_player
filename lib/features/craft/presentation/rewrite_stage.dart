/// Rewrite stage: editable native transcript + editable target text +
/// style/voice + actions.
///
/// Learners can correct STT mistakes in "Your words", then re-translate
/// before generating audio. Target text remains editable for final polish.
library;

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/presentation/loading_icon.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/typography.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_card.dart';
import 'package:enjoy_player/features/craft/application/craft_controller.dart';
import 'package:enjoy_player/features/craft/domain/azure_voice.dart';
import 'package:enjoy_player/features/craft/domain/craft_job_state.dart';
import 'package:enjoy_player/features/craft/domain/craft_request.dart';
import 'package:enjoy_player/features/craft/presentation/style_picker.dart';
import 'package:enjoy_player/features/craft/presentation/voice_picker.dart';
import 'package:enjoy_player/features/craft/presentation/widgets/craft_failure_card.dart';
import 'package:enjoy_player/features/craft/presentation/widgets/craft_loading_view.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Rewrite stage for the Express flow.
class RewriteStage extends ConsumerStatefulWidget {
  const RewriteStage({super.key});

  @override
  ConsumerState<RewriteStage> createState() => _RewriteStageState();
}

class _RewriteStageState extends ConsumerState<RewriteStage> {
  late final TextEditingController _targetCtrl;
  late final FocusNode _targetFocus;
  late final TextEditingController _nativeCtrl;
  late final FocusNode _nativeFocus;
  bool _controllersInitialized = false;
  String? _lastSyncedTarget;
  String? _lastSyncedNative;

  @override
  void dispose() {
    if (_controllersInitialized) {
      _targetCtrl.dispose();
      _targetFocus.dispose();
      _nativeCtrl.dispose();
      _nativeFocus.dispose();
    }
    super.dispose();
  }

  void _ensureControllers(CraftJobState state) {
    if (_controllersInitialized) return;
    _targetCtrl = TextEditingController(text: state.translatedText ?? '');
    _targetFocus = FocusNode();
    _nativeCtrl = TextEditingController(text: state.rawTranscript ?? '');
    _nativeFocus = FocusNode();
    _lastSyncedTarget = state.translatedText;
    _lastSyncedNative = state.rawTranscript;
    _controllersInitialized = true;
  }

  void _seedVoiceIfNeeded(CraftJobState state) {
    if (state.selectedVoice != null) return;
    final defaultVoice = defaultVoiceForLanguage(
      state.targetLanguage.split('-').first.toLowerCase(),
    );
    if (defaultVoice == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final current = ref.read(craftControllerProvider);
      if (current.selectedVoice == null) {
        ref
            .read(craftControllerProvider.notifier)
            .setSelectedVoice(
              defaultVoice.id,
              forLanguage: current.targetLanguage,
            );
      }
    });
  }

  void _flushNativeToController() {
    if (!_controllersInitialized) return;
    ref
        .read(craftControllerProvider.notifier)
        .setRawTranscript(_nativeCtrl.text);
  }

  Future<void> _regenerate() async {
    _flushNativeToController();
    await ref.read(craftControllerProvider.notifier).regenerate();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(craftControllerProvider);
    final theme = Theme.of(context);
    final t = EnjoyThemeTokens.of(context);

    _ensureControllers(state);

    final currentTranslated = state.translatedText ?? '';
    if (_lastSyncedTarget != currentTranslated && !_targetFocus.hasFocus) {
      _targetCtrl.text = currentTranslated;
      _lastSyncedTarget = currentTranslated;
    }

    final currentNative = state.rawTranscript ?? '';
    if (_lastSyncedNative != currentNative && !_nativeFocus.hasFocus) {
      _nativeCtrl.text = currentNative;
      _lastSyncedNative = currentNative;
    }

    if (state.isTranslating && !state.hasTranslation) {
      return CraftLoadingView(message: l10n.craftLoadingRewriting);
    }

    if (state.failure != null) {
      return CraftFailureCard(
        failure: state.failure!,
        l10n: l10n,
        onRetry: () => unawaited(_regenerate()),
      );
    }

    _seedVoiceIfNeeded(state);

    final targetBase = state.targetLanguage.split('-').first.toUpperCase();
    final raw = state.rawTranscript;
    final hasRaw = raw != null && raw.isNotEmpty;
    final isRetranslating = state.isTranslating && state.hasTranslation;
    final canRegenerate =
        hasRaw &&
        normalizeCraftText(raw).length >= craftMinTextLength &&
        !state.isBusy;
    final showReTranslate =
        hasRaw && state.isRawTranscriptDirty && !isRetranslating;

    return ListView(
      padding: EdgeInsets.fromLTRB(t.space4, t.space4, t.space4, t.space32),
      children: [
        if (hasRaw) ...[
          _NativeTextCard(
            controller: _nativeCtrl,
            focusNode: _nativeFocus,
            l10n: l10n,
            theme: theme,
            enabled: !state.isBusy,
            showReTranslate: showReTranslate,
            isRetranslating: isRetranslating,
            onChanged: (v) {
              _lastSyncedNative = v;
              ref.read(craftControllerProvider.notifier).setRawTranscript(v);
            },
            onReTranslate: canRegenerate
                ? () => unawaited(_regenerate())
                : null,
          ),
          SizedBox(height: t.space16),
        ],
        _TargetTextCard(
          controller: _targetCtrl,
          focusNode: _targetFocus,
          targetLabel: l10n.craftRewriteTargetLabel,
          targetBase: targetBase,
          theme: theme,
          enabled: !state.isBusy,
          onChanged: (v) {
            _lastSyncedTarget = v;
            ref.read(craftControllerProvider.notifier).setTranslatedText(v);
          },
        ),
        SizedBox(height: t.space16),
        EnjoyCard(
          elevated: false,
          padding: EdgeInsets.symmetric(
            horizontal: t.space16,
            vertical: t.space12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StylePicker(
                value: state.style,
                onChanged: (s) {
                  if (state.isBusy) return;
                  ref.read(craftControllerProvider.notifier).setStyle(s);
                },
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: t.space8),
                child: Divider(height: 1, thickness: 1, color: t.hairline),
              ),
              VoicePicker(
                language: state.targetLanguage,
                selectedVoice: state.selectedVoice,
                onChanged: (voice) {
                  if (state.isBusy) return;
                  ref
                      .read(craftControllerProvider.notifier)
                      .setSelectedVoice(
                        voice,
                        forLanguage: state.targetLanguage,
                      );
                },
              ),
            ],
          ),
        ),
        SizedBox(height: t.space24),
        _ActionButtons(
          state: state,
          l10n: l10n,
          isRetranslating: isRetranslating,
          onReRecord: state.isBusy
              ? null
              : () => ref
                    .read(craftControllerProvider.notifier)
                    .resetForNextCapture(),
          onRegenerate: canRegenerate ? () => unawaited(_regenerate()) : null,
          onGenerateAudio:
              !state.isBusy &&
                  state.translatedText != null &&
                  state.translatedText!.trim().isNotEmpty
              ? () => ref.read(craftControllerProvider.notifier).generateAudio()
              : null,
        ),
      ],
    );
  }
}

class _NativeTextCard extends StatelessWidget {
  const _NativeTextCard({
    required this.controller,
    required this.focusNode,
    required this.l10n,
    required this.theme,
    required this.enabled,
    required this.showReTranslate,
    required this.isRetranslating,
    required this.onChanged,
    required this.onReTranslate,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final AppLocalizations l10n;
  final ThemeData theme;
  final bool enabled;
  final bool showReTranslate;
  final bool isRetranslating;
  final ValueChanged<String> onChanged;
  final VoidCallback? onReTranslate;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final scheme = theme.colorScheme;

    return EnjoyCard(
      elevated: false,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              t.space16,
              t.space16,
              t.space12,
              t.space12,
            ),
            child: Row(
              children: [
                Icon(EnjoyIcons.quote, size: 16, color: t.textFaint),
                SizedBox(width: t.space8),
                Expanded(
                  child: Text(
                    l10n.craftRewriteYourWords,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
                if (isRetranslating)
                  const LoadingIcon(size: 18, strokeWidth: 2)
                else if (showReTranslate)
                  EnjoyButton.ghost(
                    onPressed: onReTranslate,
                    size: EnjoyButtonSize.small,
                    child: Text(l10n.craftReTranslateButton),
                  ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(t.space12, 0, t.space12, t.space12),
            child: _CraftTextField(
              controller: controller,
              focusNode: focusNode,
              enabled: enabled,
              minLines: 3,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared transcript field: recessed fill, hairline outline, continuous
/// corners, and the Aurora focus treatment.
class _CraftTextField extends StatelessWidget {
  const _CraftTextField({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.minLines,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final int minLines;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final theme = Theme.of(context);
    final fieldRadius = BorderRadius.circular(t.radiusMd);
    final side = BorderSide(
      color: enabled ? t.hairline : t.hairline.withValues(alpha: 0.5),
    );

    return TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      minLines: minLines,
      maxLines: 10,
      textInputAction: TextInputAction.newline,
      style: theme.textTheme.bodyLarge?.copyWith(height: 1.55),
      onChanged: onChanged,
      decoration: InputDecoration(
        filled: true,
        fillColor: t.fill,
        isDense: false,
        contentPadding: EdgeInsets.all(t.space16),
        border: OutlineInputBorder(borderRadius: fieldRadius, borderSide: side),
        enabledBorder: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: side,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: BorderSide(color: t.accentInk, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: side,
        ),
      ),
    );
  }
}

class _TargetTextCard extends StatelessWidget {
  const _TargetTextCard({
    required this.controller,
    required this.focusNode,
    required this.targetLabel,
    required this.targetBase,
    required this.theme,
    required this.onChanged,
    required this.enabled,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String targetLabel;
  final String targetBase;
  final ThemeData theme;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final scheme = theme.colorScheme;

    return EnjoyCard(
      elevated: false,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              t.space16,
              t.space16,
              t.space16,
              t.space12,
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: t.space8,
                    vertical: 4,
                  ),
                  decoration: ShapeDecoration(
                    color: t.accentSoft,
                    shape: RoundedSuperellipseBorder(
                      borderRadius: BorderRadius.circular(t.radiusSm),
                    ),
                  ),
                  child: Text(
                    targetBase,
                    style: enjoyMonoStyle(
                      context,
                      size: 12.5,
                      weight: FontWeight.w600,
                      color: t.accentInk,
                    ),
                  ),
                ),
                SizedBox(width: t.space8),
                Expanded(
                  child: Text(
                    targetLabel,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(t.space12, 0, t.space12, t.space12),
            child: _CraftTextField(
              controller: controller,
              focusNode: focusNode,
              enabled: enabled,
              minLines: 4,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.state,
    required this.l10n,
    required this.isRetranslating,
    required this.onReRecord,
    required this.onRegenerate,
    required this.onGenerateAudio,
  });

  final CraftJobState state;
  final AppLocalizations l10n;
  final bool isRetranslating;
  final VoidCallback? onReRecord;
  final VoidCallback? onRegenerate;
  final VoidCallback? onGenerateAudio;

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EnjoyButton.primary(
          onPressed: onGenerateAudio,
          icon: EnjoyIcons.waveform,
          expand: true,
          child: Text(l10n.craftRewriteGenerateAudio),
        ),
        SizedBox(height: t.space8),
        Row(
          children: [
            Expanded(
              child: EnjoyButton.secondary(
                onPressed: onReRecord,
                icon: EnjoyIcons.mic,
                expand: true,
                child: Text(l10n.craftRewriteReRecord),
              ),
            ),
            SizedBox(width: t.space8),
            Expanded(
              child: EnjoyButton.secondary(
                onPressed: onRegenerate,
                icon: isRetranslating ? null : EnjoyIcons.refresh,
                expand: true,
                child: Text(l10n.craftRewriteRegenerate),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
