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
import 'package:enjoy_player/features/ai/domain/models/asr_long_form_phase.dart';
import 'package:enjoy_player/features/ai/domain/models/asr_request.dart';
import 'package:enjoy_player/features/ai/domain/models/asr_result.dart';
import 'package:enjoy_player/features/asr/application/asr_generation_controller.dart';
import 'package:enjoy_player/features/asr/application/asr_generation_job.dart';
import 'package:enjoy_player/features/asr/data/asr_audio_extractor.dart';
import 'package:enjoy_player/features/asr/data/asr_long_form_attempt_store.dart';
import 'package:enjoy_player/features/asr/domain/asr_long_form_job_exception.dart';
import 'package:enjoy_player/features/asr/domain/asr_long_form_models.dart';
import 'package:enjoy_player/features/transcript/application/transcript_repository_provider.dart';

void main() {
  late AppDatabase db;
  late TranscriptRepository repo;
  late Directory tempDir;

  setUp(() async {
    db = AppDatabase(executor: NativeDatabase.memory());
    repo = TranscriptRepository(db);
    tempDir = await Directory.systemTemp.createTemp('asr_lf_ctrl_');
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

  ProviderContainer containerFor(AsrCapability capability) {
    return ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        transcriptRepositoryProvider.overrideWithValue(repo),
        asrCapabilityProvider.overrideWithValue(capability),
      ],
    );
  }

  test('long-form happy path reaches success with upserted track', () async {
    final source = File('${tempDir.path}/audio.wav')
      ..writeAsBytesSync([1, 2, 3]);
    final phases = <AsrGenerationPhase>[];
    final capability = _LongFormHappyCapability();
    final container = containerFor(capability);
    addTearDown(container.dispose);

    final sub = container.listen(
      asrGenerationControllerProvider('audio-long'),
      (prev, next) {
        final phase = next.valueOrNull?.phase;
        if (phase != null) phases.add(phase);
      },
    );
    addTearDown(sub.close);

    await container
        .read(asrGenerationControllerProvider('audio-long').notifier)
        .generateTranscript(mediaSourceUri: source.path, kind: MediaKind.audio);

    final job = container
        .read(asrGenerationControllerProvider('audio-long'))
        .valueOrNull;
    final rows = await db.transcriptDao.listForTarget('Audio', 'audio-long');
    expect(job?.phase, AsrGenerationPhase.success);
    expect(job?.trackId, isNotNull);
    expect(rows.single.id, job?.trackId);
    expect(phases, contains(AsrGenerationPhase.uploading));
    expect(phases, contains(AsrGenerationPhase.polling));
    expect(phases, contains(AsrGenerationPhase.persisting));
    expect(await AsrLongFormAttemptStore(db).load('audio-long'), isNull);
  });

  test('cancel during polling → cancelled, no persist', () async {
    final source = File('${tempDir.path}/audio.wav')
      ..writeAsBytesSync([1, 2, 3]);
    final enteredPolling = Completer<void>();
    final capability = _PollingCancelCapability(enteredPolling);
    final container = containerFor(capability);
    addTearDown(container.dispose);

    final future = container
        .read(asrGenerationControllerProvider('audio-long').notifier)
        .generateTranscript(mediaSourceUri: source.path, kind: MediaKind.audio);

    await enteredPolling.future;
    await container
        .read(asrGenerationControllerProvider('audio-long').notifier)
        .cancel();
    await future;

    final job = container
        .read(asrGenerationControllerProvider('audio-long'))
        .valueOrNull;
    final rows = await db.transcriptDao.listForTarget('Audio', 'audio-long');
    expect(job?.phase, AsrGenerationPhase.cancelled);
    expect(rows, isEmpty);
    expect(await AsrLongFormAttemptStore(db).load('audio-long'), isNull);
  });

  test('resume from stored jobId skips re-upload path flags', () async {
    final source = File('${tempDir.path}/audio.wav')
      ..writeAsBytesSync([1, 2, 3]);
    await AsrLongFormAttemptStore(db).save(
      AsrLongFormAttempt(
        mediaId: 'audio-long',
        idempotencyKey: 'resume-key',
        declaredDurationSeconds: 900,
        startedAt: DateTime.utc(2026),
        jobId: 'job-99',
        mediaReference: 'ref-99',
      ),
    );

    final capability = _RecordingAsrCapability(
      const AsrResult(
        text: 'Resumed.',
        language: 'en',
        segments: [AsrSegment(start: 0, end: 2, text: 'Resumed.')],
      ),
    );
    final container = containerFor(capability);
    addTearDown(container.dispose);

    await container
        .read(asrGenerationControllerProvider('audio-long').notifier)
        .generateTranscript(mediaSourceUri: source.path, kind: MediaKind.audio);

    expect(capability.lastRequest?.existingJobId, 'job-99');
    expect(capability.lastRequest?.idempotencyKey, 'resume-key');
    expect(
      container
          .read(asrGenerationControllerProvider('audio-long'))
          .valueOrNull
          ?.phase,
      AsrGenerationPhase.success,
    );
  });
}

final class _LongFormHappyCapability implements AsrCapability {
  @override
  Future<AsrResult> transcribe(AsrRequest request) async {
    request.onLongFormPhase?.call(AsrLongFormClientPhase.uploading);
    request.onLongFormUploaded?.call('media-ref-1');
    request.onLongFormPhase?.call(AsrLongFormClientPhase.polling);
    request.onLongFormJobAccepted?.call('job-1', 'media-ref-1');
    return const AsrResult(
      text: 'Hello long form.',
      language: 'en',
      segments: [AsrSegment(start: 0, end: 2, text: 'Hello long form.')],
    );
  }
}

final class _PollingCancelCapability implements AsrCapability {
  _PollingCancelCapability(this.enteredPolling);

  final Completer<void> enteredPolling;

  @override
  Future<AsrResult> transcribe(AsrRequest request) async {
    request.onLongFormPhase?.call(AsrLongFormClientPhase.uploading);
    request.onLongFormPhase?.call(AsrLongFormClientPhase.polling);
    if (!enteredPolling.isCompleted) enteredPolling.complete();
    for (var i = 0; i < 200; i++) {
      if (request.shouldCancel?.call() ?? false) {
        throw const AsrLongFormJobException(
          category: 'cancelled',
          retryable: false,
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    fail('expected cancel during polling');
  }
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
