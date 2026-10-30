/// Shared "hand bytes or a file to the user" export flow: share sheet on
/// iOS / Android, save dialog on desktop.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/core/platform/mobile_platform.dart';

final _log = logNamed('FileShareExport');

/// Outcome of handing bytes / a file to the user: [shared] / [saved] once
/// the platform surface accepted the payload, [cancelled] when the user
/// dismissed the share sheet or save dialog, [failed] when the flow threw.
enum FileShareOutcome { shared, saved, cancelled, failed }

/// Hands [bytes] to the user: share sheet (mobile) or save dialog (desktop).
Future<FileShareOutcome> saveOrShareBytes({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
  String? dialogTitle,
}) {
  return _saveOrShare(
    bytes: bytes,
    fileName: fileName,
    mimeType: mimeType,
    dialogTitle: dialogTitle,
  );
}

/// Hands the file at [sourcePath] to the user. Mobile shares in place;
/// desktop stages the file's bytes through the save dialog.
Future<FileShareOutcome> saveOrShareFile({
  required String sourcePath,
  required String fileName,
  required String mimeType,
  String? dialogTitle,
}) {
  return _saveOrShare(
    sourcePath: sourcePath,
    fileName: fileName,
    mimeType: mimeType,
    dialogTitle: dialogTitle,
  );
}

Future<FileShareOutcome> _saveOrShare({
  Uint8List? bytes,
  String? sourcePath,
  required String fileName,
  required String mimeType,
  String? dialogTitle,
}) async {
  try {
    if (isMobilePlatform) {
      final file = sourcePath == null
          ? XFile.fromData(bytes!, mimeType: mimeType)
          : XFile(sourcePath, mimeType: mimeType);
      final result = await SharePlus.instance.share(ShareParams(files: [file]));
      if (result.status == ShareResultStatus.dismissed) {
        return FileShareOutcome.cancelled;
      }
      return FileShareOutcome.shared;
    }

    final saved = await FilePicker.saveFile(
      dialogTitle: dialogTitle,
      fileName: fileName,
      bytes: sourcePath == null ? bytes! : await File(sourcePath).readAsBytes(),
      mimeType: mimeType,
    );
    if (saved == null) return FileShareOutcome.cancelled;
    return FileShareOutcome.saved;
  } on Object catch (error, stackTrace) {
    _log.warning('save/share of "$fileName" failed', error, stackTrace);
    return FileShareOutcome.failed;
  }
}
