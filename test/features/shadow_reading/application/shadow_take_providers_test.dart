// Tests for the shadow-reading application seam (issue #764 candidate 8):
// the panel no longer names a database handle, so the wiring is the contract.
// In-memory Drift + overridden providers; no widget tree, no platform channels.
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:record/record.dart';

import 'package:enjoy_player/data/db/app_database.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/features/shadow_reading/application/shadow_take_providers.dart';
import 'package:enjoy_player/features/shadow_reading/application/shadow_take_store.dart';
import 'package:enjoy_player/features/sync/application/sync_providers.dart';
import 'package:enjoy_player/features/sync/domain/sync_types.dart';

class _FakeMicRecorder implements MicRecorder {
  final startedPaths = <String>[];
  RecordConfig? lastConfig;
  String? armedPath;
  int disposeCalls = 0;

  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<void> start(RecordConfig config, {required String path}) async {
    lastConfig = config;
    startedPaths.add(path);
  }

  @override
  Future<String?> stop() async => armedPath;

  @override
  Future<void> dispose() async => disposeCalls++;
}

/// Minimal RIFF PCM16 mono WAV (44-byte header + samples).
Uint8List buildPcm16Wav(List<int> samples, {int sampleRate = 16000}) {
  const numChannels = 1;
  final blockAlign = numChannels * 2;
  final byteRate = sampleRate * blockAlign;
  final dataSize = samples.length * blockAlign;
  final data = ByteData(44 + dataSize);
  void ascii(int offset, String s) {
    for (var i = 0; i < s.length; i++) {
      data.setUint8(offset + i, s.codeUnitAt(i));
    }
  }

  ascii(0, 'RIFF');
  data.setUint32(4, 36 + dataSize, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little); // PCM
  data.setUint16(22, numChannels, Endian.little);
  data.setUint32(24, sampleRate, Endian.little);
  data.setUint32(28, byteRate, Endian.little);
  data.setUint16(32, blockAlign, Endian.little);
  data.setUint16(34, 16, Endian.little); // bits per sample
  ascii(36, 'data');
  data.setUint32(40, dataSize, Endian.little);
  for (var i = 0; i < samples.length; i++) {
    data.setInt16(44 + i * 2, samples[i], Endian.little);
  }
  return data.buffer.asUint8List();
}

