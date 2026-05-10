/// Copy picked files into app documents and expose stable file:// paths.
library;

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:cross_file/cross_file.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/errors/app_failure.dart';
import 'chunked_file_hash.dart';

class FileImportResult {
  const FileImportResult({
    required this.localPath,
    required this.contentHashHex,
    required this.fileSize,
    required this.title,
  });

  final String localPath;
  /// Web-aligned partial SHA-256 fingerprint (see [chunkedContentSha256HexFromFileSync]).
  final String contentHashHex;
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
  /// When set, import fails with [FileFailure] if chunked hash hex does not match.
  String? expectedHashHex,
});

typedef _ImportIsolateResult = ({
  String localPath,
  String contentHashHex,
  int fileSize,
  String title,
});

/// Copy bytes from source to temp; no hashing (hash computed separately).
Future<void> _streamCopyFile(String sourcePath, String destPath) async {
  final source = File(sourcePath);
  final dest = File(destPath);
  final sink = dest.openWrite();
  await for (final chunk in source.openRead()) {
    sink.add(chunk);
  }
  await sink.flush();
  await sink.close();
}

Future<_ImportIsolateResult> _importMediaFileInIsolate(_ImportIsolateArgs args) async {
  final tempPath = p.join(args.mediaDirPath, args.tempFileName);
  final tempFile = File(tempPath);

  final contentHashHex = chunkedContentSha256HexFromFileSync(args.sourcePath);

  final expected = args.expectedHashHex;
  if (expected != null && expected.isNotEmpty && expected != contentHashHex) {
    if (await tempFile.exists()) {
      await tempFile.delete();
    }
    throw 'HASH_MISMATCH';
  }

  await _streamCopyFile(args.sourcePath, tempPath);
  final writtenLength = await tempFile.length();

  final destPath = p.join(args.mediaDirPath, '$contentHashHex${args.ext}');
  final destFile = File(destPath);
  if (await destFile.exists()) {
    await tempFile.delete();
    return (
      localPath: destPath,
      contentHashHex: contentHashHex,
      fileSize: await destFile.length(),
      title: args.title,
    );
  }

  await tempFile.rename(destPath);

  return (
    localPath: destPath,
    contentHashHex: contentHashHex,
    fileSize: writtenLength,
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
        contentHashHex: worker.contentHashHex,
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

  /// Like [importPickedFile], but only succeeds when the file's chunked SHA-256
  /// hex matches [expectedHashHex] (same value stored in Drift `md5` column).
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
        contentHashHex: worker.contentHashHex,
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
