/// Re-encode recordings to WAV that Azure Speech SDK accepts from disk.
///
/// `record` (and some encoders) emit float or non-standard RIFF layouts that
/// can trigger **SPXERR_UNEXPECTED_EOF** with [AudioConfig::FromWavFileInput].
/// Web uses 16 kHz mono 16-bit PCM WAV; we mirror that via FFmpeg.
library;

import 'dart:io';
import 'dart:isolate';

import 'package:enjoy_player/core/audio/wav_signal_peak.dart';
import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/data/files/ffmpeg_argv_runner.dart';
import 'package:enjoy_player/features/ai/data/azure_assessment_staging_path.dart';

final _log = logNamed('ai.azure_assessment_wav');

/// Top-level so the ffmpeg invocation can run inside a worker isolate
/// (see [normalizeWavForAzureAssessment]). Scans the input WAV peak first,
/// then runs the ffmpeg subprocess in the same isolate, so the scan rides
/// the spawn the encode already needs. Returns the `exitCode` / `stderr`
/// pair we used to capture from `Process.run` plus the input scan, so the
/// caller can log the same way.
List<String> _normalizeArgs({
  required String inputPath,
  required String outputWavPath,
  required String audioFilter,
}) => <String>[
  '-nostdin',
  '-hide_banner',
  '-loglevel',
  'error',
  '-y',
  '-i',
  inputPath,
  '-vn',
  '-af',
  audioFilter,
  '-c:a',
  'pcm_s16le',
  outputWavPath,
];

Future<void> _deleteIfExists(String path) async {
  try {
    final f = File(path);
    if (f.existsSync()) await f.delete();
  } on Object catch (_) {}
}

bool _looksSilent(WavPeakScan scan) {
  return scan.rmsNormalized < 0.001 ||
      scan.nonZeroRatio < 0.01 ||
      scan.peakNormalized < kWavSilencePeakNorm;
}

void _logInputScan(WavPeakScan? scan) {
  if (scan == null) return;
  _log.fine(
    'normalizeWav: input fmt=${scan.fmt.audioFormat} '
    'ch=${scan.fmt.numChannels} '
    '${scan.fmt.sampleRate}Hz ${scan.fmt.bitsPerSample}bit '
    'peak≈${scan.peakNormalized.toStringAsFixed(5)} '
    'rms≈${scan.rmsNormalized.toStringAsFixed(6)} '
    'nonZero=${(scan.nonZeroRatio * 100).toStringAsFixed(2)}%',
  );
}

/// Runs FFmpeg to write **16 kHz, mono, signed 16-bit PCM** Microsoft WAV.
///
/// Returns `true` when [outputWavPath] exists, has at least 100 bytes, and
/// passes a non-silent peak/RMS check (guards against empty FFmpeg decode).
///
/// The peak scans and the desktop (Windows / Linux) ffmpeg CLI invocation
/// run in worker isolates so the multi-MB reads and the re-encode never block
/// the UI thread. The input peak scan shares the desktop ffmpeg isolate;
/// FFmpegKit platforms cannot move the encode off the main isolate
/// (platform channel), so their input scan keeps its own isolate, and the
/// output scan always follows the encode. Assessments are user-initiated
/// one-shots — the remaining spawn count is accepted over a persistent
/// worker.
Future<bool> normalizeWavForAzureAssessment({
  required String inputPath,
  required String outputWavPath,
}) async {
  if (inputPath.trim().isEmpty) return false;

  const filter =
      'aresample=16000:resampler=swr,aformat=sample_fmts=s16:channel_layouts=mono';

  await _deleteIfExists(outputWavPath);
  final result = await runFfmpegArgv(
    args: _normalizeArgs(
      inputPath: inputPath,
      outputWavPath: outputWavPath,
      audioFilter: filter,
    ),
    failLabel: 'normalizeWav',
    cliBackend: FfmpegCliBackend.isolateRun,
    isolatePrelude: () => scanWavDataPeakFromFile(inputPath),
    outputPath: outputWavPath,
  );
  _logInputScan(result.extra as WavPeakScan?);
  if (!result.succeeded) {
    _log.fine(
      'normalizeWav: ffmpeg failed (${result.outcome.name}) '
      'filter="$filter": ${result.stderr ?? ''}',
    );
    return false;
  }

  final out = File(outputWavPath);
  if (!out.existsSync() || out.lengthSync() < 100) {
    _log.fine(
      'normalizeWav: output too small '
      '(${out.existsSync() ? out.lengthSync() : 0} bytes)',
    );
    await _deleteIfExists(outputWavPath);
    return false;
  }

  final outScan = await Isolate.run(
    () => scanWavDataPeakFromFile(outputWavPath),
    debugName: 'azure-wav-peak-scan',
  );
  if (outScan == null) {
    _log.fine('normalizeWav: could not parse output WAV for peak check');
    return true;
  }
  if (_looksSilent(outScan)) {
    _log.warning(
      'normalizeWav: FFmpeg output looks silent '
      '(peak≈${outScan.peakNormalized.toStringAsFixed(6)} '
      'rms≈${outScan.rmsNormalized.toStringAsFixed(6)} '
      'nonZero=${(outScan.nonZeroRatio * 100).toStringAsFixed(2)}%)',
    );
    await _deleteIfExists(outputWavPath);
    return false;
  }
  _log.fine(
    'normalizeWav: output ok '
    'peak≈${outScan.peakNormalized.toStringAsFixed(5)} '
    'rms≈${outScan.rmsNormalized.toStringAsFixed(6)} '
    'nonZero=${(outScan.nonZeroRatio * 100).toStringAsFixed(2)}% '
    'bytes=${out.lengthSync()}',
  );
  return true;
}

/// If FFmpeg succeeds, returns a temp `.wav` path the caller must delete.
/// On failure returns `null` (caller should pass the original file to Azure).
Future<String?> tryCreateNormalizedAzureAssessmentWav(String inputPath) async {
  final out = await newAzureAssessmentStagingWavPath();
  final ok = await normalizeWavForAzureAssessment(
    inputPath: inputPath,
    outputWavPath: out,
  );
  if (!ok) {
    await _deleteIfExists(out);
    return null;
  }
  return File(out).absolute.path;
}
