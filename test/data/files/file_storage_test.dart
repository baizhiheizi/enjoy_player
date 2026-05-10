import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:cross_file/cross_file.dart';
import 'package:enjoy_player/core/errors/app_failure.dart';
import 'package:enjoy_player/data/files/chunked_file_hash.dart';
import 'package:enjoy_player/data/files/file_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import '../../support/test_path_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('importPickedFile uses web-aligned partial hash for 4MiB file', () async {
    final original = PathProviderPlatform.instance;
    final root = Directory.systemTemp.createTempSync('enjoy_file_storage_test');
    PathProviderPlatform.instance = TestPathProvider(root.path);

    addTearDown(() {
      PathProviderPlatform.instance = original;
      if (root.existsSync()) {
        root.deleteSync(recursive: true);
      }
    });

    final size = 4 * 1024 * 1024;
    final data = Uint8List(size);
    for (var i = 0; i < size; i++) {
      data[i] = (i * 17 + 3) & 0xff;
    }
    final srcPath = p.join(root.path, 'big.bin');
    await File(srcPath).writeAsBytes(data, flush: true);
    final expectedHash = chunkedContentSha256HexFromFileSync(srcPath);

    final storage = FileStorage();
    final result = await storage.importPickedFile(XFile(srcPath, name: 'big.bin'));

    expect(result.contentHashHex, expectedHash);
    expect(result.fileSize, size);
    expect(File(result.localPath).existsSync(), isTrue);
    expect(await File(result.localPath).readAsBytes(), data);
  });

  test('importPickedFileExpectingHash succeeds when hash matches', () async {
    final original = PathProviderPlatform.instance;
    final root = Directory.systemTemp.createTempSync('enjoy_file_storage_test');
    PathProviderPlatform.instance = TestPathProvider(root.path);

    addTearDown(() {
      PathProviderPlatform.instance = original;
      if (root.existsSync()) {
        root.deleteSync(recursive: true);
      }
    });

    final data = Uint8List.fromList([1, 2, 3, 4, 5]);
    final expectedHash = sha256.convert(data).toString();
    final srcPath = p.join(root.path, 'match.bin');
    await File(srcPath).writeAsBytes(data, flush: true);

    final storage = FileStorage();
    final result = await storage.importPickedFileExpectingHash(
      XFile(srcPath, name: 'match.bin'),
      expectedHashHex: expectedHash,
    );

    expect(result.contentHashHex, expectedHash);
    expect(File(result.localPath).existsSync(), isTrue);
  });

  test('importPickedFileExpectingHash throws FileFailure when hash mismatches',
      () async {
    final original = PathProviderPlatform.instance;
    final root = Directory.systemTemp.createTempSync('enjoy_file_storage_test');
    PathProviderPlatform.instance = TestPathProvider(root.path);

    addTearDown(() {
      PathProviderPlatform.instance = original;
      if (root.existsSync()) {
        root.deleteSync(recursive: true);
      }
    });

    final data = Uint8List.fromList([9, 9, 9]);
    final wrongExpected = sha256.convert(Uint8List.fromList([0])).toString();
    final srcPath = p.join(root.path, 'bad.bin');
    await File(srcPath).writeAsBytes(data, flush: true);

    final storage = FileStorage();
    expect(
      () => storage.importPickedFileExpectingHash(
        XFile(srcPath, name: 'bad.bin'),
        expectedHashHex: wrongExpected,
      ),
      throwsA(isA<FileFailure>()),
    );

    final mediaDir = Directory(p.join(root.path, 'media'));
    if (mediaDir.existsSync()) {
      final temps = mediaDir
          .listSync()
          .where((e) => p.basename(e.path).startsWith('.tmp_'));
      expect(temps, isEmpty);
    }
  });
}
