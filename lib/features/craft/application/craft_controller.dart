/// Craft controller: two-tool state (Translate + Synthesize) on one screen.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/data/api/api_exception.dart';
import 'package:enjoy_player/features/ai/application/ai_services.dart';
import 'package:enjoy_player/features/ai/domain/byok_not_configured_failure.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/craft/data/craft_translation_service_translator.dart';
import 'package:enjoy_player/features/craft/data/craft_tts_service_synthesizer.dart';
import 'package:enjoy_player/features/craft/domain/azure_voice.dart';
import 'package:enjoy_player/features/craft/domain/craft_failure.dart';
import 'package:enjoy_player/features/craft/domain/craft_job_state.dart';
import 'package:enjoy_player/features/craft/domain/craft_request.dart';
import 'package:enjoy_player/features/craft/domain/craft_synthesizer.dart';
import 'package:enjoy_player/features/craft/domain/craft_translator.dart';
import 'package:enjoy_player/features/craft/domain/transcript_timestamp_estimator.dart';
import 'package:enjoy_player/features/craft/domain/translation_style.dart';
import 'package:enjoy_player/features/craft/domain/wav_duration.dart';
import 'package:enjoy_player/features/library/application/library_repository_provider.dart';

/// Provider for the Craft synthesizer (wraps TtsService).
final craftSynthesizerProvider = Provider<CraftSynthesizer>((ref) {
  return CraftTtsServiceSynthesizer(ref.read(ttsServiceProvider));
});

/// Provider for the Craft translator (wraps ChatService / LLM API).
final craftTranslatorProvider = Provider<CraftTranslator>((ref) {
  return CraftTranslationServiceTranslator(ref.read(chatServiceProvider));
});

/// Two-tool Craft controller for the full-screen Craft route.
class CraftController extends Notifier<CraftJobState> {
  @override
  CraftJobState build() => const CraftJobState();

  // === Translate tool actions ===

  void setSourceText(String text) {
    state = state.copyWith(sourceText: text, clearFailure: true);
  }

  void setSourceLanguage(String? lang) {
    state = state.copyWith(sourceLanguage: lang, clearFailure: true);
  }

  void setTargetLanguage(String lang) {
    state = state.copyWith(targetLanguage: lang, clearFailure: true);
  }

  void setStyle(TranslationStyle style) {
    state = state.copyWith(style: style, clearFailure: true);
  }

  void setCustomPrompt(String? prompt) {
    state = state.copyWith(customPrompt: prompt, clearFailure: true);
  }

  /// Inline edit of the translated result.
  void setTranslatedText(String text) {
    state = state.copyWith(translatedText: text);
  }

  void swapLanguages() {
    final src = state.sourceLanguage;
    state = state.copyWith(
      sourceLanguage: state.targetLanguage,
      targetLanguage: src ?? state.targetLanguage,
      translatedText: null,
    );
  }

  /// Copy the translated text into the synthesize tool's input.
  void useTranslatedText() {
    if (state.translatedText != null && state.translatedText!.isNotEmpty) {
      state = state.copyWith(
        synthText: state.translatedText!,
        synthLanguage: state.targetLanguage,
      );
    }
  }

  Future<void> translate() async {
    final normalized = normalizeCraftText(state.sourceText);
    if (normalized.length < craftMinTextLength) return;

    final src = state.sourceLanguage;
    if (src == null || src.isEmpty) return;

    // Same-language guard.
    if (_sameBaseLanguage(src, state.targetLanguage)) {
      state = state.copyWith(failure: const CraftSameLanguageFailure());
      return;
    }

    state = state.copyWith(isTranslating: true, clearFailure: true);

    try {
      final translator = ref.read(craftTranslatorProvider);
      final result = await translator.translate(
        text: normalized,
        sourceLanguage: src,
        targetLanguage: state.targetLanguage,
        style: state.style,
        customPrompt: state.customPrompt,
      );
      state = state.copyWith(translatedText: result, isTranslating: false);
    } catch (e, st) {
      logNamed('craft.translate').warning('Translate failed: $e', e, st);
      state = state.copyWith(
        isTranslating: false,
        failure: const CraftTranslateFailure(),
      );
    }
  }

  // === Synthesize tool actions ===

  void setSynthText(String text) {
    state = state.copyWith(synthText: text, clearFailure: true);
  }

