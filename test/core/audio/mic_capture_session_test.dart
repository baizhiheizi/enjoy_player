import 'dart:io';

import 'package:enjoy_player/core/audio/mic_capture_session.dart';
import 'package:enjoy_player/core/audio/mic_recorder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:record/record.dart';

class _FakeMicRecorder implements MicRecorder {
  _FakeMicRecorder();

  bool permissionGranted = true;
  RecordConfig? lastConfig;
  String? lastPath;
  String? stopResult;
  int stopCalls = 0;
  int disposeCalls = 0;

  @override
  Future<bool> hasPermission() async => permissionGranted;

  @override
  Future<void> start(RecordConfig config, {required String path}) async {
    lastConfig = config;
    lastPath = path;
  }

  @override
  Future<String?> stop() async {
    stopCalls++;
    return stopResult;
  }

  @override
  Stream<Amplitude> onAmplitudeChanged([Duration? interval]) =>
      const Stream<Amplitude>.empty();

  @override
  Future<void> dispose() async {
    disposeCalls++;
  }
}

void main() {
  late Directory tempDir;
  late List<_FakeMicRecorder> recorders;
  late MicCaptureSession session;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('mic_capture_test_');
    recorders = [];
    session = MicCaptureSession(
      recorderFactory: () {
        final r = _FakeMicRecorder();
        recorders.add(r);
        return r;
      },
    );
  });

  tearDown(() async {
    await session.dispose();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Directory captureDir() => Directory(p.join(tempDir.path, 'captures'));

  test(
    'start throws MicPermissionDeniedException and never starts the recorder',
    () async {
      recorders.single.permissionGranted = false;

      await expectLater(
        session.start(directory: captureDir(), filename: 'x.wav'),
        throwsA(isA<MicPermissionDeniedException>()),
      );

      expect(recorders.single.lastPath, isNull);
      expect(session.isActive, isFalse);
    },
  );

  test(
    'start creates the directory and starts with the shared 16 kHz mono config',
    () async {
      const device = InputDevice(id: 'mic-9', label: 'Test Mic');

      await session.start(
        directory: captureDir(),
        filename: 'take.wav',
        device: device,
      );

      expect(await captureDir().exists(), isTrue);
      expect(recorders.single.lastPath, p.join(captureDir().path, 'take.wav'));
      final config = recorders.single.lastConfig!;
      expect(config.encoder, AudioEncoder.wav);
      expect(config.sampleRate, 16000);
      expect(config.numChannels, 1);
      expect(config.device?.id, 'mic-9');
      expect(session.isActive, isTrue);
    },
  );

  test('stop returns the written path and recreates the recorder', () async {
    await session.start(directory: captureDir(), filename: 'take.wav');
    final first = recorders.single;
    first.stopResult = first.lastPath;

    final path = await session.stop();

    expect(path, first.lastPath);
    expect(first.disposeCalls, 1);
    expect(recorders, hasLength(2));
    expect(identical(recorders[0], recorders[1]), isFalse);
    expect(session.isActive, isFalse);
  });

  test('stop without a start returns null', () async {
    expect(await session.stop(), isNull);
    expect(recorders.single.stopCalls, 0);
  });

  test('cancel deletes the captured wav', () async {
    await session.start(directory: captureDir(), filename: 'take.wav');
    final path = recorders.single.lastPath!;
    await File(path).writeAsBytes([1, 2, 3]);
    recorders.single.stopResult = path;

    await session.cancel();

    expect(await File(path).exists(), isFalse);
    expect(session.isActive, isFalse);
  });

  test('dispose deletes a pending capture and releases the recorder', () async {
    await session.start(directory: captureDir(), filename: 'take.wav');
    final path = recorders.single.lastPath!;
    await File(path).writeAsBytes([1, 2, 3]);
    recorders.single.stopResult = path;

    await session.dispose();

    expect(await File(path).exists(), isFalse);
    expect(recorders.single.disposeCalls, 1);
    expect(session.isActive, isFalse);
  });
}
