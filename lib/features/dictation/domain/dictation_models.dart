import 'package:flutter/foundation.dart';
import 'package:enjoy_player/data/db/app_database.dart';

enum DictationInputMode { voice, text }

enum DictationAttemptStatus {
  idle,
  recordingVoice,
  transcribingVoice,
  checked,
  failed,
}

enum DictationWordDiffOp { correct, missed, extra }

@immutable
class DictationScope {
  const DictationScope({
    required this.targetType,
    required this.targetId,
    required this.referenceStartMs,
    required this.referenceDurationMs,
    required this.referenceText,
    required this.language,
  });

  final String targetType;
  final String targetId;
  final int referenceStartMs;
  final int referenceDurationMs;
  final String referenceText;
  final String language;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DictationScope &&
          runtimeType == other.runtimeType &&
          targetType == other.targetType &&
          targetId == other.targetId &&
          referenceStartMs == other.referenceStartMs &&
          referenceDurationMs == other.referenceDurationMs &&
          referenceText == other.referenceText &&
          language == other.language;

  @override
  int get hashCode => Object.hash(
    targetType,
    targetId,
    referenceStartMs,
    referenceDurationMs,
    referenceText,
    language,
  );
}

@immutable
class DictationDiffToken {
  const DictationDiffToken({required this.word, required this.op});

  final String word;
  final DictationWordDiffOp op;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DictationDiffToken &&
          runtimeType == other.runtimeType &&
          word == other.word &&
          op == other.op;

  @override
  int get hashCode => Object.hash(word, op);
}

@immutable
class DictationDiffResult {
  const DictationDiffResult({
    required this.tokens,
    required this.accuracy,
    required this.correctWords,
    required this.missedWords,
    required this.extraWords,
  });

  final List<DictationDiffToken> tokens;
  final int accuracy;
  final int correctWords;
  final int missedWords;
  final int extraWords;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DictationDiffResult &&
          runtimeType == other.runtimeType &&
          listEquals(tokens, other.tokens) &&
          accuracy == other.accuracy &&
          correctWords == other.correctWords &&
          missedWords == other.missedWords &&
          extraWords == other.extraWords;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(tokens),
    accuracy,
    correctWords,
    missedWords,
    extraWords,
  );
}

@immutable
class DictationBandWord {
  const DictationBandWord({
    required this.text,
    required this.blockWidth,
    required this.startMs,
    required this.endMs,
  });

  final String text;
  final double blockWidth;
  final int startMs;
  final int endMs;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DictationBandWord &&
          runtimeType == other.runtimeType &&
          text == other.text &&
          blockWidth == other.blockWidth &&
          startMs == other.startMs &&
          endMs == other.endMs;

  @override
  int get hashCode => Object.hash(text, blockWidth, startMs, endMs);
}

@immutable
class DictationSessionState {
  const DictationSessionState({
    this.mode = DictationInputMode.voice,
    this.status = DictationAttemptStatus.idle,
    this.textDraft = '',
    this.activeDiff,
    this.selectedTake,
    this.selectedHistoricalAttempt,
    this.lastVoiceRecording,
    this.errorMessage,
  });

  final DictationInputMode mode;
  final DictationAttemptStatus status;
  final String textDraft;
  final DictationDiffResult? activeDiff;
  final RecordingRow? selectedTake;
  final DictationRow? selectedHistoricalAttempt;
  final RecordingRow? lastVoiceRecording;
  final String? errorMessage;

  DictationSessionState copyWith({
    DictationInputMode? mode,
    DictationAttemptStatus? status,
    String? textDraft,
    DictationDiffResult? Function()? activeDiff,
    RecordingRow? Function()? selectedTake,
    DictationRow? Function()? selectedHistoricalAttempt,
    RecordingRow? Function()? lastVoiceRecording,
    String? Function()? errorMessage,
  }) => DictationSessionState(
    mode: mode ?? this.mode,
    status: status ?? this.status,
    textDraft: textDraft ?? this.textDraft,
    activeDiff: activeDiff != null ? activeDiff() : this.activeDiff,
    selectedTake: selectedTake != null ? selectedTake() : this.selectedTake,
    selectedHistoricalAttempt: selectedHistoricalAttempt != null
        ? selectedHistoricalAttempt()
        : this.selectedHistoricalAttempt,
    lastVoiceRecording: lastVoiceRecording != null
        ? lastVoiceRecording()
        : this.lastVoiceRecording,
    errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
  );
}
