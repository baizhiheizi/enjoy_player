/// Craft controller: two-tool state (Translate + Synthesize) on one screen.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/analytics/analytics_events.dart';
import 'package:enjoy_player/core/analytics/analytics_provider.dart';
import 'package:enjoy_player/core/application/app_language_catalog.dart';
import 'package:enjoy_player/core/application/app_preferences_provider.dart';
import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/craft/application/craft_capture_stage.dart';
import 'package:enjoy_player/features/craft/application/craft_controller_core.dart';
import 'package:enjoy_player/features/craft/application/craft_library_repository_provider.dart';
import 'package:enjoy_player/features/craft/application/craft_preferences_provider.dart';
import 'package:enjoy_player/features/craft/application/craft_synthesize_stage.dart';
import 'package:enjoy_player/features/craft/application/craft_timeline_enricher.dart';
import 'package:enjoy_player/features/craft/application/craft_translate_stage.dart';
import 'package:enjoy_player/features/craft/domain/azure_voice.dart';
import 'package:enjoy_player/features/craft/domain/craft_edit_source.dart';
import 'package:enjoy_player/features/craft/domain/craft_failure.dart';
import 'package:enjoy_player/features/craft/domain/craft_job_state.dart';
import 'package:enjoy_player/features/craft/domain/craft_request.dart';
import 'package:enjoy_player/features/craft/domain/craft_save_result.dart';
import 'package:enjoy_player/features/craft/domain/craft_screen_mode.dart';
import 'package:enjoy_player/features/craft/domain/craft_stage.dart';
import 'package:enjoy_player/features/craft/domain/translation_style.dart';
import 'package:enjoy_player/features/craft/domain/word_boundary_segmenter.dart';

export 'package:enjoy_player/features/craft/application/craft_service_providers.dart'
    show
        craftSynthesizerProvider,
        craftTranscriberProvider,
        craftTranslatorProvider;

