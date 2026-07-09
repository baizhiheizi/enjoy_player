/// Craft controller: orchestrates translate → synthesize → save pipeline.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/data/api/api_exception.dart';
import 'package:enjoy_player/features/ai/application/ai_services.dart';
import 'package:enjoy_player/features/ai/domain/byok_not_configured_failure.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/craft/data/craft_translation_service_translator.dart';
import 'package:enjoy_player/features/craft/data/craft_tts_service_synthesizer.dart';
import 'package:enjoy_player/features/craft/domain/craft_failure.dart';
import 'package:enjoy_player/features/craft/domain/craft_job_status.dart';
import 'package:enjoy_player/features/craft/domain/craft_job_state.dart';
import 'package:enjoy_player/features/craft/domain/craft_mode.dart';
import 'package:enjoy_player/features/craft/domain/craft_request.dart';
import 'package:enjoy_player/features/craft/domain/craft_synthesizer.dart';
import 'package:enjoy_player/features/craft/domain/craft_translator.dart';
import 'package:enjoy_player/features/library/application/library_repository_provider.dart';

/// Provider for the Craft synthesizer (wraps TtsService).
final craftSynthesizerProvider = Provider<CraftSynthesizer>((ref) {
  return CraftTtsServiceSynthesizer(ref.read(ttsServiceProvider));
});

/// Provider for the Craft translator (wraps TranslationService).
final craftTranslatorProvider = Provider<CraftTranslator>((ref) {
  return CraftTranslationServiceTranslator(
    ref.read(translationServiceProvider),
  );
});

/// Craft controller state + pipeline orchestration.
///
/// Manages the full Craft lifecycle: text input → (optional translate) →
/// synthesize → save to library. Discards all intermediate results on
/// failure so no orphan transcripts or audio files are left behind.
class CraftController extends Notifier<CraftJobState> {
  @override
  CraftJobState build() => const CraftJobState();

  void selectMode(CraftMode mode) {
    state = state.copyWith(mode: mode, failure: null);
  }

  void setText(String text) {
    state = state.copyWith(text: text, failure: null);
  }

  void setSourceLanguage(String? language) {
    state = state.copyWith(sourceLanguage: language, failure: null);
  }

  void setTargetLanguage(String language) {
    state = state.copyWith(targetLanguage: language, failure: null);
  }

  void reset() {
    state = const CraftJobState();
  }

  /// Whether the current input is valid enough to submit.
  bool get canSubmit {
    final normalized = normalizeCraftText(state.text);
    return normalized.length >= craftMinTextLength && !state.isRunning;
  }

  /// Whether same-language suggestion should fire (Translate then speak only).
  bool get shouldSuggestSpeakDirectly {
    if (state.mode != CraftMode.translateThenSpeak) return false;
    final src = state.sourceLanguage;
    if (src == null || src.isEmpty) return false;
    return _sameBaseLanguage(src, state.targetLanguage) &&
        state.text.length > 50;
  }

  /// Whether the text exceeds the length cap.
  bool get isOverLengthCap {
    final normalized = normalizeCraftText(state.text);
    return normalized.length > craftMaxTextLength;
  }

