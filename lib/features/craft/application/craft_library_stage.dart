/// Library stage of the Craft controller: persisting a crafted item to
/// the library, deduplicating, and restoring a saved item for editing.
library;

import 'package:enjoy_player/core/analytics/analytics_events.dart';
import 'package:enjoy_player/core/analytics/analytics_provider.dart';
import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/features/auth/application/auth_controller.dart';
import 'package:enjoy_player/features/auth/domain/auth_state.dart';
import 'package:enjoy_player/features/craft/application/craft_controller_core.dart';
import 'package:enjoy_player/features/craft/application/craft_library_repository_provider.dart';
import 'package:enjoy_player/features/craft/application/craft_timeline_enricher.dart';
import 'package:enjoy_player/features/craft/domain/craft_edit_source.dart';
import 'package:enjoy_player/features/craft/domain/craft_failure.dart';
import 'package:enjoy_player/features/craft/domain/craft_request.dart';
import 'package:enjoy_player/features/craft/domain/craft_save_result.dart';
import 'package:enjoy_player/features/craft/domain/craft_screen_mode.dart';
import 'package:enjoy_player/features/craft/domain/craft_stage.dart';
import 'package:enjoy_player/features/craft/domain/translation_style.dart';
import 'package:enjoy_player/features/craft/domain/word_boundary_segmenter.dart';

/// Library save, deduplication, and edit restore.
mixin CraftLibraryMixin on CraftControllerCore {
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
}