/// Two-tool Craft controller for the full-screen Craft route.
class CraftController extends Notifier<CraftJobState>
    with
        CraftControllerCore,
        CraftTranslateMixin,
        CraftSynthesizeMixin,
        CraftCaptureMixin {
  @override
  CraftJobState build() {
    prefsHydrationMutated = false;
    final prefs = ref.read(appPreferencesCtrlProvider).valueOrNull;
    final native = canonicalMediaLanguageTag(
      prefs?.effectiveNativeLanguage ?? 'en',
    );
    final learn = canonicalMediaLanguageTag(
      prefs?.effectiveLearningLanguage ?? 'en',
    );
    unawaited(Future<void>.microtask(_hydrateFromPreferences));
    return const CraftJobState().copyWith(
      sourceLanguage: native,
      targetLanguage: learn,
    );
  }

  /// Overlay persisted craft preferences (mode / per-mode style / prompt /
  /// remembered voice). Skipped when the user already interacted (their
  /// setters write through) or when an edit-from-history restore is in
  /// flight ([loadForEdit] sets fields directly and must not be clobbered).
  Future<void> _hydrateFromPreferences() async {
    if (!ref.mounted) return;
    final prefs = await ref.read(craftPreferencesCtrlProvider.notifier).load();
    if (!ref.mounted) return;
    if (prefsHydrationMutated || state.editingMediaId != null) return;

    final base = baseLanguage(state.targetLanguage);
    final remembered = prefs.voices[base];
    final rememberedValid =
        remembered != null &&
        voicesForLanguage(base).any((v) => v.id == remembered);

    state = state.copyWith(
      screenMode: prefs.screenMode,
      style: prefs.styleFor(prefs.screenMode),
      customPrompt: prefs.customPrompt,
      selectedVoice: rememberedValid ? remembered : null,
    );
  }

  void swapLanguages() {
    prefsHydrationMutated = true;
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

  Future<CraftSaveResult?> saveToLibrary() async {
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

      final timelineJson030 = buildCraftPrimaryTimelineJson(
        state.previewWordBoundaries,
        language: state.synthLanguage,
      );
      final wroteSolid = timelineJson030 != null;

      final hasSourceLang =
          state.sourceLanguage != null &&
          state.sourceLanguage!.isNotEmpty &&
          state.translatedText != null &&
          state.translatedText!.isNotEmpty;
      final sourceFlag = state.screenMode == CraftScreenMode.express
          ? 'craft-express'
          : (hasSourceLang ? 'craft-translate' : 'craft-direct');
      final sourceTextForImport = state.screenMode == CraftScreenMode.express
          ? (state.rawTranscript ?? state.synthText)
          : state.synthText;

      final repo = ref.read(craftLibraryRepositoryProvider);

      final editingId = state.editingMediaId;
      if (editingId != null) {
        final timelineJson = await _enrichTimeline(timelineJson030);
        final mediaId = await repo.updateCraftedFromText(
          mediaId: editingId,
          audioBytes: state.previewAudioBytes!,
          audioFormat: state.previewFormat ?? 'wav',
          learningLanguage: state.synthLanguage,
          text: sourceTextForImport,
          normalizedText: truncated,
          primaryTimelineJson: timelineJson,
          voice: state.selectedVoice,
          sourceFlag: sourceFlag,
        );
        state = state.copyWith(isSaving: false, resultMediaId: mediaId);
        return CraftSaveResult(
          mediaId: mediaId,
          wroteSolidTranscript: wroteSolid,
        );
      }

      final existingId = await repo.findExistingCrafted(
        learningLanguage: state.synthLanguage,
        normalizedText: truncated,
        sourceFlag: sourceFlag,
        voice: state.selectedVoice,
      );
      if (existingId != null) {
        state = state.copyWith(isSaving: false, dedupedExistingId: existingId);
        return CraftSaveResult(
          mediaId: existingId,
          wroteSolidTranscript: false,
          wasDedupe: true,
        );
      }

      final timelineJson = await _enrichTimeline(timelineJson030);
      final mediaId = await repo.importCraftedFromText(
        audioBytes: state.previewAudioBytes!,
        audioFormat: state.previewFormat ?? 'wav',
        learningLanguage: state.synthLanguage,
        sourceLanguage: hasSourceLang ? state.sourceLanguage : null,
        text: sourceTextForImport,
        normalizedText: truncated,
        sourceFlag: sourceFlag,
        signedInUserId: auth.profile.id,
        primaryTimelineJson: timelineJson,
        voice: state.selectedVoice,
      );

      state = state.copyWith(isSaving: false, resultMediaId: mediaId);
      ref
          .read(analyticsProvider)
          .capture(
            AnalyticsEvents.craftProjectCreated,
            properties: AnalyticsEvents.craftCreated(
              mode: sourceFlag == 'craft-express'
                  ? AnalyticsEvents.modeCapture
                  : AnalyticsEvents.modeFromText,
            ),
          );
      return CraftSaveResult(
        mediaId: mediaId,
        wroteSolidTranscript: wroteSolid,
      );
    } catch (e, st) {
      logNamed('craft.save').warning('Save failed: $e', e, st);
      state = state.copyWith(
        isSaving: false,
        failure: const CraftSaveFailure(),
      );
      return null;
    }
  }

  Future<String?> _enrichTimeline(String? timelineJson) {
    return ref
        .read(craftTimelineEnricherProvider)
        .enrich(
          timelineJson: timelineJson,
          audioBytes: state.previewAudioBytes!,
          language: state.synthLanguage,
        );
  }

  void clearResult() {
    state = state.copyWith(
      resultMediaId: null,
      dedupedExistingId: null,
      clearFailure: true,
    );
  }

  /// Loads an existing Crafted item for editing and prefills the working
  /// state so [saveToLibrary] updates it in place instead of creating a
  /// new library entry.
  ///
  /// Returns `false` when the item no longer exists (e.g. deleted from
  /// another device) — callers should surface a "no longer available"
  /// message and avoid navigating to the Craft screen.
  Future<bool> loadForEdit(String mediaId) async {
    final repo = ref.read(craftLibraryRepositoryProvider);
    final CraftEditSource? source = await repo.getCraftEditSource(mediaId);
    if (source == null) return false;

    final matchedVoice = voiceMatchingLanguage(source.language, source.voice);
    final isExpress =
        source.sourceFlag == 'craft-express' &&
        source.sourceText != null &&
        source.sourceText!.isNotEmpty;

    if (isExpress) {
      state = state.copyWith(
        editingMediaId: mediaId,
        screenMode: CraftScreenMode.express,
        stage: CraftStage.rewrite,
        style: TranslationStyle.auto,
        rawTranscript: source.sourceText,
        rewrittenFromTranscript: source.sourceText,
        sourceText: source.sourceText ?? '',
        translatedText: source.practiceText,
        synthText: source.practiceText,
        targetLanguage: source.language,
        synthLanguage: source.language,
        selectedVoice: matchedVoice,
        clearPreview: true,
        clearResultMediaId: true,
        clearDedupedExistingId: true,
        clearFailure: true,
      );
      return true;
    }

    state = state.copyWith(
      editingMediaId: mediaId,
      screenMode: CraftScreenMode.advanced,
      sourceText: source.sourceText ?? '',
      synthText: source.practiceText,
      targetLanguage: source.language,
      synthLanguage: source.language,
      selectedVoice: matchedVoice,
      clearPreview: true,
      clearResultMediaId: true,
      clearDedupedExistingId: true,
      clearFailure: true,
      clearTranslatedText: true,
    );
    return true;
  }

  /// Switch between Express and Advanced screen layouts.
  /// Resets all working state so each mode starts fresh, restores the
  /// remembered translation style for the target mode, and persists the
  /// choice for the next session.
  void setScreenMode(CraftScreenMode mode) {
    if (mode == state.screenMode) return;
    prefsHydrationMutated = true;
    final rememberedStyle = ref
        .read(craftPreferencesCtrlProvider)
        .styleFor(mode);
    state = _clearWorkingState().copyWith(
      screenMode: mode,
      style: rememberedStyle,
    );
    unawaited(
      ref.read(craftPreferencesCtrlProvider.notifier).setScreenMode(mode),
    );
  }

  /// Save current item, then reset for the next capture.
  /// If the save fails, the failure is already in [state.failure] —
  /// we return early so the user's work is NOT destroyed.
  ///
  /// Returns the save outcome (including whether a solid transcript was
  /// written) so callers can show hints before the reset clears preview.
  Future<CraftSaveResult?> saveAndCaptureNext() async {
    final result = await saveToLibrary();
    if (result == null) return null;
    resetForNextCapture();
    return result;
  }

  /// Clear Express working data, preserve session preferences.
  void resetForNextCapture() {
    state = _clearWorkingState();
  }

  /// Working-state reset shared by screen-mode switches and next-capture
  /// resets.
  CraftJobState _clearWorkingState() {
    return state.copyWith(
      stage: CraftStage.capture,
      isCapturing: false,
      isTranscribing: false,
      clearCapturedAudio: true,
      clearRawTranscript: true,
      clearRewrittenFromTranscript: true,
      clearTranslatedText: true,
      clearPreview: true,
      clearResultMediaId: true,
      clearDedupedExistingId: true,
      clearFailure: true,
      clearEditingMediaId: true,
      sourceText: '',
      synthText: '',
    );
  }
}

/// Notifier provider for [CraftController].
final craftControllerProvider =
    NotifierProvider<CraftController, CraftJobState>(CraftController.new);
