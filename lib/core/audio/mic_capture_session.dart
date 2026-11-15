/// One microphone capture lifecycle behind the [MicRecorder] seam.
///
/// Deep module: the policies every recording surface must agree on live here —
/// microphone permission (typed [MicPermissionDeniedException]), the shared
/// 16 kHz mono WAV config (web-client and Azure-Speech aligned; see
/// [buildMicRecordConfig]), output-directory creation, and the
/// recreate-the-recorder-after-every-stop Windows workaround. Callers own the
/// per-surface identity only: the directory, the file naming, the chosen
/// device, and what to do with the resulting WAV.
library;

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:record/record.dart';

import 'package:enjoy_player/core/audio/mic_recorder.dart';
import 'package:enjoy_player/core/logging/log.dart';

final _log = logNamed('MicCaptureSession');

/// Microphone permission was denied by the OS.
class MicPermissionDeniedException implements Exception {
  const MicPermissionDeniedException();

  @override
  String toString() => 'microphone permission denied';
}

/// Capture config aligned with the web client and Azure Speech expectations.
///
/// 16 kHz mono PCM16 WAV avoids stereo downmix loss (one mic channel + one
/// silent / out-of-phase channel cancelling each other to zero) and matches
/// what the Azure Speech SDK accepts directly without downstream re-encoding.
///
/// `device` is the user's chosen (or auto-picked, non-virtual) microphone —
/// this is what stops Windows from silently picking GlideX / VoiceMeeter /
/// Stereo-Mix loopback devices.
RecordConfig buildMicRecordConfig(InputDevice? device) => RecordConfig(
  encoder: AudioEncoder.wav,
  sampleRate: 16000,
  numChannels: 1,
  device: device,
);

/// Hands every surface its own [MicCaptureSession] so concurrently mounted
/// surfaces never share recorder state.
final micCaptureSessionFactoryProvider = Provider<MicCaptureSession Function()>(
  (ref) => MicCaptureSession.new,
);

class MicCaptureSession {
  MicCaptureSession({MicRecorder Function()? recorderFactory})
    : _recorderFactory = recorderFactory ?? PackageRecordMicRecorder.new {
    _recorder = _recorderFactory();
  }

  final MicRecorder Function() _recorderFactory;

  late MicRecorder _recorder;
  bool _active = false;

  /// Whether a capture is currently in flight on the microphone.
  bool get isActive => _active;

  /// Begins capturing into [directory]/[filename] (the directory is created
  /// when missing). Throws [MicPermissionDeniedException] when the OS denies
  /// the microphone, or propagates recorder errors.
  Future<void> start({
    required Directory directory,
    required String filename,
    InputDevice? device,
  }) async {
    directory.createSync(recursive: true);
    final granted = await _recorder.hasPermission();
    if (!granted) {
      throw const MicPermissionDeniedException();
    }
    await _recorder.start(
      buildMicRecordConfig(device),
      path: p.join(directory.path, filename),
    );
    _active = true;
  }

  /// Ends the capture and returns the written WAV path, or `null` when
  /// nothing was captured (or no capture is active). The file is kept — the
  /// caller decides whether it is a keeper or a temp file.
  Future<String?> stop() async {
    if (!_active) return null;
    _active = false;
    final path = await _stopAndRecreate();
    return path;
  }

  /// Ends the capture and discards the written WAV.
  Future<void> cancel() async {
    if (!_active) return;
    _active = false;
    final path = await _stopAndRecreate();
    await _deleteFileIfExists(path);
  }

  /// Ends any in-flight capture (discarding its WAV) and releases the
  /// recorder. Safe to call from a widget `dispose`.
  Future<void> dispose() async {
    if (_active) {
      _active = false;
      String? path;
      try {
        path = await _recorder.stop();
      } catch (e, st) {
        _log.fine('mic recorder stop on dispose', e, st);
      }
      await _deleteFileIfExists(path);
    }
    try {
      await _recorder.dispose();
    } catch (e, st) {
      _log.fine('mic recorder dispose failed', e, st);
    }
  }

  /// Live amplitude readings while a capture is running. Subscribe after
  /// [start]; the subscription binds to the recorder instance of that capture.
  Stream<Amplitude> amplitudeEvents([
    Duration interval = const Duration(milliseconds: 100),
  ]) => _recorder.onAmplitudeChanged(interval);

  /// Recreated after every `stop()` — `record` on Windows can keep stale
  /// Media Foundation state on the same instance, so a second `start()`
  /// quietly produces a zero-sample WAV ("second take won't record").
  Future<String?> _stopAndRecreate() async {
    String? path;
    try {
      path = await _recorder.stop();
    } catch (e, st) {
      _log.warning('mic recorder stop failed', e, st);
    }
    final old = _recorder;
    _recorder = _recorderFactory();
    try {
      await old.dispose();
    } catch (e, st) {
      _log.fine('mic recorder dispose after stop failed', e, st);
    }
    return path;
  }

  Future<void> _deleteFileIfExists(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (e, st) {
      _log.fine('delete recording wav failed', e, st);
    }
  }
}
