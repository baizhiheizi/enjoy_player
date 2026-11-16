library;

import 'dart:io';

import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/ai/application/ai_services.dart';
import 'package:enjoy_player/features/ai/domain/models/asr_request.dart';
import 'package:enjoy_player/features/dictation/domain/dictation_diff.dart';
import 'package:enjoy_player/features/dictation/domain/dictation_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'dictation_providers.g.dart';

final dictationEchoRegionHistoryProvider = StreamProvider.autoDispose
    .family<
      List<DictationRow>,
      ({String targetType, String targetId, int startMs, int durationMs})
    >((ref, arg) {
      final db = ref.watch(appDatabaseProvider);
      return db.dictationDao.watchByEchoRegion(
        arg.targetType,
        arg.targetId,
        arg.startMs,
        arg.durationMs,
      );
    });

@riverpod
class DictationSessionCtrl extends _$DictationSessionCtrl {
  static const _uuid = Uuid();

  bool _disposed = false;
  int _transcriptionGeneration = 0;
  bool _isCheckingText = false;

  @override
  DictationSessionState build(
    String targetType,
    String targetId,
    int startMs,
    int durationMs,
    String referenceText,
    String language,
  ) {
    ref.onDispose(_markDisposed);
    return const DictationSessionState();
  }

  void _markDisposed() {
    _disposed = true;
  }

  DictationScope get scope => DictationScope(
    targetType: targetType,
    targetId: targetId,
    referenceStartMs: startMs,
    referenceDurationMs: durationMs,
    referenceText: referenceText,
    language: language,
  );

  void setInputMode(DictationInputMode mode) {
    if (_disposed) return;
    if (state.mode == mode) return;
    state = state.copyWith(mode: mode);
  }

  void updateTextDraft(String text) {
    if (_disposed) return;
    state = state.copyWith(textDraft: text);
  }

  void tryAgain() {
    if (_disposed) return;
    state = state.copyWith(
      status: DictationAttemptStatus.idle,
      activeDiff: () => null,
      selectedHistoricalAttempt: () => null,
      errorMessage: () => null,
    );
  }

  void selectHistoricalAttempt(DictationRow? attempt) {
    if (_disposed) return;
    if (attempt == null) {
      state = state.copyWith(selectedHistoricalAttempt: () => null);
      return;
    }

    final diff = computeDictationDiff(attempt.referenceText, attempt.userInput);
    _applyChecked(attempt, diff);
  }

  Future<void> checkTextAnswer() async {
    if (_disposed || _isCheckingText) return;
    final text = state.textDraft.trim();
    if (text.isEmpty) return;

    _isCheckingText = true;
    try {
      final diff = computeDictationDiff(referenceText, text);
      final row = _dictationRow(userInput: text, diff: diff);
      await _persistAndApplyChecked(row, diff, () => !_disposed);
    } catch (e, st) {
      logNamed('DictationSessionCtrl').warning('checkTextAnswer failed', e, st);
      if (!_disposed) {
        state = state.copyWith(
          status: DictationAttemptStatus.failed,
          errorMessage: () => e.toString(),
        );
      }
    } finally {
      _isCheckingText = false;
    }
  }

  Future<void> onVoiceTakeRecorded(RecordingRow take) async {
    if (_disposed) return;
    state = state.copyWith(
      status: DictationAttemptStatus.transcribingVoice,
      lastVoiceRecording: () => take,
      selectedTake: () => take,
      errorMessage: () => null,
    );

    await _transcribeTake(take);
  }

  Future<void> retryVoiceTranscription() async {
    if (_disposed) return;
    final take = state.lastVoiceRecording;
    if (take == null) return;

    state = state.copyWith(
      status: DictationAttemptStatus.transcribingVoice,
      errorMessage: () => null,
    );

    await _transcribeTake(take);
  }

  DictationRow _dictationRow({
    required String userInput,
    required DictationDiffResult diff,
  }) {
    final now = DateTime.now();
    return DictationRow(
      id: _uuid.v4(),
      targetType: targetType,
      targetId: targetId,
      referenceStartMs: startMs,
      referenceDurationMs: durationMs,
      referenceText: referenceText,
      language: language,
      userInput: userInput,
      accuracy: diff.accuracy,
      correctWords: diff.correctWords,
      missedWords: diff.missedWords,
      extraWords: diff.extraWords,
      createdAt: now,
      updatedAt: now,
      serverUpdatedAt: null,
      syncStatus: 'local',
    );
  }

  void _applyChecked(DictationRow row, DictationDiffResult diff) {
    state = state.copyWith(
      status: DictationAttemptStatus.checked,
      activeDiff: () => diff,
      selectedHistoricalAttempt: () => row,
      errorMessage: () => null,
    );
  }

  Future<void> _persistAndApplyChecked(
    DictationRow row,
    DictationDiffResult diff,
    bool Function() stillCurrent,
  ) async {
    final db = ref.read(appDatabaseProvider);
    await db.dictationDao.insertRow(row);

    if (!stillCurrent()) return;
    _applyChecked(row, diff);
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
          language: language.isNotEmpty ? language : null,
          mimeType: 'audio/wav',
        ),
      );

      if (_disposed || generation != _transcriptionGeneration) return;

      final recognizedText = asrResult.text.trim();
      if (recognizedText.isEmpty) {
        state = state.copyWith(
          status: DictationAttemptStatus.failed,
          errorMessage: () => 'No speech detected',
        );
        return;
      }

      final diff = computeDictationDiff(referenceText, recognizedText);
      final row = _dictationRow(userInput: recognizedText, diff: diff);
      await _persistAndApplyChecked(
        row,
        diff,
        () => !_disposed && generation == _transcriptionGeneration,
      );
    } catch (e, st) {
      logNamed(
        'DictationSessionCtrl',
      ).warning('ASR transcription failed', e, st);
      if (_disposed || generation != _transcriptionGeneration) return;
      try {
        state = state.copyWith(
          status: DictationAttemptStatus.failed,
          errorMessage: () => e.toString(),
        );
      } catch (_) {}
    }
  }
}
