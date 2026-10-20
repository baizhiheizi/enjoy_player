/// Craft controller: two-tool state (Translate + Synthesize) on one screen.
///
/// The controller is assembled from one mixin per pipeline so no single file
/// owns the whole Craft surface:
///
/// - [`CraftControllerCore`](craft_controller_core.dart) — hydration latch and
///   the shared language / voice helpers.
/// - [`CraftTranslateMixin`](craft_translate_stage.dart) — text inputs and the
///   translation pipeline.
/// - [`CraftSynthesizeMixin`](craft_synthesize_stage.dart) — voice inputs, the
///   TTS pipeline, and the audio handoff.
/// - [`CraftCaptureMixin`](craft_capture_stage.dart) — Express capture, ASR,
///   and the transcript rewrite.
/// - [`CraftLibraryMixin`](craft_library_stage.dart) — library save, dedup, and
///   edit restore.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/application/app_language_catalog.dart';
import 'package:enjoy_player/core/application/app_preferences_provider.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/features/craft/application/craft_capture_stage.dart';
import 'package:enjoy_player/features/craft/application/craft_controller_core.dart';
import 'package:enjoy_player/features/craft/application/craft_library_stage.dart';
import 'package:enjoy_player/features/craft/application/craft_preferences_provider.dart';
import 'package:enjoy_player/features/craft/application/craft_synthesize_stage.dart';
import 'package:enjoy_player/features/craft/application/craft_translate_stage.dart';
import 'package:enjoy_player/features/craft/domain/azure_voice.dart';
import 'package:enjoy_player/features/craft/domain/craft_job_state.dart';
import 'package:enjoy_player/features/craft/domain/craft_save_result.dart';
import 'package:enjoy_player/features/craft/domain/craft_screen_mode.dart';
import 'package:enjoy_player/features/craft/domain/craft_stage.dart';

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
        CraftCaptureMixin,
        CraftLibraryMixin {
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
