import 'dart:io';
import 'package:drift/native.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/ai/application/ai_capability_providers.dart';
import 'package:enjoy_player/features/ai/domain/capabilities/asr_capability.dart';
import 'package:enjoy_player/features/ai/domain/models/asr_request.dart';
import 'package:enjoy_player/features/ai/domain/models/asr_result.dart';
import 'package:enjoy_player/features/dictation/application/dictation_controller.dart';
import 'package:enjoy_player/features/dictation/domain/dictation_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAsrCapability implements AsrCapability {
  _FakeAsrCapability({this.textToReturn = ''});

  final String textToReturn;

  @override
  Future<AsrResult> transcribe(AsrRequest request) async {
    return AsrResult(text: textToReturn);
  }
}

class _DelegatingAsrCapability implements AsrCapability {
  _DelegatingAsrCapability({required this.shouldFail, required this.delegate});

  final bool Function() shouldFail;
  final AsrCapability delegate;

  @override
  Future<AsrResult> transcribe(AsrRequest request) {
    if (shouldFail()) {
      throw Exception('ASR network error');
    }
    return delegate.transcribe(request);
  }
}

void main() {
  late AppDatabase db;
  late Directory tempDir;

  setUp(() async {
    db = AppDatabase(executor: NativeDatabase.memory());
    tempDir = await Directory.systemTemp.createTemp('dictation_test_');
  });

  tearDown(() async {
    await db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  const scope = DictationScope(
    targetType: 'video',
    targetId: 'v-1',
    referenceStartMs: 1000,
    referenceDurationMs: 2000,
    referenceText: 'Hello world',
    language: 'en',
  );

  test('checkTextAnswer computes diff and inserts row in dictations', () async {
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    var state = const DictationSessionState();
    final ctrl = DictationController(
      ref: container.read(Provider((ref) => ref)),
      scope: scope,
      getState: () => state,
      setState: (next) => state = next,
    );

    ctrl.setInputMode(DictationInputMode.text);
    ctrl.updateTextDraft('hello world');
    await ctrl.checkTextAnswer();

    expect(state.status, DictationAttemptStatus.checked);
    expect(state.activeDiff?.accuracy, 100);
    expect(state.activeDiff?.correctWords, 2);

    final saved = await db.dictationDao.listByEchoRegion(
      'video',
      'v-1',
      1000,
      2000,
    );
    expect(saved, hasLength(1));
    expect(saved.single.userInput, 'hello world');
    expect(saved.single.accuracy, 100);
  });

  test(
    'onVoiceTakeRecorded transcribes take and handles failure retry',
    () async {
      final audioFile = File('${tempDir.path}/take.wav');
      await audioFile.writeAsBytes([0, 1, 2, 3]);

      final take = RecordingRow(
        id: 'rec-1',
        targetType: 'video',
        targetId: 'v-1',
        referenceStart: 1000,
        referenceDuration: 2000,
        referenceText: 'Hello world',
        language: 'en',
        localPath: audioFile.path,
        duration: 2000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      var shouldFail = true;
      final dynamicAsr = _FakeAsrCapability(textToReturn: 'hello world');

      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          asrCapabilityProvider.overrideWith(
            (ref) => _DelegatingAsrCapability(
              shouldFail: () => shouldFail,
              delegate: dynamicAsr,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      var state = const DictationSessionState();
      final ctrl = DictationController(
        ref: container.read(Provider((ref) => ref)),
        scope: scope,
        getState: () => state,
        setState: (next) => state = next,
      );

      await ctrl.onVoiceTakeRecorded(take);
      expect(state.status, DictationAttemptStatus.idle);
      expect(state.errorMessage, contains('ASR network error'));
      expect(state.lastVoiceRecording, isNotNull);

      shouldFail = false;
      await ctrl.retryVoiceTranscription();

      expect(state.status, DictationAttemptStatus.checked);
      expect(state.activeDiff?.accuracy, 100);
      expect(state.errorMessage, isNull);

      final saved = await db.dictationDao.listByEchoRegion(
        'video',
        'v-1',
        1000,
        2000,
      );
      expect(saved, hasLength(1));
      expect(saved.single.userInput, 'hello world');
    },
  );
}
