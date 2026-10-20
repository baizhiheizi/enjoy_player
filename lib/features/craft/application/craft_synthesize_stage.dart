/// Synthesize stage of the Craft controller: the speech inputs, the TTS
/// pipeline, and the audio handoff that turns a translation into a preview.
library;

import 'dart:async';

import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/craft/application/craft_controller_core.dart';
import 'package:enjoy_player/features/craft/application/craft_preferences_provider.dart';
import 'package:enjoy_player/features/craft/application/craft_service_providers.dart';
import 'package:enjoy_player/features/craft/domain/craft_failure.dart';
import 'package:enjoy_player/features/craft/domain/craft_job_state.dart';
import 'package:enjoy_player/features/craft/domain/craft_request.dart';
import 'package:enjoy_player/features/craft/domain/craft_stage.dart';

/// Voice inputs, the TTS pipeline, and the audio handoff.
mixin CraftSynthesizeMixin on CraftControllerCore {
  void setSynthText(String text) {
    state = state.copyWith(synthText: text, clearFailure: true);
  }

  void setSynthLanguage(String lang) {
    prefsHydrationMutated = true;
    state = state.copyWith(
      synthLanguage: lang,
      selectedVoice: voiceMatchingLanguage(lang, state.selectedVoice),
      clearPreview: true,
      clearFailure: true,
    );
  }

  /// Selects a voice, remembering it under [forLanguage]'s base code so the
  /// pick survives sessions. Defaults to [CraftJobState.synthLanguage]; the
  /// RewriteStage picker passes [CraftJobState.targetLanguage] explicitly
  /// because synthLanguage may still be stale there.
  void setSelectedVoice(String? voice, {String? forLanguage}) {
    prefsHydrationMutated = true;
    final language = forLanguage ?? state.synthLanguage;
    state = state.copyWith(
      selectedVoice: voice,
      clearSelectedVoice: voice == null,
      clearPreview: true,
    );
    unawaited(
      ref
          .read(craftPreferencesCtrlProvider.notifier)
          .setVoice(baseLanguage(language), voice),
    );
  }

  Future<void> synthesize() async {
    final normalized = normalizeCraftText(state.synthText);
    if (normalized.length < craftMinTextLength) return;

    final auth = ref.read(authCtrlProvider).valueOrNull;
    if (auth is! AuthSignedIn) {
      state = state.copyWith(failure: const CraftSignInRequiredFailure());
      return;
    }

    state = state.copyWith(
      isSynthesizing: true,
      clearFailure: true,
      clearPreview: true,
    );

    try {
      final synthesizer = ref.read(craftSynthesizerProvider);
      final result = await synthesizer.synthesize(
        text: normalized,
        language: state.synthLanguage,
        voice: state.selectedVoice,
      );
      state = state.copyWith(
        previewAudioBytes: result.audioBytes,
        previewFormat: result.format,
        previewWordBoundaries: result.wordBoundaries,
        isSynthesizing: false,
      );
    } catch (e, st) {
      logNamed('craft.synthesize').warning('Synthesize failed: $e', e, st);
      state = state.copyWith(isSynthesizing: false, failure: mapTtsFailure(e));
    }
  }

  /// Copy [translatedText] → [synthText] and synthesize.
  /// Auto-selects a default voice if none is set.
  Future<void> generateAudio() async {
    if (state.translatedText == null || state.translatedText!.isEmpty) return;

    final target = state.targetLanguage;

    state = state.copyWith(
      stage: CraftStage.audio,
      synthText: state.translatedText!,
      synthLanguage: target,
      selectedVoice: voiceMatchingLanguage(target, state.selectedVoice),
      clearPreview: true,
      clearFailure: true,
    );
    await synthesize();
  }
}
