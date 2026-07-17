/// Platform save/share for Anki CSV bytes.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

enum VocabularyAnkiExportIoOutcome { shared, saved, cancelled, failed }

/// Writes [bytes] via share sheet (mobile) or save dialog (desktop).
Future<VocabularyAnkiExportIoOutcome> saveOrShareAnkiCsv({
  required Uint8List bytes,
  String? fileName,
  String? dialogTitle,
}) async {
  final name =
      fileName ??
      'enjoy-vocabulary-anki-${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';
  try {
    if (Platform.isIOS || Platform.isAndroid) {
      final file = XFile.fromData(bytes, mimeType: 'text/csv', name: name);
      final result = await SharePlus.instance.share(ShareParams(files: [file]));
      if (result.status == ShareResultStatus.dismissed) {
        return VocabularyAnkiExportIoOutcome.cancelled;
      }
      return VocabularyAnkiExportIoOutcome.shared;
    }

    final savedPath = await FilePicker.saveFile(
      dialogTitle: dialogTitle ?? 'Export to Anki',
      fileName: name,
      bytes: bytes,
    );
    if (savedPath == null) return VocabularyAnkiExportIoOutcome.cancelled;
    return VocabularyAnkiExportIoOutcome.saved;
  } on Object {
    return VocabularyAnkiExportIoOutcome.failed;
  }
}
