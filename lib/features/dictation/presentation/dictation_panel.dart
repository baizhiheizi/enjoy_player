import 'dart:async';

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_segmented_control.dart';
import 'package:enjoy_player/features/dictation/application/dictation_controller.dart';
import 'package:enjoy_player/features/dictation/domain/dictation_diff.dart';
import 'package:enjoy_player/features/dictation/domain/dictation_models.dart';
import 'package:enjoy_player/features/shadow_reading/application/shadow_reading_hotkey_bus.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DictationPanel extends StatefulWidget {
  const DictationPanel({
    super.key,
    required this.state,
    required this.controller,
    required this.onNextLine,
  });

  final DictationSessionState state;
  final DictationController controller;
  final VoidCallback onNextLine;

  @override
  State<DictationPanel> createState() => _DictationPanelState();
}

class _DictationPanelState extends State<DictationPanel> {
  late final TextEditingController _textEditingController;

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController(
      text: widget.state.textDraft,
    );
  }

  @override
  void didUpdateWidget(DictationPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.textDraft != widget.state.textDraft &&
        _textEditingController.text != widget.state.textDraft) {
      _textEditingController.text = widget.state.textDraft;
    }
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);
    final isChecked = widget.state.status == DictationAttemptStatus.checked;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isChecked) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                EnjoySegmentedControl<DictationInputMode>(
                  value: widget.state.mode,
                  onChanged: (mode) => widget.controller.setInputMode(mode),
                  segments: [
                    EnjoySegment(
                      value: DictationInputMode.voice,
                      label: l10n?.playerDictationVoiceMode ?? 'Voice',
                    ),
                    EnjoySegment(
                      value: DictationInputMode.text,
                      label: l10n?.playerDictationTextMode ?? 'Text',
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (widget.state.mode == DictationInputMode.voice)
            _buildVoiceRetellingView(t, l10n)
          else
            _buildTextInputView(t, l10n),
        ] else
          _buildCheckedSummary(t, l10n),
      ],
    );
  }

  Widget _buildVoiceRetellingView(EnjoyThemeTokens t, AppLocalizations? l10n) {
    final isTranscribing =
        widget.state.status == DictationAttemptStatus.transcribingVoice;
    final hasError = widget.state.errorMessage != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.sunk,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n?.playerDictationVoiceHint ??
                'Listen and retell by voice. Tap Record or press R when ready.',
            style: TextStyle(fontSize: 13, color: t.ink2),
          ),
          const SizedBox(height: 12),
          if (isTranscribing)
            Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text(
                  l10n?.playerDictationCheckingVoice ??
                      'Transcribing speech...',
                  style: TextStyle(fontSize: 13, color: t.ink2),
                ),
              ],
            )
          else if (hasError)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.state.errorMessage ?? '',
                  style: TextStyle(fontSize: 13, color: t.danger),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    EnjoyButton.secondary(
                      size: EnjoyButtonSize.small,
                      onPressed: () =>
                          widget.controller.retryVoiceTranscription(),
                      child: Text(
                        l10n?.playerDictationRetryTranscription ??
                            'Retry transcription',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Consumer(
                      builder: (context, ref, _) {
                        return EnjoyButton.brand(
                          size: EnjoyButtonSize.small,
                          onPressed: () {
                            ref
                                .read(shadowReadingHotkeyBusProvider.notifier)
                                .pulseRecording();
                          },
                          icon: EnjoyIcons.mic,
                          child: const Text('Record again'),
                        );
                      },
                    ),
                  ],
                ),
              ],
            )
          else
            Consumer(
              builder: (context, ref, _) {
                return EnjoyButton.brand(
                  onPressed: () {
                    ref
                        .read(shadowReadingHotkeyBusProvider.notifier)
                        .pulseRecording();
                  },
                  icon: EnjoyIcons.mic,
                  child: const Text('Record retelling (R)'),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTextInputView(EnjoyThemeTokens t, AppLocalizations? l10n) {
    final typedCount = tokenizeDictationWords(widget.state.textDraft).length;
    final totalCount = tokenizeDictationWords(
      widget.controller.scope.referenceText,
    ).length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: t.sunk,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KeyboardListener(
            focusNode: FocusNode(),
            onKeyEvent: (event) {
              if (event is KeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.enter &&
                  !HardwareKeyboard.instance.isShiftPressed) {
                unawaited(widget.controller.checkTextAnswer());
              }
            },
            child: TextField(
              controller: _textEditingController,
              onChanged: (val) => widget.controller.updateTextDraft(val),
              maxLines: 3,
              minLines: 2,
              decoration: InputDecoration(
                hintText:
                    l10n?.playerDictationTextPlaceholder ??
                    'Type what you hear...',
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n?.playerDictationWordCountProgress(
                      typedCount,
                      totalCount,
                    ) ??
                    '$typedCount of about $totalCount words',
                style: TextStyle(fontSize: 12, color: t.ink3),
              ),
              EnjoyButton.brand(
                size: EnjoyButtonSize.small,
                onPressed: widget.state.textDraft.trim().isNotEmpty
                    ? () => widget.controller.checkTextAnswer()
                    : null,
                child: Text(l10n?.playerDictationCheckAnswer ?? 'Check answer'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCheckedSummary(EnjoyThemeTokens t, AppLocalizations? l10n) {
    final diff = widget.state.activeDiff;
    final accuracy = diff?.accuracy ?? 0;
    final correct = diff?.correctWords ?? 0;
    final missed = diff?.missedWords ?? 0;
    final extra = diff?.extraWords ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.sunk,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: accuracy >= 80 ? t.originalSoft : t.sunk,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: accuracy >= 80 ? t.original : t.line,
                  ),
                ),
                child: Text(
                  '$accuracy%',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: accuracy >= 80 ? t.originalInk : t.ink,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    Text(
                      l10n?.playerDictationStatsCorrect(correct) ??
                          '$correct correct',
                      style: TextStyle(
                        fontSize: 13,
                        color: t.originalInk,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      l10n?.playerDictationStatsMissed(missed) ??
                          '$missed missed',
                      style: TextStyle(
                        fontSize: 13,
                        color: t.danger,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      l10n?.playerDictationStatsExtra(extra) ?? '$extra extra',
                      style: TextStyle(
                        fontSize: 13,
                        color: t.youInk,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              EnjoyButton.secondary(
                onPressed: () => widget.controller.tryAgain(),
                child: Text(l10n?.playerDictationTryAgain ?? 'Try again'),
              ),
              const SizedBox(width: 8),
              EnjoyButton.brand(
                onPressed: widget.onNextLine,
                child: Text(l10n?.playerDictationNextLine ?? 'Next line'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
