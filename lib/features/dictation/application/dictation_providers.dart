library;

import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/dictation/application/dictation_controller.dart';
import 'package:enjoy_player/features/dictation/domain/dictation_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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
  @override
  DictationSessionState build(
    String targetType,
    String targetId,
    int startMs,
    int durationMs,
    String referenceText,
    String language,
  ) {
    ref.onDispose(_controller.dispose);
    return const DictationSessionState();
  }

  DictationScope get _scope => DictationScope(
    targetType: targetType,
    targetId: targetId,
    referenceStartMs: startMs,
    referenceDurationMs: durationMs,
    referenceText: referenceText,
    language: language,
  );

  late final DictationController _controller = DictationController(
    ref: ref,
    scope: _scope,
    getState: () => state,
    setState: (next) => state = next,
  );

  DictationController get controller => _controller;

  void setInputMode(DictationInputMode mode) => _controller.setInputMode(mode);

  void updateTextDraft(String text) => _controller.updateTextDraft(text);

  Future<void> checkTextAnswer() => _controller.checkTextAnswer();

  Future<void> onVoiceTakeRecorded(RecordingRow take) =>
      _controller.onVoiceTakeRecorded(take);

  Future<void> retryVoiceTranscription() =>
      _controller.retryVoiceTranscription();

  void tryAgain() => _controller.tryAgain();

  void selectHistoricalAttempt(DictationRow? attempt) =>
      _controller.selectHistoricalAttempt(attempt);
}