  /// Runs the full Craft pipeline. Returns the new media id on success,
  /// or `null` on failure (state.failure is set) or dedupe (state.dedupedExistingId is set).
  Future<String?> submit() async {
    if (!canSubmit) return null;

    final generation = state.generation + 1;
    state = state.copyWith(
      status: CraftJobStatus.validating,
      failure: null,
      generation: generation,
      resultMediaId: null,
      dedupedExistingId: null,
      synthesizedAudioBytes: null,
      synthesizedFormat: null,
      translatedText: null,
    );

    // Check sign-in.
    final auth = ref.read(authCtrlProvider).valueOrNull;
    if (auth is! AuthSignedIn) {
      state = state.copyWith(
        status: CraftJobStatus.failed,
        failure: const CraftSignInRequiredFailure(),
      );
      return null;
    }

    final normalized = normalizeCraftText(state.text);
    final truncated = normalized.length > craftMaxTextLength
        ? normalized.substring(0, craftMaxTextLength)
        : normalized;

    // Check dedupe BEFORE any AI calls.
    final repo = ref.read(mediaLibraryRepositoryProvider);
    final existingId = await repo.findExistingCrafted(
      learningLanguage: state.targetLanguage,
      normalizedText: truncated,
      sourceFlag: state.mode.sourceFlag,
    );
    if (existingId != null) {
      state = state.copyWith(
        status: CraftJobStatus.completed,
        dedupedExistingId: existingId,
        generation: generation,
      );
      return existingId;
    }

    // Translate (Translate then speak only, and only when languages differ).
    String synthesisInput = truncated;
    if (state.mode == CraftMode.translateThenSpeak &&
        state.sourceLanguage != null &&
        !_sameBaseLanguage(state.sourceLanguage!, state.targetLanguage)) {
      state = state.copyWith(status: CraftJobStatus.translating);
      try {
        final translator = ref.read(craftTranslatorProvider);
        synthesisInput = await translator.translate(
          text: truncated,
          sourceLanguage: state.sourceLanguage!,
          targetLanguage: state.targetLanguage,
        );
        state = state.copyWith(translatedText: synthesisInput);
      } catch (e) {
        state = state.copyWith(
          status: CraftJobStatus.failed,
          failure: _mapFailure(e, CraftStage.translate),
        );
        return null;
      }
    }

    // Synthesize.
    state = state.copyWith(status: CraftJobStatus.synthesizing);
    CraftSynthesisResult synthesisResult;
    try {
      final synthesizer = ref.read(craftSynthesizerProvider);
      synthesisResult = await synthesizer.synthesize(
        text: synthesisInput,
        language: state.targetLanguage,
      );
    } catch (e) {
      state = state.copyWith(
        status: CraftJobStatus.failed,
        failure: _mapFailure(e, CraftStage.synthesize),
      );
      return null;
    }

    // Save to library.
    state = state.copyWith(status: CraftJobStatus.saving);
    try {
      final mediaId = await repo.importCraftedFromText(
        audioBytes: synthesisResult.audioBytes,
        audioFormat: synthesisResult.format,
        learningLanguage: state.targetLanguage,
        sourceLanguage: state.mode == CraftMode.translateThenSpeak
            ? state.sourceLanguage
            : null,
        text: state.text,
        normalizedText: truncated,
        sourceFlag: state.mode.sourceFlag,
        signedInUserId: auth.profile.id,
      );
      state = state.copyWith(
        status: CraftJobStatus.completed,
        resultMediaId: mediaId,
        generation: generation,
      );
      return mediaId;
    } catch (e) {
      state = state.copyWith(
        status: CraftJobStatus.failed,
        failure: _mapFailure(e, CraftStage.save),
      );
      return null;
    }
  }

  bool _sameBaseLanguage(String a, String b) {
    final aBase = a.split('-').first.toLowerCase();
    final bBase = b.split('-').first.toLowerCase();
    return aBase == bBase;
  }

  CraftFailure _mapFailure(Object error, CraftStage stage) {
    switch (stage) {
      case CraftStage.translate:
        return const CraftTranslateFailure();
      case CraftStage.synthesize:
        if (error is ByokNotConfiguredFailure) {
          return const CraftTtsFailure(
            action: CraftFailureAction.openAiSettings,
          );
        }
        if (error is ApiException && error.statusCode == 401) {
          return const CraftTtsFailure(
            action: CraftFailureAction.openAiSettings,
          );
        }
        return const CraftTtsFailure();
      case CraftStage.save:
        return const CraftSaveFailure();
    }
  }
}

enum CraftStage { translate, synthesize, save }

/// Notifier provider for [CraftController]. Reset via `controller.reset()`
/// at sheet open to get fresh state per session.
final craftControllerProvider =
    NotifierProvider<CraftController, CraftJobState>(CraftController.new);
