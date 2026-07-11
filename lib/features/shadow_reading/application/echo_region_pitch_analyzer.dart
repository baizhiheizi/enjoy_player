/// Runs envelope + YIN pitch extraction on decoded PCM.
///
/// The byte→Float32 decode and the pitch math both run inside a single worker
/// isolate ([Isolate.run]) so the multi-megabyte PCM buffer never crosses an
/// isolate port and never blocks the UI thread. Only the small analysis result
/// (~520 points) is returned to the main isolate.
library;

import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import '../data/echo_segment_pcm_extractor.dart';
import '../domain/echo_region_analysis.dart';
import '../domain/waveform_envelope.dart';
import '../domain/yin_pitch.dart';

/// Analyzes the reference media time range `[startSec, endSec)`.
///
/// Throws [EchoPcmExtractionException] on extraction/cancellation failure.
/// [token] cooperatively cancels the in-flight FFmpeg process; [timeout] bounds
/// each extraction step.
Future<EchoRegionAnalysisResult> analyzeMediaTimeRange({
  required String mediaPath,
  required double startSec,
  required double endSec,
  EchoPcmCancelToken? token,
  Duration timeout = kEchoPcmExtractionTimeout,
}) async {
  final dur = endSec - startSec;
  if (dur <= 0) {
    throw const EchoPcmExtractionException(EchoPcmFailureReason.invalidInput);
  }
  final tempPath = await extractMonoFloat32SegmentToTempFile(
    mediaFilePath: mediaPath,
    startSec: startSec,
    durationSec: dur,
    token: token,
    timeout: timeout,
  );
  return _decodeTempAndAnalyze(tempPath, token, timeout);
}

/// Analyzes an entire (short) user recording at [mediaPath].
///
/// Throws [EchoPcmExtractionException] on extraction/cancellation failure.
Future<EchoRegionAnalysisResult> analyzeMediaFileFull({
  required String mediaPath,
  EchoPcmCancelToken? token,
  Duration timeout = kEchoPcmExtractionTimeout,
}) async {
  final tempPath = await extractEntireFileToTempF32(
    mediaPath,
    token: token,
    timeout: timeout,
  );
  return _decodeTempAndAnalyze(tempPath, token, timeout);
}

/// Reads the FFmpeg-produced `.raw`, decodes it, and runs the pitch pipeline —
/// all inside one worker isolate (no large buffer crosses a port). The temp
/// file is always cleaned up.
Future<EchoRegionAnalysisResult> _decodeTempAndAnalyze(
  String tempPath,
  EchoPcmCancelToken? token,
  Duration timeout,
) async {
  try {
    if (token?.isCancelled ?? false) {
      throw const EchoPcmExtractionException(EchoPcmFailureReason.cancelled);
    }
    final f = File(tempPath);
    if (!f.existsSync() || f.lengthSync() < 4) {
      throw const EchoPcmExtractionException(EchoPcmFailureReason.emptyOutput);
    }
    final sampleRate = kEchoPcmSampleRate.toDouble();
    final args = _DecodeAndAnalyzeArgs(
      tempPath: tempPath,
      sampleRate: sampleRate,
    );
    return await Isolate.run(
      () => _decodeAndAnalyze(args),
      debugName: 'echo-pcm-analyze',
    ).timeout(
      timeout,
      onTimeout: () {
        throw const EchoPcmExtractionException(EchoPcmFailureReason.timeout);
      },
    );
  } finally {
    try {
      final f = File(tempPath);
      if (f.existsSync()) await f.delete();
    } catch (_) {}
  }
}

class _DecodeAndAnalyzeArgs {
  const _DecodeAndAnalyzeArgs({
    required this.tempPath,
    required this.sampleRate,
  });
  final String tempPath;
  final double sampleRate;
}

/// Worker-isolate entry point: reads the temp `.raw`, decodes it to Float32
/// (no extra copy), and runs the full pitch pipeline. Top-level + sync so it
/// can run inside [Isolate.run] and be unit-tested directly via
/// [analyzePcmSamples].
EchoRegionAnalysisResult _decodeAndAnalyze(_DecodeAndAnalyzeArgs args) {
  final bytes = File(args.tempPath).readAsBytesSync();
  final samples = decodeF32leBytes(bytes);
  return analyzePcmSamples(samples, args.sampleRate);
}

/// Pure pitch pipeline over already-decoded PCM. Public so it is unit-testable
/// without a live FFmpeg: envelope → YIN → time-map → series points.
EchoRegionAnalysisResult analyzePcmSamples(
  Float32List samples,
  double sampleRate,
) {
  final env = computePeakEnvelope(samples, sampleRate, points: 520);
  final yin = estimatePitchYin(samples, sampleRate);
  final hz = pitchAtEnvelopeTimes(envelope: env, yin: yin);
  final points = buildSeriesPoints(envelope: env, pitchHzList: hz);
  final durationSeconds = samples.length / sampleRate;
  return EchoRegionAnalysisResult(
    points: points,
    durationSeconds: durationSeconds,
    sampleRate: sampleRate,
  );
}
