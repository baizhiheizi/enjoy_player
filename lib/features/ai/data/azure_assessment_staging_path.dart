/// ASCII-safe temp paths for Azure Speech WAV I/O on Windows.
///
/// Azure Speech `FromWavFileInput` has historically been brittle with
/// non-ASCII filesystem paths (e.g. `C:\Users\<中文>\AppData\Local\Temp\...`).
/// Prefer an ASCII-only staging root when the default system temp is not.
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

/// True when [path] contains any code unit outside 7-bit ASCII.
bool pathContainsNonAscii(String path) {
  for (final unit in path.codeUnits) {
    if (unit > 127) return true;
  }
  return false;
}

/// Picks a preferred Windows temp root when [systemTemp] is non-ASCII.
///
/// Returns [systemTemp] unchanged when it is already ASCII-only or when not
/// on Windows. Pure (no I/O) so unit tests can cover the preference order.
String preferAsciiTempRoot({
  required bool isWindows,
  required String systemTemp,
  String? systemRoot,
  String? windir,
}) {
  if (!isWindows || !pathContainsNonAscii(systemTemp)) {
    return systemTemp;
  }

  final candidates = <String>[];
  final root = systemRoot?.trim();
  if (root != null && root.isNotEmpty) {
    candidates.add(p.join(root, 'Temp', 'EnjoyPlayer'));
  }
  final win = windir?.trim();
  if (win != null && win.isNotEmpty) {
    candidates.add(p.join(win, 'Temp', 'EnjoyPlayer'));
  }
  candidates.add(p.join(r'C:\Windows', 'Temp', 'EnjoyPlayer'));

  for (final candidate in candidates) {
    if (!pathContainsNonAscii(candidate)) {
      return candidate;
    }
  }
  return systemTemp;
}

/// Resolves a writable staging directory for Azure assessment WAVs.
///
/// On Windows with a non-ASCII [Directory.systemTemp], prefers
/// `%SystemRoot%\Temp\EnjoyPlayer` (typically `C:\Windows\Temp\EnjoyPlayer`).
Future<Directory> resolveAzureAssessmentStagingDir({
  String? systemTempOverride,
  String? systemRootOverride,
  String? windirOverride,
}) async {
  final systemTemp = systemTempOverride ?? Directory.systemTemp.path;
  final preferred = preferAsciiTempRoot(
    isWindows: Platform.isWindows,
    systemTemp: systemTemp,
    systemRoot: systemRootOverride ?? Platform.environment['SystemRoot'],
    windir: windirOverride ?? Platform.environment['WINDIR'],
  );

  if (preferred == systemTemp) {
    return Directory(systemTemp);
  }

  final dir = Directory(preferred);
  try {
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final probe = File(p.join(dir.path, '.write_probe_${const Uuid().v4()}'));
    await probe.writeAsString('ok', flush: true);
    await probe.delete();
    return dir;
  } on Object {
    return Directory(systemTemp);
  }
}

/// Builds a unique `.wav` path under the Azure assessment staging directory.
Future<String> newAzureAssessmentStagingWavPath() async {
  final dir = await resolveAzureAssessmentStagingDir();
  return p.join(dir.path, 'azure_assess_${const Uuid().v4()}.wav');
}

/// Copies [audioPath] into an ASCII-safe staging dir when needed.
///
/// Returns `(path, shouldDeleteAfter)`. When the source path is already
/// ASCII-safe (or not Windows), returns the original path unchanged.
Future<(String path, bool shouldDelete)> stageWavForAzureAssessment(
  String audioPath,
) async {
  final absolute = File(audioPath).absolute.path;
  if (!Platform.isWindows || !pathContainsNonAscii(absolute)) {
    return (absolute, false);
  }

  final dest = await newAzureAssessmentStagingWavPath();
  await File(absolute).copy(dest);
  return (dest, true);
}