  void setSynthLanguage(String lang) {
    // Auto-pick default voice for the new language if current voice doesn't match.
    final voices = voicesForLanguage(lang.split('-').first.toLowerCase());
    final currentVoice = state.selectedVoice;
    final voiceMatches =
        currentVoice != null && voices.any((v) => v.id == currentVoice);
    state = state.copyWith(
      synthLanguage: lang,
      selectedVoice: voiceMatches
          ? currentVoice
          : defaultVoiceForLanguage(lang.split('-').first.toLowerCase())?.id,
      clearPreview: true,
      clearFailure: true,
    );
  }

  void setSelectedVoice(String? voice) {
    state = state.copyWith(selectedVoice: voice, clearPreview: true);
  }

  Future<void> synthesize() async {
    final normalized = normalizeCraftText(state.synthText);
    if (normalized.length < craftMinTextLength) return;

    // Check sign-in.
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
        isSynthesizing: false,
      );
    } catch (e, st) {
      logNamed('craft.synthesize').warning('Synthesize failed: $e', e, st);
      state = state.copyWith(isSynthesizing: false, failure: _mapTtsFailure(e));
    }
  }

  // === Save action ===

  Future<String?> saveToLibrary() async {
    if (state.previewAudioBytes == null) return null;

    final auth = ref.read(authCtrlProvider).valueOrNull;
    if (auth is! AuthSignedIn) {
      state = state.copyWith(failure: const CraftSignInRequiredFailure());
      return null;
    }

    state = state.copyWith(isSaving: true, clearFailure: true);

    try {
      final normalized = normalizeCraftText(state.synthText);
      final truncated = normalized.length > craftMaxTextLength
          ? normalized.substring(0, craftMaxTextLength)
          : normalized;

      // Parse actual audio duration from WAV header for accurate timestamps.
      final audioDurationMs = wavDurationMs(state.previewAudioBytes!);
      final timelineJson = encodeTimelineJson(
        text: truncated,
        totalDurationMs: audioDurationMs > 0
            ? audioDurationMs
            : (truncated.length / 12.5 * 1000).round(),
      );

      // Determine if this is a translate-then-synthesize or direct synthesize.
      final hasSourceLang =
          state.sourceLanguage != null &&
          state.sourceLanguage!.isNotEmpty &&
          state.translatedText != null &&
          state.translatedText!.isNotEmpty;
      final sourceFlag = hasSourceLang ? 'craft-translate' : 'craft-direct';

      final repo = ref.read(mediaLibraryRepositoryProvider);

      // Check dedupe before writing.
      final existingId = await repo.findExistingCrafted(
        learningLanguage: state.synthLanguage,
        normalizedText: truncated,
        sourceFlag: sourceFlag,
        voice: state.selectedVoice,
      );
      if (existingId != null) {
        state = state.copyWith(isSaving: false, dedupedExistingId: existingId);
        return existingId;
      }

      final mediaId = await repo.importCraftedFromText(
        audioBytes: state.previewAudioBytes!,
        audioFormat: state.previewFormat ?? 'wav',
        learningLanguage: state.synthLanguage,
        sourceLanguage: hasSourceLang ? state.sourceLanguage : null,
        text: state.synthText,
        normalizedText: truncated,
        sourceFlag: sourceFlag,
        signedInUserId: auth.profile.id,
        primaryTimelineJson: timelineJson,
        voice: state.selectedVoice,
      );

      state = state.copyWith(isSaving: false, resultMediaId: mediaId);
      return mediaId;
    } catch (e, st) {
      logNamed('craft.save').warning('Save failed: $e', e, st);
      state = state.copyWith(
        isSaving: false,
        failure: const CraftSaveFailure(),
      );
      return null;
    }
  }

  void clearResult() {
    state = state.copyWith(
      resultMediaId: null,
      dedupedExistingId: null,
      clearFailure: true,
    );
  }

  // === Helpers ===

  bool _sameBaseLanguage(String a, String b) {
    final aBase = a.split('-').first.toLowerCase();
    final bBase = b.split('-').first.toLowerCase();
    return aBase == bBase;
  }

  CraftFailure _mapTtsFailure(Object error) {
    if (error is ByokNotConfiguredFailure) {
      return const CraftTtsFailure(action: CraftFailureAction.openAiSettings);
    }
    if (error is ApiException && error.statusCode == 401) {
      return const CraftTtsFailure(action: CraftFailureAction.openAiSettings);
    }
    return const CraftTtsFailure();
  }
}

/// Notifier provider for [CraftController].
final craftControllerProvider =
    NotifierProvider<CraftController, CraftJobState>(CraftController.new);
