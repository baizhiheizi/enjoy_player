/// Extracts mono `float32` PCM for a media time range via the FFmpeg CLI
/// (Windows / Linux) or FFmpegKit (Android / iOS / macOS), with cooperative
/// cancellation and a per-call timeout.
///
/// The expensive byte→Float32 decode no longer runs here (or on the main
/// isolate) — callers receive the temp `.raw` path produced by FFmpeg and
/// decode+analyze it inside a single worker isolate (see
/// `echo_region_pitch_analyzer.dart`). That keeps the multi-megabyte PCM
/// buffer off the UI thread and out of any isolate message port.
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/data/files/ffmpeg_argv_runner.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

final _log = logNamed('EchoSegmentPcmExtractor');

/// Sample rate used for extracted PCM (fixed for consistent pitch hop math).
const int kEchoPcmSampleRate = 44100;

/// Default per-extraction wall-clock budget. Region/user extracts are short;
/// a hung FFmpeg should surface as a timeout rather than block the UI.
const Duration kEchoPcmExtractionTimeout = Duration(seconds: 30);

/// Why a PCM extraction failed. Surfaced (instead of a silent `null`) so the
/// UI can tell "FFmpeg not installed" apart from a transient decode error.
enum EchoPcmFailureReason {
  invalidInput,
  fileMissing,
  ffmpegMissing,
  ffmpegFailed,
  timeout,
  cancelled,
  emptyOutput,
}

/// Typed failure for echo PCM extraction (ADR-0018-friendly: callers can branch
/// on [reason] instead of string-matching).
class EchoPcmExtractionException implements Exception {
  const EchoPcmExtractionException(this.reason, [this.message = '']);

  final EchoPcmFailureReason reason;
  final String message;

  @override
  String toString() =>
      'EchoPcmExtractionException($reason'
      '${message.isEmpty ? '' : ': $message'})';
}

/// Cooperative cancellation handle for an FFmpeg extraction.
///
/// When [cancel] is invoked (e.g. because the echo region changed while a
/// previous extraction was still running) the live FFmpeg process/session is
/// killed and the in-flight future completes with a `cancelled` exception —
/// so the work is *stopped*, not merely discarded by the caller.
class EchoPcmCancelToken implements FfmpegCancellation {
  bool _cancelled = false;
  final List<void Function()> _hooks = [];

  /// Whether [cancel] has been called.
  @override
  bool get isCancelled => _cancelled;

  /// Cancels the work. Runs any hooks registered via [onCancel] exactly once.
  /// Safe to call multiple times; subsequent calls are no-ops.
  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    for (final hook in List<void Function()>.of(_hooks)) {
      try {
        hook();
      } catch (e, st) {
        _log.warning('echo pcm cancel hook threw', e, st);
      }
    }
  }

  /// Registers [hook] to run when [cancel] is called. If already cancelled,
  /// [hook] runs immediately.
  @override
  void onCancel(void Function() hook) {
    if (_cancelled) {
      hook();
      return;
    }
    _hooks.add(hook);
  }
}

/// Decodes little-endian `f32` bytes into a [Float32List] without an extra
/// `Uint8List.fromList` copy. Top-level + allocation-free so it can run inside
/// a worker isolate next to the analysis (no port crossing of the PCM buffer).
Float32List decodeF32leBytes(Uint8List bytes) {
  if (bytes.lengthInBytes < 4) return Float32List(0);
  final bd = ByteData.sublistView(bytes);
  final nFloat = bd.lengthInBytes ~/ 4;
  final samples = Float32List(nFloat);
  for (var i = 0; i < nFloat; i++) {
    samples[i] = bd.getFloat32(i * 4, Endian.little);
  }
  return samples;
}

/// Runs FFmpeg to extract `[startSec, startSec + durationSec)` of [mediaFilePath]
/// (a local path or an `http(s)` URL) to a temp `.raw` (f32le, [kEchoPcmSampleRate] Hz, mono).
///
/// Returns the temp file path; the **caller must delete it** (typically after a
/// worker isolate has decoded+analyzed it). Throws [EchoPcmExtractionException]
/// on any failure — including a surfaced [EchoPcmFailureReason.ffmpegMissing]
/// instead of a silent `null`.
///
/// [token] cooperatively cancels the live FFmpeg process/session.
/// [timeout] bounds the wall-clock cost of a single FFmpeg invocation.
Future<String> extractMonoFloat32SegmentToTempFile({
  required String mediaFilePath,
  required double startSec,
  required double durationSec,
  EchoPcmCancelToken? token,
  Duration timeout = kEchoPcmExtractionTimeout,
}) async {
  if (durationSec <= 0 || mediaFilePath.trim().isEmpty) {
    throw const EchoPcmExtractionException(EchoPcmFailureReason.invalidInput);
  }
  if (!isNetworkMediaInput(mediaFilePath) &&
      !File(mediaFilePath).existsSync()) {
    throw const EchoPcmExtractionException(EchoPcmFailureReason.fileMissing);
  }
  final outFile = await _newTempRawFile('echo_seg');
  await _runFfmpegExtract(
    mediaPath: mediaFilePath,
    outPath: outFile,
    startSec: startSec,
    durationSec: durationSec,
    token: token,
    timeout: timeout,
  );
  return outFile;
}

