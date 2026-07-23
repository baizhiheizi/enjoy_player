/// Rewrite stage: raw transcript + editable target text + style chip + actions.
///
/// Shows what the user said (muted, italic) and an editable AI-rewritten version
/// in the target language. Includes a collapsible style chip and three actions:
/// re-record, regenerate, and generate audio.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/features/craft/application/craft_controller.dart';
import 'package:enjoy_player/features/craft/domain/craft_failure.dart';
import 'package:enjoy_player/features/craft/domain/craft_job_state.dart';
import 'package:enjoy_player/features/craft/domain/translation_style.dart';
import 'package:enjoy_player/features/craft/presentation/style_picker.dart';
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
  bool _styleExpanded = false;
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(craftControllerProvider);
    final theme = Theme.of(context);

    _ensureTargetController(state);

    // Sync controller text when the translated text changes externally
    // (e.g. after regenerate), but only if the field isn't being actively edited.
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

    final targetBase = state.targetLanguage.split('-').first.toUpperCase();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Raw transcript card.
              if (state.rawTranscript != null &&
                  state.rawTranscript!.isNotEmpty) ...[
                _RawTranscriptCard(
                  text: state.rawTranscript!,
                  l10n: l10n,
                  theme: theme,
                ),
                const SizedBox(height: 20),
              ],

              // Target text card.
              _TargetTextCard(
                controller: _targetCtrl,
                focusNode: _targetFocus,
                targetLabel: l10n.craftRewriteTargetLabel,
                targetBase: targetBase,
                theme: theme,
                onChanged: (v) {
                  _lastSyncedText = v;
                  ref
                      .read(craftControllerProvider.notifier)
                      .setTranslatedText(v);
                },
              ),
              const SizedBox(height: 16),

              // Collapsible style chip.
              _StyleSection(
                expanded: _styleExpanded,
                state: state,
                l10n: l10n,
                onToggle: () =>
                    setState(() => _styleExpanded = !_styleExpanded),
                onStyleChanged: (s) =>
                    ref.read(craftControllerProvider.notifier).setStyle(s),
              ),
              const SizedBox(height: 24),

              // Action buttons.
              _ActionButtons(
                state: state,
                l10n: l10n,
                onReRecord: () => ref
                    .read(craftControllerProvider.notifier)
                    .resetForNextCapture(),
                onRegenerate:
                    state.rawTranscript != null &&
                        state.rawTranscript!.isNotEmpty
                    ? () => ref
                          .read(craftControllerProvider.notifier)
                          .regenerate()
                    : null,
                onGenerateAudio:
                    state.translatedText != null &&
                        state.translatedText!.trim().isNotEmpty
                    ? () => ref
                          .read(craftControllerProvider.notifier)
                          .generateAudio()
                    : null,
              ),
            ],
          ),
        ),
      ),
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
  });

  final String text;
  final AppLocalizations l10n;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.record_voice_over_rounded,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                l10n.craftRewriteYourWords,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                targetBase,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                targetLabel,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            focusNode: focusNode,
            maxLines: null,
            minLines: 3,
            textInputAction: TextInputAction.newline,
            style: theme.textTheme.bodyLarge,
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _StyleSection extends StatelessWidget {
  const _StyleSection({
    required this.expanded,
    required this.state,
    required this.l10n,
    required this.onToggle,
    required this.onStyleChanged,
  });

  final bool expanded;
  final CraftJobState state;
  final AppLocalizations l10n;
  final VoidCallback onToggle;
  final ValueChanged<TranslationStyle> onStyleChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.craftStyleLabel,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        if (expanded) ...[
          const SizedBox(height: 4),
          StylePicker(value: state.style, onChanged: onStyleChanged),
        ],
      ],
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
        // Primary: Generate audio.
        FilledButton.icon(
          onPressed: onGenerateAudio,
          icon: const Icon(Icons.graphic_eq_rounded),
          label: Text(l10n.craftRewriteGenerateAudio),
        ),
        const SizedBox(height: 12),
        // Secondary actions row.
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onReRecord,
                icon: const Icon(Icons.mic_rounded, size: 18),
                label: Text(l10n.craftRewriteReRecord),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onRegenerate,
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
