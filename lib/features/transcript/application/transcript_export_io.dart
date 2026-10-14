/// Platform save/share for exported transcript bytes.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

enum TranscriptExportIoOutcome { shared, saved, cancelled, failed }

/// Writes [bytes] via share sheet (mobile) or save dialog (desktop).
Future<TranscriptExportIoOutcome> saveOrShareTranscriptFile({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
  required String dialogTitle,
}) async {
  try {
    if (Platform.isIOS || Platform.isAndroid) {
      final file = XFile.fromData(bytes, mimeType: mimeType, name: fileName);
      final result = await SharePlus.instance.share(ShareParams(files: [file]));
      if (result.status == ShareResultStatus.dismissed) {
        return TranscriptExportIoOutcome.cancelled;
      }
      return TranscriptExportIoOutcome.shared;
    }

    final savedPath = await FilePicker.saveFile(
      dialogTitle: dialogTitle,
      fileName: fileName,
      bytes: bytes,
    );
    if (savedPath == null) return TranscriptExportIoOutcome.cancelled;
    return TranscriptExportIoOutcome.saved;
  } on Object {
    return TranscriptExportIoOutcome.failed;
  }
}
