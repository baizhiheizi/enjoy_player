/// Copy picked files into app documents and expose stable file:// paths.
library;

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

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

/// Arguments for [_importMediaFileInIsolate]; only plain data for [Isolate.run].
typedef _ImportIsolateArgs = ({
  String sourcePath,
  String mediaDirPath,
  String tempFileName,
  String ext,
  String title,
  /// When set, import fails with [FileFailure] if SHA-256 hex does not match.
  String? expectedHashHex,
});

typedef _ImportIsolateResult = ({
  String localPath,
  String fileHash,
  int fileSize,
  String title,
});

/// Heavy read + SHA-256 + write runs off the UI isolate.
Future<_ImportIsolateResult> _importMediaFileInIsolate(_ImportIsolateArgs args) async {
  final source = File(args.sourcePath);
  final tempPath = p.join(args.mediaDirPath, args.tempFileName);
  final tempFile = File(tempPath);

  final controller = StreamController<List<int>>();
  final hashFuture = sha256.bind(controller.stream).first;
  var length = 0;
  final sink = tempFile.openWrite();

  await for (final chunk in source.openRead()) {
    length += chunk.length;
    sink.add(chunk);
    controller.add(chunk);
  }
  await sink.flush();
  await sink.close();
  await controller.close();
  final digest = await hashFuture;
  final hash = digest.toString();

  final expected = args.expectedHashHex;
  if (expected != null && expected.isNotEmpty && expected != hash) {
    if (await tempFile.exists()) {
      await tempFile.delete();
    }
    // String is reliably passed across [Isolate.run] error boundaries.
    throw 'HASH_MISMATCH';
  }

  final destPath = p.join(args.mediaDirPath, '$hash${args.ext}');
  final destFile = File(destPath);
  if (await destFile.exists()) {
    await tempFile.delete();
    return (
      localPath: destPath,
      fileHash: hash,
      fileSize: await destFile.length(),
      title: args.title,
    );
  }

  await tempFile.rename(destPath);

  return (
    localPath: destPath,
    fileHash: hash,
    fileSize: length,
    title: args.title,
  );
}

class FileStorage {
  // ignore: prefer_const_constructors
  static final Uuid _uuid = Uuid();

  Future<FileImportResult> importPickedFile(XFile file) async {
    try {
      final path = file.path;
      if (path.isEmpty) {
        throw const FileFailure('Import failed: no file path');
      }

      final docs = await getApplicationDocumentsDirectory();
      final mediaDir = Directory(p.join(docs.path, 'media'));
      if (!await mediaDir.exists()) {
        await mediaDir.create(recursive: true);
      }

      final ext = p.extension(file.name).toLowerCase();
      final tempFileName = '.tmp_${_uuid.v4()}$ext';
      final title = p.basenameWithoutExtension(file.name);
      final mediaDirPath = mediaDir.path;

      final worker = await Isolate.run(
        () => _importMediaFileInIsolate((
          sourcePath: path,
          mediaDirPath: mediaDirPath,
          tempFileName: tempFileName,
          ext: ext,
          title: title,
          expectedHashHex: null,
        )),
      );

      return FileImportResult(
        localPath: worker.localPath,
        fileHash: worker.fileHash,
        fileSize: worker.fileSize,
        title: worker.title,
      );
    } catch (e, st) {
      if (e is FileFailure) {
        Error.throwWithStackTrace(e, st);
      }
      if (e == 'HASH_MISMATCH') {
        Error.throwWithStackTrace(
          const FileFailure(
            'Hash mismatch: file does not match synced media.',
          ),
          st,
        );
      }
      Error.throwWithStackTrace(
        FileFailure('Import failed: $e'),
        st,
      );
    }
  }

  /// Like [importPickedFile], but only succeeds when the file's SHA-256 hex
  /// matches [expectedHashHex] (same value stored in Drift `md5` column).
  Future<FileImportResult> importPickedFileExpectingHash(
    XFile file, {
    required String expectedHashHex,
  }) async {
    try {
      final path = file.path;
      if (path.isEmpty) {
        throw const FileFailure('Import failed: no file path');
      }

      final docs = await getApplicationDocumentsDirectory();
      final mediaDir = Directory(p.join(docs.path, 'media'));
      if (!await mediaDir.exists()) {
        await mediaDir.create(recursive: true);
      }

      final ext = p.extension(file.name).toLowerCase();
      final tempFileName = '.tmp_${_uuid.v4()}$ext';
      final title = p.basenameWithoutExtension(file.name);
      final mediaDirPath = mediaDir.path;

      final worker = await Isolate.run(
        () => _importMediaFileInIsolate((
          sourcePath: path,
          mediaDirPath: mediaDirPath,
          tempFileName: tempFileName,
          ext: ext,
          title: title,
          expectedHashHex: expectedHashHex,
        )),
      );

      return FileImportResult(
        localPath: worker.localPath,
        fileHash: worker.fileHash,
        fileSize: worker.fileSize,
        title: worker.title,
      );
    } catch (e, st) {
      if (e is FileFailure) {
        Error.throwWithStackTrace(e, st);
      }
      if (e == 'HASH_MISMATCH') {
        Error.throwWithStackTrace(
          const FileFailure(
            'Hash mismatch: file does not match synced media.',
          ),
          st,
        );
      }
      Error.throwWithStackTrace(
        FileFailure('Import failed: $e'),
        st,
      );
    }
  }
}
