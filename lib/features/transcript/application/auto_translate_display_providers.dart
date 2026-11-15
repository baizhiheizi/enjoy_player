/// The auto-translate display state the transcript hosts derive.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'active_transcript_provider.dart';
import 'auto_translate_controller.dart';

part 'auto_translate_display_providers.g.dart';

/// Whether the auto-translate AI track is the live secondary for [mediaId],
/// plus the source → target pair its lines render with — the derivation both
/// transcript hosts (the echo merged card and the scrollable list) previously
/// re-spelled field by field.
@riverpod
({bool active, String? sourceLanguage, String? targetLanguage})
autoTranslateDisplayState(Ref ref, String mediaId) {
  final mode = ref.watch(
    autoTranslateCtrlProvider(mediaId).select(
      (s) => (
        isActive: s.isActive,
        aiTranscriptId: s.aiTranscriptId,
        sourceLanguage: s.sourceLanguage,
        targetLanguage: s.targetLanguage,
      ),
    ),
  );
  final secondaryId = ref.watch(secondaryTranscriptIdProvider(mediaId)).value;
  return (
    active:
        mode.isActive &&
        mode.aiTranscriptId != null &&
        secondaryId == mode.aiTranscriptId,
    sourceLanguage: mode.sourceLanguage,
    targetLanguage: mode.targetLanguage,
  );
}
