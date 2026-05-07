/// Copy picked files into app documents and expose stable file:// paths.
library;

import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/errors/app_failure.dart';

class FileImportResult {
  const FileImportResult({
    required this.localPath,
    required this.fileHash,
    required this.fileSize,
    required this.title,
  });

  final String localPath;
  final String fileHash;
  final int fileSize;
  final String title;

  String get fileUri => Uri.file(localPath).toString();
}

class FileStorage {
  Future<FileImportResult> importPickedFile(XFile file) async {
    try {
      final docs = await getApplicationDocumentsDirectory();
      final mediaDir = Directory(p.join(docs.path, 'media'));
      if (!await mediaDir.exists()) {
        await mediaDir.create(recursive: true);
      }

      final bytes = await file.readAsBytes();
      final hash = sha256.convert(bytes).toString();
      final ext = p.extension(file.name).toLowerCase();
      final destPath = p.join(mediaDir.path, '$hash$ext');
      await File(destPath).writeAsBytes(bytes, flush: true);

      return FileImportResult(
        localPath: destPath,
        fileHash: hash,
        fileSize: bytes.length,
        title: p.basenameWithoutExtension(file.name),
      );
    } catch (e, st) {
      Error.throwWithStackTrace(FileFailure('Import failed: $e'), st);
    }
  }
}
