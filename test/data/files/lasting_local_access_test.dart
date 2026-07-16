import 'dart:io';

import 'package:enjoy_player/data/files/lasting_local_access.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import '../../support/test_path_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PathProviderPlatform original;
  late Directory root;

  setUp(() {
    original = PathProviderPlatform.instance;
    root = Directory.systemTemp.createTempSync('enjoy_lasting_access');
    PathProviderPlatform.instance = TestPathProvider(root.path);
  });

  tearDown(() {
    PathProviderPlatform.instance = original;
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  });

  test('canLinkExternally is true for durable path under documents', () async {
    final file = File(p.join(root.path, 'movie.mp4'));
    await file.writeAsBytes([1, 2, 3]);
    expect(await canLinkExternally(file.path), isTrue);
  });

  test('canLinkExternally is false for temp and cache paths', () async {
    final tmpDir = Directory(p.join(root.path, '.os_tmp'))
      ..createSync(recursive: true);
    final cacheDir = Directory(p.join(root.path, '.os_cache'))
      ..createSync(recursive: true);
    final tmpFile = File(p.join(tmpDir.path, 'picked.mp4'));
    final cacheFile = File(p.join(cacheDir.path, 'picked.mp4'));
    await tmpFile.writeAsBytes([1]);
    await cacheFile.writeAsBytes([1]);

    expect(await canLinkExternally(tmpFile.path), isFalse);
    expect(await canLinkExternally(cacheFile.path), isFalse);
  });

  test('canLinkExternally is false for missing or empty path', () async {
    expect(await canLinkExternally(''), isFalse);
    expect(await canLinkExternally(p.join(root.path, 'missing.mp4')), isFalse);
  });

  test('isAppManagedMediaPath detects documents/media', () async {
    final media = Directory(p.join(root.path, 'media'))
      ..createSync(recursive: true);
    final managed = File(p.join(media.path, 'abc.mp3'));
    await managed.writeAsBytes([9]);
    final external = File(p.join(root.path, 'external.mp3'));
    await external.writeAsBytes([8]);

    expect(await isAppManagedMediaPath(managed.path), isTrue);
    expect(
      await isAppManagedMediaPath(Uri.file(managed.path).toString()),
      isTrue,
    );
    expect(await isAppManagedMediaPath(external.path), isFalse);
  });
}
