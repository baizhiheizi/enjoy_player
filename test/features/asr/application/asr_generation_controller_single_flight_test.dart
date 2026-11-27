import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/ai/application/ai_capability_providers.dart';
import 'package:enjoy_player/features/ai/domain/capabilities/asr_capability.dart';
import 'package:enjoy_player/features/ai/domain/models/asr_request.dart';
import 'package:enjoy_player/features/ai/domain/models/asr_result.dart';
import 'package:enjoy_player/features/asr/application/asr_generation_controller.dart';
import 'package:enjoy_player/features/asr/data/asr_audio_extractor.dart';
import 'package:enjoy_player/features/transcript/application/transcript_repository_provider.dart';

/// ASR capability that blocks every `transcribe` call on its own gate, so a
/// test can hold one pass in flight while a second one starts.
class _GatedAsrCapability implements AsrCapability {
  final List<Completer<void>> gates = [];

  int get callCount => gates.length;

  @override
  Future<AsrResult> transcribe(AsrRequest request) async {
    final gate = Completer<void>();
    gates.add(gate);
    await gate.future;
    return const AsrResult(
      text: 'Hello.',
      language: 'en',
      segments: [AsrSegment(start: 0, end: 1, text: 'Hello.')],
    );
  }
}

void main() {
  late AppDatabase db;
  late Directory tempDir;
  late String sourcePath;

  setUp(() async {
    db = AppDatabase(executor: NativeDatabase.memory());
    tempDir = await Directory.systemTemp.createTemp('asr_single_flight_test_');
    sourcePath = '${tempDir.path}/audio.wav';
    File(sourcePath).writeAsBytesSync([1, 2, 3]);
    final now = DateTime.utc(2026);
    await db.audioDao.insertRow(
      AudioRow(
        id: 'audio-1',
        aid: 'aid-1',
        provider: 'user',
        title: 'Audio',
        description: null,
        thumbnailUrl: null,
        durationSeconds: 10,
        language: 'es',
        translationKey: null,
        sourceText: null,
        voice: null,
        source: null,
        localUri: 'file://$sourcePath',
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

  Future<void> waitFor(bool Function() condition) async {
    for (var i = 0; i < 200; i++) {
      if (condition()) return;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    fail('condition was never met');
  }

  test(
    'a superseded pass does not release the slot held by the newer pass',
    () async {
      final capability = _GatedAsrCapability();
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

      final ctrl = container.read(
        asrGenerationControllerProvider('audio-1').notifier,
      );

      final first = ctrl.generateTranscript(
        mediaSourceUri: sourcePath,
        kind: MediaKind.audio,
      );
      await waitFor(() => capability.callCount == 1);
      expect(ctrl.isInFlight, isTrue);

      final second = ctrl.generateTranscript(
        mediaSourceUri: sourcePath,
        kind: MediaKind.audio,
      );
      await waitFor(() => capability.callCount == 2);
      expect(ctrl.isInFlight, isTrue);

      capability.gates[0].complete();
      await first;
      expect(ctrl.isInFlight, isTrue);

      capability.gates[1].complete();
      await second;
      expect(ctrl.isInFlight, isFalse);
    },
  );
}
