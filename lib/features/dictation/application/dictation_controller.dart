import 'dart:io';
import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/ai/application/ai_services.dart';
import 'package:enjoy_player/features/ai/domain/models/asr_request.dart';
import 'package:enjoy_player/features/dictation/domain/dictation_diff.dart';
import 'package:enjoy_player/features/dictation/domain/dictation_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class DictationController {
  DictationController({
    required this.ref,
    required this.scope,
    required this.getState,
    required this.setState,
  });

  final Ref ref;
  final DictationScope scope;
  final DictationSessionState Function() getState;
  final void Function(DictationSessionState next) setState;

  static const _uuid = Uuid();
  bool _disposed = false;
  int _transcriptionGeneration = 0;
  bool _isCheckingText = false;

  void dispose() {
    _disposed = true;
  }

  void setInputMode(DictationInputMode mode) {
    if (_disposed) return;
    final current = getState();
    if (current.mode == mode) return;
    setState(current.copyWith(mode: mode));
  }

  void updateTextDraft(String text) {
    if (_disposed) return;
    final current = getState();
    setState(current.copyWith(textDraft: text));
  }

  void tryAgain() {
    if (_disposed) return;
    final current = getState();
    setState(
      current.copyWith(
        status: DictationAttemptStatus.idle,
        activeDiff: () => null,
        selectedHistoricalAttempt: () => null,
        errorMessage: () => null,
      ),
    );
  }

  void selectHistoricalAttempt(DictationRow? attempt) {
    if (_disposed) return;
    final current = getState();
    if (attempt == null) {
      setState(current.copyWith(selectedHistoricalAttempt: () => null));
      return;
    }

    final diff = computeDictationDiff(attempt.referenceText, attempt.userInput);
    setState(
      current.copyWith(
        status: DictationAttemptStatus.checked,
        selectedHistoricalAttempt: () => attempt,
        activeDiff: () => diff,
        errorMessage: () => null,
      ),
    );
  }

  Future<void> checkTextAnswer() async {
    if (_disposed || _isCheckingText) return;
    final current = getState();
    final text = current.textDraft.trim();
    if (text.isEmpty) return;

    _isCheckingText = true;
    try {
      final diff = computeDictationDiff(scope.referenceText, text);
      final now = DateTime.now();
      final row = DictationRow(
        id: _uuid.v4(),
        targetType: scope.targetType,
        targetId: scope.targetId,
        referenceStartMs: scope.referenceStartMs,
        referenceDurationMs: scope.referenceDurationMs,
        referenceText: scope.referenceText,
        language: scope.language,
        userInput: text,
        accuracy: diff.accuracy,
        correctWords: diff.correctWords,
        missedWords: diff.missedWords,
        extraWords: diff.extraWords,
        createdAt: now,
        updatedAt: now,
        serverUpdatedAt: null,
        syncStatus: 'local',
      );

      final db = ref.read(appDatabaseProvider);
      await db.dictationDao.insertRow(row);

      if (_disposed) return;
      setState(
        getState().copyWith(
          status: DictationAttemptStatus.checked,
          activeDiff: () => diff,
          selectedHistoricalAttempt: () => row,
          errorMessage: () => null,
        ),
      );
    } catch (e, st) {
      logNamed('DictationController').warning('checkTextAnswer failed', e, st);
      if (!_disposed) {
        setState(
          getState().copyWith(
            status: DictationAttemptStatus.failed,
            errorMessage: () => e.toString(),
          ),
        );
      }
    } finally {
      _isCheckingText = false;
    }
  }

  Future<void> onVoiceTakeRecorded(RecordingRow take) async {
    if (_disposed) return;
    final current = getState();
    setState(
      current.copyWith(
        status: DictationAttemptStatus.transcribingVoice,
        lastVoiceRecording: () => take,
        selectedTake: () => take,
        errorMessage: () => null,
      ),
    );

    await _transcribeTake(take);
  }

  Future<void> retryVoiceTranscription() async {
    if (_disposed) return;
    final current = getState();
    final take = current.lastVoiceRecording;
    if (take == null) return;

    setState(
      current.copyWith(
        status: DictationAttemptStatus.transcribingVoice,
        errorMessage: () => null,
      ),
    );

    await _transcribeTake(take);
  }

  Future<void> _transcribeTake(RecordingRow take) async {
    final generation = ++_transcriptionGeneration;
    try {
      final localPath = take.localPath;
      if (localPath == null || localPath.isEmpty) {
        throw Exception('Audio path is empty');
      }
      final file = File(localPath);
      if (!await file.exists()) {
        throw Exception('Audio file not found: $localPath');
      }
      final bytes = await file.readAsBytes();
      if (_disposed || generation != _transcriptionGeneration) return;

      final asr = ref.read(asrServiceProvider);
      final asrResult = await asr.transcribe(
        AsrRequest(
          audioBytes: bytes,
          filename: file.uri.pathSegments.isNotEmpty
              ? file.uri.pathSegments.last
              : 'take.wav',
          language: scope.language.isNotEmpty ? scope.language : null,
          mimeType: 'audio/wav',
        ),
      );

      if (_disposed || generation != _transcriptionGeneration) return;

      final recognizedText = asrResult.text.trim();
      if (recognizedText.isEmpty) {
        final current = getState();
        setState(
          current.copyWith(
            status: DictationAttemptStatus.failed,
            errorMessage: () => 'No speech detected',
          ),
        );
        return;
      }

      final diff = computeDictationDiff(scope.referenceText, recognizedText);
      final now = DateTime.now();
      final row = DictationRow(
        id: _uuid.v4(),
        targetType: scope.targetType,
        targetId: scope.targetId,
        referenceStartMs: scope.referenceStartMs,
        referenceDurationMs: scope.referenceDurationMs,
        referenceText: scope.referenceText,
        language: scope.language,
        userInput: recognizedText,
        accuracy: diff.accuracy,
        correctWords: diff.correctWords,
        missedWords: diff.missedWords,
        extraWords: diff.extraWords,
        createdAt: now,
        updatedAt: now,
        serverUpdatedAt: null,
        syncStatus: 'local',
      );

      final db = ref.read(appDatabaseProvider);
      await db.dictationDao.insertRow(row);

      if (_disposed || generation != _transcriptionGeneration) return;

      final current = getState();
      setState(
        current.copyWith(
          status: DictationAttemptStatus.checked,
          activeDiff: () => diff,
          selectedHistoricalAttempt: () => row,
          errorMessage: () => null,
        ),
      );
    } catch (e, st) {
      logNamed(
        'DictationController',
      ).warning('ASR transcription failed', e, st);
      if (_disposed || generation != _transcriptionGeneration) return;
      try {
        final current = getState();
        setState(
          current.copyWith(
            status: DictationAttemptStatus.failed,
            errorMessage: () => e.toString(),
          ),
        );
      } catch (_) {}
    }
  }
}
