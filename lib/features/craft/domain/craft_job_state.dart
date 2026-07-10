/// In-memory Craft job state for the two-tool Craft screen.
library;

import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import 'craft_failure.dart';
import 'craft_mode.dart';
import 'translation_style.dart';

/// The full state of one Craft session — covers both Translate and
/// Synthesize tools on the same screen.
@immutable
class CraftJobState {
  const CraftJobState({
    // Translate tool
    this.sourceText = '',
    this.sourceLanguage,
    this.targetLanguage = 'en',
    this.style = TranslationStyle.natural,
    this.customPrompt,
    this.translatedText,
    this.isTranslating = false,
    // Synthesize tool
    this.synthText = '',
    this.synthLanguage = 'en',
    this.selectedVoice,
    this.previewAudioBytes,
    this.previewFormat,
    this.isSynthesizing = false,
    this.isSaving = false,
    // Result
    this.resultMediaId,
    this.dedupedExistingId,
    this.failure,
    this.generation = 0,
  });

  // --- Translate tool ---
  final String sourceText;
  final String? sourceLanguage;
  final String targetLanguage;
  final TranslationStyle style;
  final String? customPrompt;
  final String? translatedText;
  final bool isTranslating;

  // --- Synthesize tool ---
  final String synthText;
  final String synthLanguage;
  final String? selectedVoice;
  final Uint8List? previewAudioBytes;
  final String? previewFormat;
  final bool isSynthesizing;
  final bool isSaving;

  // --- Result ---
  final String? resultMediaId;
  final String? dedupedExistingId;
  final CraftFailure? failure;
  final int generation;

  // --- Derived ---
  bool get isBusy => isTranslating || isSynthesizing || isSaving;
  bool get hasPreview => previewAudioBytes != null;
  bool get hasTranslation =>
      translatedText != null && translatedText!.isNotEmpty;

  CraftJobState copyWith({
    String? sourceText,
    String? sourceLanguage,
    String? targetLanguage,
    TranslationStyle? style,
    String? customPrompt,
    String? translatedText,
    bool? isTranslating,
    String? synthText,
    String? synthLanguage,
    String? selectedVoice,
    Uint8List? previewAudioBytes,
    String? previewFormat,
    bool? isSynthesizing,
    bool? isSaving,
    String? resultMediaId,
    String? dedupedExistingId,
    CraftFailure? failure,
    int? generation,
    bool clearPreview = false,
    bool clearFailure = false,
  }) {
    return CraftJobState(
      sourceText: sourceText ?? this.sourceText,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      style: style ?? this.style,
      customPrompt: customPrompt ?? this.customPrompt,
      translatedText: translatedText ?? this.translatedText,
      isTranslating: isTranslating ?? this.isTranslating,
      synthText: synthText ?? this.synthText,
      synthLanguage: synthLanguage ?? this.synthLanguage,
      selectedVoice: selectedVoice ?? this.selectedVoice,
      previewAudioBytes: clearPreview
          ? null
          : (previewAudioBytes ?? this.previewAudioBytes),
      previewFormat: clearPreview
          ? null
          : (previewFormat ?? this.previewFormat),
      isSynthesizing: isSynthesizing ?? this.isSynthesizing,
      isSaving: isSaving ?? this.isSaving,
      resultMediaId: resultMediaId ?? this.resultMediaId,
      dedupedExistingId: dedupedExistingId ?? this.dedupedExistingId,
      failure: clearFailure ? null : (failure ?? this.failure),
      generation: generation ?? this.generation,
    );
  }
}
