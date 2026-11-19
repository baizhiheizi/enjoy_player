/// Capture stage of the Craft controller: the Express-mode microphone
/// flow, ASR transcription, and the LLM rewrite of a transcript.
library;

import 'dart:typed_data';

import 'package:enjoy_player/features/craft/application/craft_controller_core.dart';
import 'package:enjoy_player/features/craft/application/craft_service_providers.dart';
import 'package:enjoy_player/features/craft/domain/craft_failure.dart';
import 'package:enjoy_player/features/craft/domain/craft_job_state.dart';
import 'package:enjoy_player/features/craft/domain/craft_request.dart';
import 'package:enjoy_player/features/craft/domain/craft_stage.dart';

/// Express-mode capture, ASR transcription, and the transcript rewrite.
mixin CraftCaptureMixin on CraftControllerCore {
  /// Begin voice capture — sets [isCapturing] flag.
  /// The [CaptureStage] widget owns the actual AudioRecorder.
  void startCapture() {
    state = state.copyWith(
      isCapturing: true,
      clearFailure: true,
      clearCapturedAudio: true,
      clearRawTranscript: true,
      clearRewrittenFromTranscript: true,
    );
  }

  /// Discard an in-progress capture without running ASR.
  ///
  /// Bumps [CraftJobState.captureCancelTick] so [CaptureStage] can stop and
  /// discard the live mic. Safe to call when not capturing (no-op for UI).
  void cancelCapture() {
    state = state.copyWith(
      isCapturing: false,
      isTranscribing: false,
      captureCancelTick: state.captureCancelTick + 1,
      clearCapturedAudio: true,
      clearFailure: true,
    );
  }

  /// Stop capture and store the recorded audio bytes.
  /// Automatically kicks off transcription + rewrite.
  Future<void> stopCapture(Uint8List audioBytes) async {
    state = state.copyWith(isCapturing: false, capturedAudioBytes: audioBytes);
    await transcribeAndRewrite();
  }

  /// Text fallback: skip ASR, advance directly to rewrite.
  Future<void> useTextInput(String text) async {
    final normalized = normalizeCraftText(text);
    state = state.copyWith(
      rawTranscript: normalized.isEmpty ? null : normalized,
      sourceText: text,
      isTranscribing: false,
      clearFailure: true,
    );
    if (normalized.isEmpty) return;
    await _rewriteTranscript(normalized);
  }

  /// ASR transcription + LLM rewrite pipeline.
  Future<void> transcribeAndRewrite() async {
    final audio = state.capturedAudioBytes;
    if (audio == null) return;

    state = state.copyWith(isTranscribing: true, clearFailure: true);

    final transcript = await runCraftAiCall<String>(
      logLabel: 'craft.asr',
      surface: 'ASR',
      call: () => ref
          .read(craftTranscriberProvider)
          .transcribe(audioBytes: audio, language: state.sourceLanguage),
      genericFailure: () => const CraftAsrFailure(),
      clearTranslating: false,
      clearTranscribing: true,
    );
    if (transcript == null) return;

    if (transcript.trim().length < craftMinTextLength) {
      state = state.copyWith(
        isTranscribing: false,
        rawTranscript: transcript.isEmpty ? null : transcript,
        failure: const CraftEmptyTranscriptFailure(),
      );
      return;
    }

    state = state.copyWith(rawTranscript: transcript);
    await _rewriteTranscript(transcript);
  }

  /// Internal: run LLM rewrite on [rawTranscript] → [translatedText].
  Future<void> _rewriteTranscript(String transcript) async {
    final src = state.sourceLanguage;
    final target = state.targetLanguage;

    state = state.copyWith(
      isTranslating: true,
      stage: CraftStage.rewrite,
      clearFailure: true,
    );

    await runCraftAiCall<String>(
      logLabel: 'craft.rewrite',
      surface: 'Rewrite',
      call: () => ref
          .read(craftTranslatorProvider)
          .translate(
            text: transcript,
            sourceLanguage: src ?? target,
            targetLanguage: target,
            style: state.style,
            customPrompt: state.customPrompt,
          ),
      onSuccess: (translated) => state.copyWith(
        translatedText: translated,
        rewrittenFromTranscript: transcript,
        isTranslating: false,
        isTranscribing: false,
        stage: CraftStage.rewrite,
        selectedVoice: voiceMatchingLanguage(target, state.selectedVoice),
        synthLanguage: target,
      ),
      genericFailure: () => const CraftTranslateFailure(),
      clearTranscribing: true,
    );
  }

  /// Re-run the LLM rewrite on existing transcript with current style.
  Future<void> regenerate() async {
    final transcript = state.rawTranscript;
    if (transcript == null) return;
    final normalized = normalizeCraftText(transcript);
    if (normalized.length < craftMinTextLength) return;
    state = state.copyWith(generation: state.generation + 1);
    await _rewriteTranscript(normalized);
  }
}
