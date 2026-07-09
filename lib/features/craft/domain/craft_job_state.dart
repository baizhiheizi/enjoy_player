/// In-memory Craft job state owned by [CraftController].
library;

import 'package:flutter/foundation.dart';

import 'craft_failure.dart';
import 'craft_job_status.dart';
import 'craft_mode.dart';

/// The full state of one Craft session.
///
/// Owned in-memory by the Craft controller; never persisted to Drift.
@immutable
class CraftJobState {
  const CraftJobState({
    this.status = CraftJobStatus.idle,
    this.mode = CraftMode.speakDirectly,
    this.text = '',
    this.sourceLanguage,
    this.targetLanguage = 'en',
    this.failure,
    this.generation = 0,
    this.resultMediaId,
    this.dedupedExistingId,
    this.synthesizedAudioBytes,
    this.synthesizedFormat,
    this.translatedText,
  });

  final CraftJobStatus status;
  final CraftMode mode;
  final String text;

  /// Source language for Translate then speak; `null` for Speak directly.
  final String? sourceLanguage;
  final String targetLanguage;
  final CraftFailure? failure;
  final int generation;

  /// Set when status == completed.
  final String? resultMediaId;

  /// Set when the same content hash already exists in the library.
  final String? dedupedExistingId;

  /// In-flight synthesized audio bytes (held until save succeeds).
  final Uint8List? synthesizedAudioBytes;
  final String? synthesizedFormat;

  /// In-flight translated text for the learning language (Translate then speak).
  final String? translatedText;

  /// Whether the text input meets the minimum length requirement.
  bool get canSubmit =>
      status == CraftJobStatus.idle || status == CraftJobStatus.failed;

  /// Whether a job is currently running.
  bool get isRunning =>
      status == CraftJobStatus.validating ||
      status == CraftJobStatus.translating ||
      status == CraftJobStatus.synthesizing ||
      status == CraftJobStatus.saving;

  CraftJobState copyWith({
    CraftJobStatus? status,
    CraftMode? mode,
    String? text,
    String? sourceLanguage,
    String? targetLanguage,
    CraftFailure? failure,
    int? generation,
    String? resultMediaId,
    String? dedupedExistingId,
    Uint8List? synthesizedAudioBytes,
    String? synthesizedFormat,
    String? translatedText,
  }) {
    return CraftJobState(
      status: status ?? this.status,
      mode: mode ?? this.mode,
      text: text ?? this.text,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      failure: failure ?? this.failure,
      generation: generation ?? this.generation,
      resultMediaId: resultMediaId ?? this.resultMediaId,
      dedupedExistingId: dedupedExistingId ?? this.dedupedExistingId,
      synthesizedAudioBytes:
          synthesizedAudioBytes ?? this.synthesizedAudioBytes,
      synthesizedFormat: synthesizedFormat ?? this.synthesizedFormat,
      translatedText: translatedText ?? this.translatedText,
    );
  }

  /// Clears failure/result fields for a fresh attempt.
  CraftJobState clearTransient() => copyWith(
    status: CraftJobStatus.idle,
    failure: null,
    resultMediaId: null,
    dedupedExistingId: null,
    synthesizedAudioBytes: null,
    synthesizedFormat: null,
    translatedText: null,
  );
}
