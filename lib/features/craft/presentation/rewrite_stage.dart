/// Rewrite stage: raw transcript + editable target text + style/voice + actions.
///
/// Shows what the user said (compact, collapsible) and an editable AI-rewritten
/// version in the target language, then style/voice controls and generate.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/features/craft/application/craft_controller.dart';
import 'package:enjoy_player/features/craft/domain/azure_voice.dart';
import 'package:enjoy_player/features/craft/domain/craft_failure.dart';
import 'package:enjoy_player/features/craft/domain/craft_job_state.dart';
import 'package:enjoy_player/features/craft/presentation/style_picker.dart';
import 'package:enjoy_player/features/craft/presentation/voice_picker.dart';
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
  bool _targetInitialized = false;
  bool _rawExpanded = false;
  String? _lastSyncedText;

  @override
  void dispose() {
    if (_targetInitialized) {
      _targetCtrl.dispose();
      _targetFocus.dispose();
    }
    super.dispose();
  }

  void _ensureTargetController(CraftJobState state) {
    if (!_targetInitialized) {
      _targetCtrl = TextEditingController(text: state.translatedText ?? '');
      _targetFocus = FocusNode();
      _lastSyncedText = state.translatedText;
      _targetInitialized = true;
    }
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
            .setSelectedVoice(defaultVoice.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(craftControllerProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    _ensureTargetController(state);

    final currentTranslated = state.translatedText ?? '';
    if (_lastSyncedText != currentTranslated && !_targetFocus.hasFocus) {
      _targetCtrl.text = currentTranslated;
      _lastSyncedText = currentTranslated;
    }

    if (state.isTranslating) {
      return _LoadingView(l10n: l10n);
    }

    if (state.failure != null) {
      return _FailureCard(
        failure: state.failure!,
        l10n: l10n,
        onRetry: () => ref.read(craftControllerProvider.notifier).regenerate(),
      );
    }

    _seedVoiceIfNeeded(state);

    final targetBase = state.targetLanguage.split('-').first.toUpperCase();
    final raw = state.rawTranscript;
    final hasRaw = raw != null && raw.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 28),
      children: [
        if (hasRaw) ...[
          _RawTranscriptCard(
            text: raw,
            l10n: l10n,
            theme: theme,
            expanded: _rawExpanded,
            onToggle: () => setState(() => _rawExpanded = !_rawExpanded),
          ),
          const SizedBox(height: 14),
        ],
        _TargetTextCard(
          controller: _targetCtrl,
          focusNode: _targetFocus,
          targetLabel: l10n.craftRewriteTargetLabel,
          targetBase: targetBase,
          theme: theme,
          onChanged: (v) {
            _lastSyncedText = v;
            ref.read(craftControllerProvider.notifier).setTranslatedText(v);
          },
        ),
        const SizedBox(height: 14),
        DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StylePicker(
                  value: state.style,
                  onChanged: (s) =>
                      ref.read(craftControllerProvider.notifier).setStyle(s),
                ),
                Divider(
                  height: 20,
                  color: scheme.outlineVariant.withValues(alpha: 0.5),
                ),
                VoicePicker(
                  language: state.targetLanguage,
                  selectedVoice: state.selectedVoice,
                  onChanged: (voice) => ref
                      .read(craftControllerProvider.notifier)
                      .setSelectedVoice(voice),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        _ActionButtons(
          state: state,
          l10n: l10n,
          onReRecord: () =>
              ref.read(craftControllerProvider.notifier).resetForNextCapture(),
          onRegenerate: hasRaw
              ? () => ref.read(craftControllerProvider.notifier).regenerate()
              : null,
          onGenerateAudio:
              state.translatedText != null &&
                  state.translatedText!.trim().isNotEmpty
              ? () => ref.read(craftControllerProvider.notifier).generateAudio()
              : null,
        ),
      ],
    );
  }
}

// === Sub-widgets ===

class _LoadingView extends StatelessWidget {
  const _LoadingView({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            '…',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _RawTranscriptCard extends StatelessWidget {
  const _RawTranscriptCard({
    required this.text,
    required this.l10n,
    required this.theme,
    required this.expanded,
    required this.onToggle,
  });

  final String text;
  final AppLocalizations l10n;
  final ThemeData theme;
  final bool expanded;
  final VoidCallback onToggle;

  static const _collapseAt = 140;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    final canCollapse = text.length > _collapseAt;
    final showExpanded = expanded || !canCollapse;

    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: canCollapse ? onToggle : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.format_quote_rounded,
                    size: 16,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n.craftRewriteYourWords,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  if (canCollapse)
                    Icon(
                      showExpanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      size: 20,
                      color: scheme.onSurfaceVariant,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                text,
                maxLines: showExpanded ? null : 3,
                overflow: showExpanded
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
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
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String targetLabel;
  final String targetBase;
  final ThemeData theme;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.35)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: ColoredBox(
                color: scheme.primary,
                child: const SizedBox(width: 3),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          targetBase,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          targetLabel,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: controller,
                    focusNode: focusNode,
                    minLines: 3,
                    maxLines: 10,
                    textInputAction: TextInputAction.newline,
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                    onChanged: onChanged,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.state,
    required this.l10n,
    required this.onReRecord,
    required this.onRegenerate,
    required this.onGenerateAudio,
  });

  final CraftJobState state;
  final AppLocalizations l10n;
  final VoidCallback onReRecord;
  final VoidCallback? onRegenerate;
  final VoidCallback? onGenerateAudio;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: onGenerateAudio,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: const Icon(Icons.graphic_eq_rounded),
          label: Text(l10n.craftRewriteGenerateAudio),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onReRecord,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.mic_rounded, size: 18),
                label: Text(l10n.craftRewriteReRecord),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onRegenerate,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(l10n.craftRewriteRegenerate),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FailureCard extends StatelessWidget {
  const _FailureCard({
    required this.failure,
    required this.l10n,
    required this.onRetry,
  });

  final CraftFailure failure;
  final AppLocalizations l10n;
  final VoidCallback onRetry;

  String _actionLabel() {
    switch (failure.action) {
      case CraftFailureAction.openAiSettings:
        return l10n.craftOpenAiSettings;
      case CraftFailureAction.signIn:
        return l10n.craftSignInRequired;
      default:
        return l10n.craftRetry;
    }
  }

  void _handleAction(BuildContext context) {
    switch (failure.action) {
      case CraftFailureAction.openAiSettings:
        unawaited(context.push('/settings/ai-providers'));
      case CraftFailureAction.signIn:
        unawaited(context.push('/sign-in'));
      default:
        onRetry();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              failure.message(l10n),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => _handleAction(context),
              child: Text(_actionLabel()),
            ),
          ],
        ),
      ),
    );
  }
}