void main() {
  late AppDatabase db;
  late Directory tempDir;
  late _FakeMicRecorder recorder;
  late List<(SyncEntityType, String, SyncAction)> syncCalls;
  late ProviderContainer container;

  setUp(() async {
    db = AppDatabase(executor: NativeDatabase.memory());
    tempDir = await Directory.systemTemp.createTemp('shadow_take_providers');
    recorder = _FakeMicRecorder();
    syncCalls = [];
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        syncEnqueueProvider.overrideWithValue((type, id, action) async {
          syncCalls.add((type, id, action));
        }),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  /// The factory must bind the container's database and sync seam, so a take
  /// persisted through a store it built still lands in the test database and
  /// still enqueues.
  test(
    'factory-built store persists through the container database and sync seam',
    () async {
      final factory = container.read(shadowTakeStoreFactoryProvider);
      final store = factory(
        recorderFactory: () => recorder,
        takeDirectory: tempDir,
      );
      addTearDown(store.dispose);

      await store.start(device: null);
      final path = recorder.startedPaths.last;
      await File(path).writeAsBytes(buildPcm16Wav([0, 120, -120, 40]));
      recorder.armedPath = path;

      final result = await store.stopAndPersist(
        region: const TakeRegion(
          targetType: 'transcript',
          targetId: 'media-1',
          language: 'en',
          referenceText: 'hello',
          startSec: 1,
          endSec: 3,
        ),
      );
      expect(result.row.targetId, 'media-1');
      expect(syncCalls, isNotEmpty);
      expect(container.read(appDatabaseProvider), same(db));
    },
  );

  /// Two stores from one factory are distinct objects: the panel owns its
  /// store (recorder + `_active`), so sharing would cross-talk between
  /// concurrently mounted panels.
  test('factory hands out independent store instances', () {
    final factory = container.read(shadowTakeStoreFactoryProvider);
    final a = factory(recorderFactory: () => recorder, takeDirectory: tempDir);
    final b = factory(recorderFactory: () => recorder, takeDirectory: tempDir);
    addTearDown(a.dispose);
    addTearDown(b.dispose);
    expect(identical(a, b), isFalse);
  });

  group('echo region recordings', () {
    Future<void> insert({
      required String id,
      required int referenceStart,
      required int referenceDuration,
    }) {
      return db.recordingDao
          .into(db.recordings)
          .insert(
            RecordingsCompanion.insert(
              id: id,
              createdAt: DateTime.utc(2026, 1, 1),
              updatedAt: DateTime.utc(2026, 1, 1),
              targetType: 'transcript',
              targetId: 'media-1',
              language: 'en',
              referenceText: 'hello',
              localPath: Value('/tmp/$id.wav'),
              referenceStart: referenceStart,
              referenceDuration: referenceDuration,
              duration: referenceDuration,
            ),
          );
    }

    const query = EchoRegionRecordingsQuery(
      targetType: 'transcript',
      targetId: 'media-1',
      language: 'en',
      echoStartMs: 1000,
      echoEndMs: 3000,
    );

    test('one-shot read returns only rows overlapping the window', () async {
      await insert(
        id: 'overlap-start',
        referenceStart: 500,
        referenceDuration: 1000,
      );
      await insert(
        id: 'overlap-end',
        referenceStart: 2500,
        referenceDuration: 1000,
      );
      await insert(id: 'before', referenceStart: 0, referenceDuration: 500);
      await insert(id: 'after', referenceStart: 4000, referenceDuration: 500);

      final rows = await container.read(
        echoRegionRecordingsOnceProvider(query).future,
      );
      expect(
        rows.map((r) => r.id),
        containsAll(['overlap-start', 'overlap-end']),
      );
      expect(rows.map((r) => r.id), isNot(contains('before')));
      expect(rows.map((r) => r.id), isNot(contains('after')));
    });

    test('stream read emits rows for the window', () async {
      await insert(id: 'overlap', referenceStart: 900, referenceDuration: 400);
      final rows = await container
          .read(echoRegionRecordingsProvider(query))
          .first;
      expect(rows.map((r) => r.id), contains('overlap'));
    });
  });

  // The family keys off `==`: without it every rebuild would open a fresh
  // drift query and resubscribe.
  test('query equality compares all five fields', () {
    const base = EchoRegionRecordingsQuery(
      targetType: 'transcript',
      targetId: 'media-1',
      language: 'en',
      echoStartMs: 0,
      echoEndMs: 10,
    );
    const same = EchoRegionRecordingsQuery(
      targetType: 'transcript',
      targetId: 'media-1',
      language: 'en',
      echoStartMs: 0,
      echoEndMs: 10,
    );
    expect(base, same);
    expect(base.hashCode, same.hashCode);
    for (final other in <EchoRegionRecordingsQuery>[
      const EchoRegionRecordingsQuery(
        targetType: 'vocab',
        targetId: 'media-1',
        language: 'en',
        echoStartMs: 0,
        echoEndMs: 10,
      ),
      const EchoRegionRecordingsQuery(
        targetType: 'transcript',
        targetId: 'media-2',
        language: 'en',
        echoStartMs: 0,
        echoEndMs: 10,
      ),
      const EchoRegionRecordingsQuery(
        targetType: 'transcript',
        targetId: 'media-1',
        language: 'de',
        echoStartMs: 0,
        echoEndMs: 10,
      ),
      const EchoRegionRecordingsQuery(
        targetType: 'transcript',
        targetId: 'media-1',
        language: 'en',
        echoStartMs: 1,
        echoEndMs: 10,
      ),
      const EchoRegionRecordingsQuery(
        targetType: 'transcript',
        targetId: 'media-1',
        language: 'en',
        echoStartMs: 0,
        echoEndMs: 11,
      ),
    ]) {
      expect(base, isNot(other));
    }
  });
}