/// Runs FFmpeg to decode an entire file to a temp `.raw` (for short user
/// recordings). Returns the temp file path; the **caller must delete it**.
///
/// See [extractMonoFloat32SegmentToTempFile] for failure/cancellation semantics.
Future<String> extractEntireFileToTempF32(
  String mediaFilePath, {
  EchoPcmCancelToken? token,
  Duration timeout = kEchoPcmExtractionTimeout,
}) async {
  if (mediaFilePath.trim().isEmpty) {
    throw const EchoPcmExtractionException(EchoPcmFailureReason.invalidInput);
  }
  if (!File(mediaFilePath).existsSync()) {
    throw const EchoPcmExtractionException(EchoPcmFailureReason.fileMissing);
  }
  final outFile = await _newTempRawFile('echo_full');
  await _runFfmpegFullDecode(
    mediaPath: mediaFilePath,
    outPath: outFile,
    token: token,
    timeout: timeout,
  );
  return outFile;
}

/// Whether [input] is an `http(s)` URL (cloud-streamed media) rather than a
/// local file path.
bool isNetworkMediaInput(String input) {
  final lower = input.trimLeft().toLowerCase();
  return lower.startsWith('http://') || lower.startsWith('https://');
}

List<String> _networkArgs(String input) => isNetworkMediaInput(input)
    ? const ['-protocol_whitelist', 'file,http,https,tcp,tls,crypto']
    : const [];

Future<String> _newTempRawFile(String prefix) async {
  final tempDir = await getTemporaryDirectory();
  return p.join(
    tempDir.path,
    '${prefix}_${DateTime.now().microsecondsSinceEpoch}.raw',
  );
}

Future<void> _runFfmpegExtract({
  required String mediaPath,
  required String outPath,
  required double startSec,
  required double durationSec,
  required EchoPcmCancelToken? token,
  required Duration timeout,
}) async {
  final ss = startSec.toStringAsFixed(4);
  final dur = durationSec.toStringAsFixed(4);
  final args = <String>[
    '-nostdin',
    '-hide_banner',
    '-loglevel',
    'error',
    '-y',
    '-ss',
    ss,
    ..._networkArgs(mediaPath),
    '-i',
    mediaPath,
    '-t',
    dur,
    '-vn',
    '-ac',
    '1',
    '-ar',
    '$kEchoPcmSampleRate',
    '-f',
    'f32le',
    outPath,
  ];

  await _runFfmpeg(
    args: args,
    outputPath: outPath,
    token: token,
    timeout: timeout,
    failLabel: 'segment',
  );
}

Future<void> _runFfmpegFullDecode({
  required String mediaPath,
  required String outPath,
  required EchoPcmCancelToken? token,
  required Duration timeout,
}) async {
  final args = <String>[
    '-nostdin',
    '-hide_banner',
    '-loglevel',
    'error',
    '-y',
    '-i',
    mediaPath,
    '-vn',
    '-ac',
    '1',
    '-ar',
    '$kEchoPcmSampleRate',
    '-f',
    'f32le',
    outPath,
  ];

  await _runFfmpeg(
    args: args,
    outputPath: outPath,
    token: token,
    timeout: timeout,
    failLabel: 'full decode',
  );
}

/// Runs FFmpeg and maps the shared runner's outcome onto this feature's
/// typed failure.
Future<void> _runFfmpeg({
  required List<String> args,
  required String outputPath,
  required EchoPcmCancelToken? token,
  required Duration timeout,
  required String failLabel,
}) async {
  final result = await runFfmpegArgv(
    args: args,
    failLabel: failLabel,
    cliBackend: FfmpegCliBackend.processStart,
    kitBackend: FfmpegKitBackend.async,
    timeout: timeout,
    cancellation: token,
    outputPath: outputPath,
  );
  switch (result.outcome) {
    case FfmpegOutcome.success:
      return;
    case FfmpegOutcome.unavailable:
      throw const EchoPcmExtractionException(
        EchoPcmFailureReason.ffmpegMissing,
        'No FFmpeg executable found',
      );
    case FfmpegOutcome.cancelled:
      throw const EchoPcmExtractionException(EchoPcmFailureReason.cancelled);
    case FfmpegOutcome.timedOut:
      throw const EchoPcmExtractionException(EchoPcmFailureReason.timeout);
    case FfmpegOutcome.failed:
      throw EchoPcmExtractionException(
        EchoPcmFailureReason.ffmpegFailed,
        '$failLabel exit ${result.exitCode ?? -1}'
        '${result.stderr == null ? '' : ': ${result.stderr}'}',
      );
  }
}
