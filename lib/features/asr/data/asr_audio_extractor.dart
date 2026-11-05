/// Extract audio bytes suitable for [AsrService.transcribe] from a
/// local media source.
///
/// * Audio-only sources ([MediaKind.audio]) are read directly — the
///   bytes are passed to the recognition service unchanged.
/// * Video sources ([MediaKind.video]) go through FFmpeg: the audio
///   track is extracted to a temporary 16 kHz mono 16-bit PCM WAV
///   (the format the Azure Speech SDK accepts). On Windows / Linux the
///   invocation runs in a worker isolate so a long re-encode does
///   not block the UI thread (mirrors `azure_assessment_wav_normalizer`).
///
/// Errors are mapped to a single [AsrAudioExtractionException] with a
/// machine-readable [AsrAudioExtractionFailureReason] — the controller
/// maps each reason to a localized ARB key (see `asr_failure_messages.dart`).
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:enjoy_player/data/files/ffmpeg_argv_runner.dart';
import 'package:enjoy_player/data/files/ffmpeg_media_probe.dart';
import 'package:enjoy_player/features/asr/domain/asr_audio_extraction_failure.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

enum MediaKind { audio, video }

class AsrAudioExtractor {
  const AsrAudioExtractor();

  static const _maxBytesDefault = 500 * 1024 * 1024;

  /// Returns the audio bytes to feed to [AsrService.transcribe].
  ///
  /// Throws [AsrAudioExtractionException] on every failure mode listed
  /// in [AsrAudioExtractionFailureReason].
  Future<Uint8List> extractAudio({
    required String mediaSourceUri,
    required MediaKind kind,
    void Function(double progress)? onProgress,
    int maxBytes = _maxBytesDefault,
  }) async {
    if (mediaSourceUri.trim().isEmpty) {
      throw AsrAudioExtractionException(
        AsrAudioExtractionFailureReason.unsupportedSource,
        'Empty media source URI',
      );
    }
    final input = FfmpegMediaProbe.mediaInputForFfmpeg(mediaSourceUri);

    if (kind == MediaKind.audio) {
      return _readAudioDirect(input, maxBytes);
    }

    return _extractFromVideo(
      input: input,
      onProgress: onProgress,
      maxBytes: maxBytes,
    );
  }

  Future<Uint8List> _readAudioDirect(String input, int maxBytes) async {
    final file = File(input);
    if (!file.existsSync()) {
      throw AsrAudioExtractionException(
        AsrAudioExtractionFailureReason.unsupportedSource,
        'Audio file does not exist: $input',
      );
    }
    final size = await file.length();
    if (size > maxBytes) {
      throw AsrAudioExtractionException(
        AsrAudioExtractionFailureReason.fileTooLarge,
        'Audio file is $size bytes (max $maxBytes)',
      );
    }
    return file.readAsBytes();
  }

  Future<Uint8List> _extractFromVideo({
    required String input,
    required void Function(double progress)? onProgress,
    required int maxBytes,
  }) async {
    final file = File(input);
    if (!file.existsSync()) {
      throw AsrAudioExtractionException(
        AsrAudioExtractionFailureReason.unsupportedSource,
        'Video file does not exist: $input',
      );
    }
    final size = await file.length();
    if (size > maxBytes) {
      throw AsrAudioExtractionException(
        AsrAudioExtractionFailureReason.fileTooLarge,
        'Video file is $size bytes (max $maxBytes)',
      );
    }

    onProgress?.call(0.0);

    final dir = await getTemporaryDirectory();
    final outputPath = p.join(dir.path, 'asr_${const Uuid().v4()}.wav');
    try {
      final ok = await _runExtract(
        input: input,
        outputWav: outputPath,
        onProgress: onProgress,
      );
      if (!ok) {
        throw AsrAudioExtractionException(
          AsrAudioExtractionFailureReason.ffmpegFailed,
          'FFmpeg extract failed for $input',
        );
      }
      final out = File(outputPath);
      if (!out.existsSync() || out.lengthSync() < 100) {
        throw AsrAudioExtractionException(
          AsrAudioExtractionFailureReason.noAudioTrack,
          'Extracted audio is empty or missing',
        );
      }
      final extractedSize = out.lengthSync();
      if (extractedSize > maxBytes) {
        throw AsrAudioExtractionException(
          AsrAudioExtractionFailureReason.fileTooLarge,
          'Extracted audio is $extractedSize bytes (max $maxBytes)',
        );
      }
      onProgress?.call(1.0);
      return await out.readAsBytes();
    } finally {
      try {
        final f = File(outputPath);
        if (f.existsSync()) await f.delete();
      } on Object catch (_) {}
    }
  }

  Future<bool> _runExtract({
    required String input,
    required String outputWav,
    required void Function(double progress)? onProgress,
  }) async {
    final bool usesKit = !FfmpegMediaProbe.usesFfmpegCli;
    if (usesKit) onProgress?.call(0.1);
    final result = await runFfmpegArgv(
      args: _extractArgs(input: input, outputWav: outputWav),
      failLabel: 'asr extract',
      cliBackend: FfmpegCliBackend.isolateRun,
      outputPath: outputWav,
    );
    if (usesKit) onProgress?.call(0.9);
    switch (result.outcome) {
      case FfmpegOutcome.success:
        return true;
      case FfmpegOutcome.unavailable:
        throw AsrAudioExtractionException(
          AsrAudioExtractionFailureReason.ffmpegUnavailable,
          'ffmpeg not available',
        );
      case FfmpegOutcome.failed:
      case FfmpegOutcome.cancelled:
      case FfmpegOutcome.timedOut:
        return false;
    }
  }
}

List<String> _extractArgs({required String input, required String outputWav}) =>
    <String>[
      '-nostdin',
      '-hide_banner',
      '-loglevel',
      'error',
      '-y',
      '-i',
      input,
      '-vn',
      '-af',
      'aformat=sample_fmts=s16:channel_layouts=mono',
      '-ar',
      '16000',
      '-ac',
      '1',
      '-c:a',
      'pcm_s16le',
      outputWav,
    ];
