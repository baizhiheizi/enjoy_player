/// Audio stage: preview player + save/loop/practice actions.
///
/// Shows the full learning-language script (scrollable when long) so the
/// learner can follow along while previewing, an inline audio preview player,
/// a collapsible voice chip, an unsaved-preview hint, and two save CTAs:
/// "Save & practice" (navigate to player) and "Save & say another" (loop).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/notices/app_notice.dart';
import 'package:enjoy_player/core/presentation/loading_icon.dart';
import 'package:enjoy_player/core/routing/player_navigation.dart';
import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/core/theme/widgets/enjoy_button.dart';
import 'package:enjoy_player/features/craft/application/craft_controller.dart';
import 'package:enjoy_player/features/craft/presentation/audio_stage_actions.dart';
import 'package:enjoy_player/features/craft/presentation/audio_stage_script_block.dart';
import 'package:enjoy_player/features/craft/presentation/audio_stage_voice_chip.dart';
import 'package:enjoy_player/features/craft/presentation/craft_solid_transcript_stt_hint.dart';
import 'package:enjoy_player/features/craft/presentation/widgets/craft_failure_card.dart';
import 'package:enjoy_player/features/craft/presentation/widgets/craft_loading_view.dart';
import 'package:enjoy_player/features/craft/presentation/widgets/craft_preview_player.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

/// Audio stage for the Express flow.
class AudioStage extends ConsumerStatefulWidget {
  const AudioStage({super.key});

  @override
  ConsumerState<AudioStage> createState() => _AudioStageState();
}

class _AudioStageState extends ConsumerState<AudioStage> {
  bool _voiceExpanded = false;

  Future<void> _saveAndCaptureNext() async {
    final result = await ref
        .read(craftControllerProvider.notifier)
        .saveAndCaptureNext();
    if (!mounted) return;
    if (result == null) return;

    AppNotice.success(
      context,
      AppLocalizations.of(context)!.craftSavedToLibrary,
    );
    maybeShowCraftSolidTranscriptSttHint(
      context,
      savedSolidTimeline: result.wroteSolidTranscript,
    );
  }

  Future<void> _saveAndPractice() async {
    final result = await ref
        .read(craftControllerProvider.notifier)
        .saveToLibrary();
    if (!mounted || result == null) return;

    maybeShowCraftSolidTranscriptSttHint(
      context,
      savedSolidTimeline: result.wroteSolidTranscript,
    );
    final state = ref.read(craftControllerProvider);
    final targetId = state.dedupedExistingId ?? result.mediaId;
    if (mounted) openPlayerRoute(context, targetId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(craftControllerProvider);
    final theme = Theme.of(context);
    final t = EnjoyThemeTokens.of(context);

    if (state.isSynthesizing) {
      return CraftLoadingView(message: l10n.craftLoadingSynthesizing);
    }

    if (state.failure != null) {
      return CraftFailureCard(
        failure: state.failure!,
        l10n: l10n,
        onRetry: () =>
            ref.read(craftControllerProvider.notifier).generateAudio(),
      );
    }

    if (!state.hasPreview) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(t.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.craftAudioPreview, style: theme.textTheme.bodyLarge),
              SizedBox(height: t.space16),
              EnjoyButton.brand(
                onPressed: () =>
                    ref.read(craftControllerProvider.notifier).generateAudio(),
                child: Text(l10n.craftRewriteGenerateAudio),
              ),
            ],
          ),
        ),
      );
    }

    final sourceLang = state.sourceLanguage?.toUpperCase() ?? '—';
    final targetLang = state.targetLanguage.toUpperCase();
    final previewText = state.translatedText ?? state.synthText;
    final voiceLabel = voiceDisplayLabel(state.selectedVoice);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: t.space8, vertical: t.space8),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AudioStageScriptBlock(
                sourceLang: sourceLang,
                targetLang: targetLang,
                text: previewText,
                theme: theme,
              ),
              SizedBox(height: t.space20),
              CraftPreviewPlayer(audioBytes: state.previewAudioBytes!),
              SizedBox(height: t.space16),
              AudioStageVoiceChip(
                expanded: _voiceExpanded,
                synthLanguage: state.synthLanguage,
                selectedVoice: state.selectedVoice,
                voiceLabel: voiceLabel,
                theme: theme,
                onToggle: () {
                  setState(() => _voiceExpanded = !_voiceExpanded);
                },
                onVoiceChanged: (voice) {
                  ref
                      .read(craftControllerProvider.notifier)
                      .setSelectedVoice(
                        voice,
                        forLanguage: state.synthLanguage,
                      );
                  unawaited(
                    ref.read(craftControllerProvider.notifier).generateAudio(),
                  );
                },
              ),
              SizedBox(height: t.space20),
              if (state.hasUnsavedPreview) ...[
                AudioStageUnsavedPreviewHint(
                  message: l10n.craftAudioUnsavedHint,
                ),
                SizedBox(height: t.space16),
              ],
              if (state.isSaving)
                const Center(child: LoadingIcon(size: 28, strokeWidth: 2.5))
              else
                AudioStageActions(
                  practiceLabel: l10n.craftAudioPracticeNow,
                  sayAnotherLabel: l10n.craftAudioSaySomethingElse,
                  onPractice: _saveAndPractice,
                  onSayAnother: _saveAndCaptureNext,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
