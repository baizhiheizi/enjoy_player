import 'package:record/record.dart';

/// Minimal seam over `package:record`'s [AudioRecorder] so microphone
/// consumers can be tested with a fake (production adapter:
/// [PackageRecordMicRecorder]).
abstract class MicRecorder {
  Future<bool> hasPermission();

  Future<void> start(RecordConfig config, {required String path});

  /// Returns the path of the written WAV, or `null`/empty when nothing was
  /// captured.
  Future<String?> stop();

  /// Live amplitude readings in dB while a capture is running.
  Stream<Amplitude> onAmplitudeChanged([Duration? interval]);

  Future<void> dispose();
}

/// Production adapter delegating to a real [AudioRecorder].
class PackageRecordMicRecorder implements MicRecorder {
  PackageRecordMicRecorder() : _impl = AudioRecorder();

  final AudioRecorder _impl;

  @override
  Future<bool> hasPermission() => _impl.hasPermission();

  @override
  Future<void> start(RecordConfig config, {required String path}) =>
      _impl.start(config, path: path);

  @override
  Future<String?> stop() => _impl.stop();

  @override
  Stream<Amplitude> onAmplitudeChanged([Duration? interval]) =>
      _impl.onAmplitudeChanged(interval ?? const Duration(milliseconds: 100));

  @override
  Future<void> dispose() => _impl.dispose();
}
