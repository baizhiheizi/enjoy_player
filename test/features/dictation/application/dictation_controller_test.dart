import 'dart:async';
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

class _CustomAsrCapability implements AsrCapability {
  _CustomAsrCapability(this._handler);

  final Future<AsrResult> Function(AsrRequest request) _handler;

  @override
  Future<AsrResult> transcribe(AsrRequest request) => _handler(request);
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

    final saved = await db.dictationDao
        .watchByEchoRegion('video', 'v-1', 1000, 2000)
        .first;
    expect(saved, hasLength(1));
    expect(saved.single.userInput, 'hello world');
    expect(saved.single.accuracy, 100);
  });

  test('tryAgain clears selectedHistoricalAttempt and activeDiff', () {
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    var state = DictationSessionState(
      status: DictationAttemptStatus.checked,
      selectedHistoricalAttempt: DictationRow(
        id: 'h-1',
        targetType: 'video',
        targetId: 'v-1',
        referenceStartMs: 1000,
        referenceDurationMs: 2000,
        referenceText: 'Hello world',
        language: 'en',
        userInput: 'hello',
        accuracy: 50,
        correctWords: 1,
        missedWords: 1,
        extraWords: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      activeDiff: const DictationDiffResult(
        tokens: [],
        accuracy: 50,
        correctWords: 1,
        missedWords: 1,
        extraWords: 0,
      ),
    );

    final ctrl = DictationController(
      ref: container.read(Provider((ref) => ref)),
      scope: scope,
      getState: () => state,
      setState: (next) => state = next,
    );

    ctrl.tryAgain();
    expect(state.status, DictationAttemptStatus.idle);
    expect(state.activeDiff, isNull);
    expect(state.selectedHistoricalAttempt, isNull);
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
      expect(state.status, DictationAttemptStatus.failed);
      expect(state.errorMessage, contains('ASR network error'));
      expect(state.lastVoiceRecording, isNotNull);

      shouldFail = false;
      await ctrl.retryVoiceTranscription();

      expect(state.status, DictationAttemptStatus.checked);
      expect(state.activeDiff?.accuracy, 100);
      expect(state.errorMessage, isNull);

      final saved = await db.dictationDao
          .watchByEchoRegion('video', 'v-1', 1000, 2000)
          .first;
      expect(saved, hasLength(1));
      expect(saved.single.userInput, 'hello world');
    },
  );

  test(
    'empty or blank ASR result enters failed status and does not insert row',
    () async {
      final audioFile = File('${tempDir.path}/take_empty.wav');
      await audioFile.writeAsBytes([0, 1, 2, 3]);

      final take = RecordingRow(
        id: 'rec-empty',
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

      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          asrCapabilityProvider.overrideWithValue(
            _FakeAsrCapability(textToReturn: '   '),
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

      expect(state.status, DictationAttemptStatus.failed);
      expect(state.errorMessage, 'No speech detected');
      expect(state.lastVoiceRecording?.id, 'rec-empty');

      final saved = await db.dictationDao
          .watchByEchoRegion('video', 'v-1', 1000, 2000)
          .first;
      expect(saved, isEmpty);
    },
  );

  test('overlapping voice takes ignore stale results', () async {
    final audioFile1 = File('${tempDir.path}/take1.wav');
    await audioFile1.writeAsBytes([0, 1]);
    final audioFile2 = File('${tempDir.path}/take2.wav');
    await audioFile2.writeAsBytes([2, 3]);

    final take1 = RecordingRow(
      id: 'rec-1',
      targetType: 'video',
      targetId: 'v-1',
      referenceStart: 1000,
      referenceDuration: 2000,
      referenceText: 'Hello world',
      language: 'en',
      localPath: audioFile1.path,
      duration: 2000,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final take2 = RecordingRow(
      id: 'rec-2',
      targetType: 'video',
      targetId: 'v-1',
      referenceStart: 1000,
      referenceDuration: 2000,
      referenceText: 'Hello world',
      language: 'en',
      localPath: audioFile2.path,
      duration: 2000,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final completer1 = Completer<AsrResult>();
    final completer2 = Completer<AsrResult>();

    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        asrCapabilityProvider.overrideWith(
          (ref) => _CustomAsrCapability((req) {
            if (req.filename == 'take1.wav') return completer1.future;
            return completer2.future;
          }),
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

    final future1 = ctrl.onVoiceTakeRecorded(take1);
    final future2 = ctrl.onVoiceTakeRecorded(take2);

    completer2.complete(const AsrResult(text: 'second take wins'));
    await future2;

    expect(state.status, DictationAttemptStatus.checked);
    expect(state.selectedHistoricalAttempt?.userInput, 'second take wins');

    completer1.complete(const AsrResult(text: 'stale first take'));
    await future1;

    expect(state.selectedHistoricalAttempt?.userInput, 'second take wins');

    final saved = await db.dictationDao
        .watchByEchoRegion('video', 'v-1', 1000, 2000)
        .first;
    expect(saved, hasLength(1));
    expect(saved.single.userInput, 'second take wins');
  });

  test(
    'disposing controller prevents background ASR from updating state or crashing',
    () async {
      final audioFile = File('${tempDir.path}/take_dispose.wav');
      await audioFile.writeAsBytes([0, 1]);

      final take = RecordingRow(
        id: 'rec-disp',
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

      final completer = Completer<AsrResult>();
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          asrCapabilityProvider.overrideWith(
            (ref) => _CustomAsrCapability((_) => completer.future),
          ),
        ],
      );

      var state = const DictationSessionState();
      final ctrl = DictationController(
        ref: container.read(Provider((ref) => ref)),
        scope: scope,
        getState: () => state,
        setState: (next) => state = next,
      );

      final future = ctrl.onVoiceTakeRecorded(take);
      ctrl.dispose();
      container.dispose();

      completer.complete(const AsrResult(text: 'hello after dispose'));
      await future;

      expect(state.status, DictationAttemptStatus.transcribingVoice);
    },
  );
}
