/// Translate stage of the Craft controller: the source-text inputs and
/// the LLM translation pipeline.
library;

import 'dart:async';

import 'package:enjoy_player/core/errors/app_failure.dart';
import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/features/craft/application/craft_controller_core.dart';
import 'package:enjoy_player/features/craft/application/craft_preferences_provider.dart';
import 'package:enjoy_player/features/craft/application/craft_service_providers.dart';
import 'package:enjoy_player/features/craft/domain/craft_failure.dart';
import 'package:enjoy_player/features/craft/domain/craft_job_state.dart';
import 'package:enjoy_player/features/craft/domain/craft_request.dart';
import 'package:enjoy_player/features/craft/domain/translation_style.dart';

/// Source-text inputs and the translation pipeline.
mixin CraftTranslateMixin on CraftControllerCore {
  void setSourceText(String text) {
    state = state.copyWith(sourceText: text, clearFailure: true);
  }

  void setSourceLanguage(String? lang) {
    prefsHydrationMutated = true;
    state = state.copyWith(sourceLanguage: lang, clearFailure: true);
  }

  void setTargetLanguage(String lang) {
    prefsHydrationMutated = true;
    state = state.copyWith(
      targetLanguage: lang,
      selectedVoice: voiceMatchingLanguage(lang, state.selectedVoice),
      clearFailure: true,
    );
  }

  void setStyle(TranslationStyle style) {
    prefsHydrationMutated = true;
    state = state.copyWith(style: style, clearFailure: true);
    unawaited(
      ref
          .read(craftPreferencesCtrlProvider.notifier)
          .setStyleFor(state.screenMode, style),
    );
  }

  void setCustomPrompt(String? prompt) {
    prefsHydrationMutated = true;
    state = state.copyWith(customPrompt: prompt, clearFailure: true);
    unawaited(
      ref.read(craftPreferencesCtrlProvider.notifier).setCustomPrompt(prompt),
    );
  }

  /// Inline edit of the translated result.
  void setTranslatedText(String text) {
    state = state.copyWith(translatedText: text);
  }

  /// Inline edit of the Express native / STT transcript.
  ///
  /// Keeps [CraftJobState.sourceText] in sync so library save continues to
  /// persist the corrected native text.
  void setRawTranscript(String text) {
    state = state.copyWith(
      rawTranscript: text,
      sourceText: text,
      clearFailure: true,
    );
  }

  Future<void> translate() async {
    final normalized = normalizeCraftText(state.sourceText);
    if (normalized.length < craftMinTextLength) return;

    final src = state.sourceLanguage;
    if (src == null || src.isEmpty) return;

    if (sameBaseLanguage(src, state.targetLanguage)) {
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
    } on CreditsFailure catch (failure, st) {
      logNamed(
        'craft.translate',
      ).warning('Translate rejected: credits', failure, st);
      state = state.copyWith(
        isTranslating: false,
        failure: CraftCreditsFailure(failure),
      );
    } catch (e, st) {
      logNamed('craft.translate').warning('Translate failed: $e', e, st);
      state = state.copyWith(
        isTranslating: false,
        failure: const CraftTranslateFailure(),
      );
    }
  }
}
