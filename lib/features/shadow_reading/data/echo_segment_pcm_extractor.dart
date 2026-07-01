/// Extracts mono `float32` PCM for a media time range via FFmpeg CLI (desktop) or FFmpegKit.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:enjoy_player/core/logging/log.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

final _log = logNamed('EchoSegmentPcmExtractor');

/// Sample rate used for extracted PCM (fixed for consistent pitch hop math).
const int kEchoPcmSampleRate = 44100;

class EchoSegmentPcmResult {
  EchoSegmentPcmResult({required this.samples, required this.sampleRate});

  final Float32List samples;
  final double sampleRate;
}

/// Extracts mono 32-bit float PCM for `[startSec, startSec + durationSec)`.
Future<EchoSegmentPcmResult?> extractMonoFloat32Segment({
  required String mediaFilePath,
  required double startSec,
  required double durationSec,
}) async {
  if (durationSec <= 0 || mediaFilePath.trim().isEmpty) return null;
  if (!File(mediaFilePath).existsSync()) return null;
  final tempDir = await getTemporaryDirectory();
  final outFile = p.join(
    tempDir.path,
    'echo_seg_${DateTime.now().microsecondsSinceEpoch}.raw',
  );

  try {
    final ok = await _runFfmpegExtract(
      mediaPath: mediaFilePath,
      outPath: outFile,
      startSec: startSec,
      durationSec: durationSec,
    );
    if (!ok) return null;
    final f = File(outFile);
    if (!f.existsSync()) return null;
    final bytes = await f.readAsBytes();
    if (bytes.length < 4) return null;
    final u8 = Uint8List.fromList(bytes);
    final bd = ByteData.sublistView(u8);
    final nFloat = bd.lengthInBytes ~/ 4;
    final samples = Float32List(nFloat);
    for (var i = 0; i < nFloat; i++) {
      samples[i] = bd.getFloat32(i * 4, Endian.little);
    }
    return EchoSegmentPcmResult(
      samples: samples,
      sampleRate: kEchoPcmSampleRate.toDouble(),
    );
  } finally {
    try {
      final f = File(outFile);
      if (f.existsSync()) await f.delete();
    } catch (_) {}
  }
}

Future<bool> _runFfmpegExtract({
  required String mediaPath,
  required String outPath,
  required double startSec,
  required double durationSec,
}) async {
  final ss = startSec.toStringAsFixed(4);
  final dur = durationSec.toStringAsFixed(4);

  if (Platform.isWindows) {
    final exe = await _resolveWindowsFfmpeg();
    if (exe == null) {
      _log.warning('No FFmpeg on Windows for pitch extraction');
      return false;
    }
    final r = await Process.run(exe, [
      '-y',
      '-ss',
      ss,
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
    ]);
    if (r.exitCode != 0) {
      _log.fine('ffmpeg segment failed: ${r.stderr}');
      return false;
    }
    return true;
  }

  final cmd =
      '-y -ss $ss -i ${_shellEscape(mediaPath)} -t $dur -vn -ac 1 -ar $kEchoPcmSampleRate -f f32le ${_shellEscape(outPath)}';
  final session = await FFmpegKit.execute(cmd);
  final code = await session.getReturnCode();
  if (!ReturnCode.isSuccess(code)) {
    _log.fine('FFmpegKit segment failed: ${await session.getOutput()}');
    return false;
  }
  return true;
}

/// Decodes full media (or local file) to mono float32 PCM (for short user recordings).
Future<EchoSegmentPcmResult?> extractEntireFileMonoF32(
  String mediaFilePath,
) async {
  if (mediaFilePath.trim().isEmpty) return null;
  if (!File(mediaFilePath).existsSync()) return null;
  final tempDir = await getTemporaryDirectory();
  final outFile = p.join(
    tempDir.path,
    'echo_full_${DateTime.now().microsecondsSinceEpoch}.raw',
  );
  try {
    final ok = await _runFfmpegFullDecode(
      mediaPath: mediaFilePath,
      outPath: outFile,
    );
    if (!ok) return null;
    final f = File(outFile);
    if (!f.existsSync()) return null;
    final bytes = await f.readAsBytes();
    if (bytes.length < 4) return null;
    final u8 = Uint8List.fromList(bytes);
    final bd = ByteData.sublistView(u8);
    final nFloat = bd.lengthInBytes ~/ 4;
    final samples = Float32List(nFloat);
    for (var i = 0; i < nFloat; i++) {
      samples[i] = bd.getFloat32(i * 4, Endian.little);
    }
    return EchoSegmentPcmResult(
      samples: samples,
      sampleRate: kEchoPcmSampleRate.toDouble(),
    );
  } finally {
    try {
      final f = File(outFile);
      if (f.existsSync()) await f.delete();
    } catch (_) {}
  }
}

Future<bool> _runFfmpegFullDecode({
  required String mediaPath,
  required String outPath,
}) async {
  if (Platform.isWindows) {
    final exe = await _resolveWindowsFfmpeg();
    if (exe == null) {
      _log.warning('No FFmpeg on Windows for pitch extraction');
      return false;
    }
    final r = await Process.run(exe, [
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
    ]);
    if (r.exitCode != 0) {
      _log.fine('ffmpeg full decode failed: ${r.stderr}');
      return false;
    }
    return true;
  }
  final cmd =
      '-y -i ${_shellEscape(mediaPath)} -vn -ac 1 -ar $kEchoPcmSampleRate -f f32le ${_shellEscape(outPath)}';
  final session = await FFmpegKit.execute(cmd);
  final code = await session.getReturnCode();
  if (!ReturnCode.isSuccess(code)) {
    _log.fine('FFmpegKit full decode failed: ${await session.getOutput()}');
    return false;
  }
  return true;
}

String _shellEscape(String path) {
  if (path.contains(' ') || path.contains('"')) {
    return '"${path.replaceAll('"', r'\"')}"';
  }
  return path;
}

Future<String?> _resolveWindowsFfmpeg() async {
  final bundled = p.join(p.dirname(Platform.resolvedExecutable), 'ffmpeg.exe');
  if (File(bundled).existsSync()) return bundled;
  try {
    final r = await Process.run('ffmpeg', ['-version']);
    if (r.exitCode == 0) return 'ffmpeg';
  } catch (_) {}
  return null;
}
