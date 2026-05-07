import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:cross_file/cross_file.dart';
import 'package:enjoy_player/data/files/file_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import '../../support/test_path_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('importPickedFile streams hash and matches sha256 of source', () async {
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
    final expectedHash = sha256.convert(data).toString();

    final srcPath = p.join(root.path, 'big.bin');
    await File(srcPath).writeAsBytes(data, flush: true);

    final storage = FileStorage();
    final result = await storage.importPickedFile(XFile(srcPath, name: 'big.bin'));

    expect(result.fileHash, expectedHash);
    expect(result.fileSize, size);
    expect(File(result.localPath).existsSync(), isTrue);
    expect(
      sha256.convert(await File(result.localPath).readAsBytes()).toString(),
      expectedHash,
    );
  });
}
