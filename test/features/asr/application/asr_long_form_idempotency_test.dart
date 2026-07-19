import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/core/riverpod/async_value_x.dart';
import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/ai/application/ai_capability_providers.dart';
import 'package:enjoy_player/features/ai/domain/capabilities/asr_capability.dart';
import 'package:enjoy_player/features/ai/domain/models/asr_request.dart';
import 'package:enjoy_player/features/ai/domain/models/asr_result.dart';
import 'package:enjoy_player/features/asr/application/asr_generation_controller.dart';
import 'package:enjoy_player/features/asr/application/asr_generation_job.dart';
import 'package:enjoy_player/features/asr/data/asr_audio_extractor.dart';
import 'package:enjoy_player/features/asr/data/asr_long_form_attempt_store.dart';
import 'package:enjoy_player/features/asr/domain/asr_long_form_job_exception.dart';
import 'package:enjoy_player/features/asr/domain/asr_long_form_models.dart';
import 'package:enjoy_player/features/transcript/application/transcript_repository_provider.dart';
import 'package:enjoy_player/features/transcript/data/transcript_repository.dart';

void main() {
  late AppDatabase db;
  late Directory tempDir;

  setUp(() async {
    db = AppDatabase(executor: NativeDatabase.memory());
    tempDir = await Directory.systemTemp.createTemp('asr_idem_');
    final now = DateTime.utc(2026);
    await db.audioDao.insertRow(
      AudioRow(
        id: 'audio-long',
        aid: 'aid-long',
        provider: 'user',
        title: 'Long',
        description: null,
        thumbnailUrl: null,
        durationSeconds: 900,
        language: 'en',
        translationKey: null,
        sourceText: null,
        voice: null,
        source: null,
        localUri: 'file://${tempDir.path}/audio.wav',
        md5: null,
        size: 3,
        mediaUrl: null,
        syncStatus: null,
        serverUpdatedAt: null,
        createdAt: now,
        updatedAt: now,
      ),
    );
  });

  tearDown(() async {
    await db.close();
    await tempDir.delete(recursive: true);
  });

  test('fresh Generate after success rotates idempotency key', () async {
    final source = File('${tempDir.path}/audio.wav')
      ..writeAsBytesSync([1, 2, 3]);
    final capability = _RecordingAsrCapability(
      const AsrResult(
        text: 'Hello.',
        language: 'en',
        segments: [AsrSegment(start: 0, end: 1, text: 'Hello.')],
      ),
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        transcriptRepositoryProvider.overrideWithValue(
          TranscriptRepository(db),
        ),
        asrCapabilityProvider.overrideWithValue(capability),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(asrGenerationControllerProvider('audio-long').notifier)
        .generateTranscript(mediaSourceUri: source.path, kind: MediaKind.audio);

    final firstKey = capability.lastRequest?.idempotencyKey;
    expect(firstKey, isNotNull);

    await container
        .read(asrGenerationControllerProvider('audio-long').notifier)
        .generateTranscript(mediaSourceUri: source.path, kind: MediaKind.audio);
    final secondKey = capability.lastRequest?.idempotencyKey;
    expect(secondKey, isNotNull);
    expect(secondKey, isNot(firstKey));
  });

  test(
    'retryable failure clears attempt so next Generate uses a new key',
    () async {
      final source = File('${tempDir.path}/audio.wav')
        ..writeAsBytesSync([1, 2, 3]);
      final capability = _FailThenSucceedCapability();
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          transcriptRepositoryProvider.overrideWithValue(
            TranscriptRepository(db),
          ),
          asrCapabilityProvider.overrideWithValue(capability),
        ],
      );
      addTearDown(container.dispose);
      final store = AsrLongFormAttemptStore(db);

      await container
          .read(asrGenerationControllerProvider('audio-long').notifier)
          .generateTranscript(
            mediaSourceUri: source.path,
            kind: MediaKind.audio,
          );

      expect(
        container
            .read(asrGenerationControllerProvider('audio-long'))
            .valueOrNull
            ?.phase,
        AsrGenerationPhase.error,
      );
      expect(await store.load('audio-long'), isNull);
      final failedKey = capability.keys.first;

      await container
          .read(asrGenerationControllerProvider('audio-long').notifier)
          .generateTranscript(
            mediaSourceUri: source.path,
            kind: MediaKind.audio,
          );

      expect(capability.keys.last, isNot(failedKey));
      expect(
        container
            .read(asrGenerationControllerProvider('audio-long'))
            .valueOrNull
            ?.phase,
        AsrGenerationPhase.success,
      );
    },
  );

  test('stored attempt reuses key when resume continues same job', () async {
    final source = File('${tempDir.path}/audio.wav')
      ..writeAsBytesSync([1, 2, 3]);
    final store = AsrLongFormAttemptStore(db);
    await store.save(
      AsrLongFormAttempt(
        mediaId: 'audio-long',
        idempotencyKey: 'fixed-key',
        declaredDurationSeconds: 900,
        startedAt: DateTime.utc(2026),
        jobId: 'job-resume',
        mediaReference: 'ref-1',
      ),
    );

    final capability = _RecordingAsrCapability(
      const AsrResult(
        text: 'Hello.',
        language: 'en',
        segments: [AsrSegment(start: 0, end: 1, text: 'Hello.')],
      ),
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        transcriptRepositoryProvider.overrideWithValue(
          TranscriptRepository(db),
        ),
        asrCapabilityProvider.overrideWithValue(capability),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(asrGenerationControllerProvider('audio-long').notifier)
        .generateTranscript(mediaSourceUri: source.path, kind: MediaKind.audio);

    expect(capability.lastRequest?.idempotencyKey, 'fixed-key');
    expect(capability.lastRequest?.existingJobId, 'job-resume');
  });
}

final class _RecordingAsrCapability implements AsrCapability {
  _RecordingAsrCapability(this.result);

  final AsrResult result;
  AsrRequest? lastRequest;

  @override
  Future<AsrResult> transcribe(AsrRequest request) async {
    lastRequest = request;
    return result;
  }
}

final class _FailThenSucceedCapability implements AsrCapability {
  final keys = <String?>[];
  var _calls = 0;

  @override
  Future<AsrResult> transcribe(AsrRequest request) async {
    keys.add(request.idempotencyKey);
    _calls++;
    if (_calls == 1) {
      throw const AsrLongFormJobException(
        category: 'provider_timeout',
        retryable: true,
      );
    }
    return const AsrResult(
      text: 'Hello.',
      language: 'en',
      segments: [AsrSegment(start: 0, end: 1, text: 'Hello.')],
    );
  }
}
