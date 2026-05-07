/// Copy picked files into app documents and expose stable file:// paths.
library;

import 'dart:async';
import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

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
  // ignore: prefer_const_constructors
  static final Uuid _uuid = Uuid();

  Future<FileImportResult> importPickedFile(XFile file) async {
    try {
      final docs = await getApplicationDocumentsDirectory();
      final mediaDir = Directory(p.join(docs.path, 'media'));
      if (!await mediaDir.exists()) {
        await mediaDir.create(recursive: true);
      }

      final ext = p.extension(file.name).toLowerCase();
      final tempPath = p.join(mediaDir.path, '.tmp_${_uuid.v4()}$ext');
      final tempFile = File(tempPath);

      final controller = StreamController<List<int>>();
      final hashFuture = sha256.bind(controller.stream).first;
      var length = 0;
      final sink = tempFile.openWrite();

      await for (final chunk in file.openRead()) {
        length += chunk.length;
        sink.add(chunk);
        controller.add(chunk);
      }
      await sink.flush();
      await sink.close();
      await controller.close();
      final digest = await hashFuture;
      final hash = digest.toString();

      final destPath = p.join(mediaDir.path, '$hash$ext');
      final destFile = File(destPath);
      if (await destFile.exists()) {
        await tempFile.delete();
        return FileImportResult(
          localPath: destPath,
          fileHash: hash,
          fileSize: await destFile.length(),
          title: p.basenameWithoutExtension(file.name),
        );
      }

      await tempFile.rename(destPath);

      return FileImportResult(
        localPath: destPath,
        fileHash: hash,
        fileSize: length,
        title: p.basenameWithoutExtension(file.name),
      );
    } catch (e, st) {
      Error.throwWithStackTrace(FileFailure('Import failed: $e'), st);
    }
  }
}
