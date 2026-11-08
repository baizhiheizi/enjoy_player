import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('sqlite3 native library prefetch', () {
    late Directory workspace;
    late Directory pubCache;
    late _ReleaseServer server;

    const releaseTag = 'sqlite3-9.9.9';

    final linuxAssets = <String, List<int>>{
      'libsqlite3.x64.linux.so': List<int>.generate(4096, (i) => i % 251),
      'libsqlite3.arm64.linux.so': List<int>.generate(
        4096,
        (i) => (i * 7) % 251,
      ),
      'libsqlite3.arm.linux.so': List<int>.generate(
        4096,
        (i) => (i * 13) % 251,
      ),
      'libsqlite3.ia32.linux.so': List<int>.generate(
        4096,
        (i) => (i * 17) % 251,
      ),
      'libsqlite3.riscv64.linux.so': List<int>.generate(
        4096,
        (i) => (i * 19) % 251,
      ),
    };

    final androidAssets = <String, List<int>>{
      'libsqlite3.x64.android.so': List<int>.generate(2048, (i) => i % 241),
      'libsqlite3.arm64.android.so': List<int>.generate(
        2048,
        (i) => (i * 3) % 241,
      ),
    };

    setUp(() async {
      workspace = Directory.systemTemp.createTempSync('sqlite3_prefetch_test_');
      pubCache = Directory('${workspace.path}/.pub-cache')..createSync();
      server = await _ReleaseServer.start(
        releaseTag: releaseTag,
        assets: {...linuxAssets, ...androidAssets},
      );
    });

    tearDown(() async {
      await server.close();
      if (workspace.existsSync()) {
        workspace.deleteSync(recursive: true);
      }
    });

    Future<ProcessResult> runScript({
      required String platform,
      Map<String, String> extraEnv = const {},
      String? browserBaseUrl,
    }) {
      final toolDir = Directory('${workspace.path}/tool')..createSync();
      File(
        'tool/prefetch_sqlite3_libs.sh',
      ).copySync('${toolDir.path}/prefetch_sqlite3_libs.sh');
      File('${workspace.path}/pubspec.lock').writeAsStringSync('''
packages:
  sqlite3:
    dependency: transitive
    description:
      name: sqlite3
      url: "https://pub.dev"
    source: hosted
    version: "9.9.9"
''');
      writeAssetHashes(pubCache, releaseTag, {
        ...linuxAssets,
        ...androidAssets,
      });

      return Process.run(
        'bash',
        ['${toolDir.path}/prefetch_sqlite3_libs.sh', platform],
        workingDirectory: workspace.path,
        environment: {
          'PATH': Platform.environment['PATH'] ?? '',
          'HOME': workspace.path,
          'PUB_CACHE': pubCache.path,
          'SQLITE3_BASE_URL': browserBaseUrl ?? server.browserBaseUrl,
          'SQLITE3_API_ROOT': server.apiRoot,
          ...extraEnv,
        },
      );
    }

    test(
      'falls back to the API asset endpoint when the download URL fails',
      () async {
        server.browserStatus = HttpStatus.gatewayTimeout;

        final result = await runScript(platform: 'linux');

        expect(result.exitCode, 0, reason: result.stderr.toString());
        final asset = server.requestedAssets.single;
        expect(asset.name, contains('linux'));
        final cached = File(
          '${workspace.path}/.dart_tool/hooks_runner/shared/sqlite3/build/'
          'download-${sha256Hex(asset.bytes).substring(0, 8)}/libsqlite3.so',
        );
        expect(cached.existsSync(), isTrue);
        expect(cached.readAsBytesSync(), asset.bytes);
      },
      timeout: const Timeout(Duration(minutes: 3)),
    );

    test('uses the download URL when it works', () async {
      server.browserStatus = HttpStatus.ok;

      final result = await runScript(platform: 'linux');

      expect(result.exitCode, 0, reason: result.stderr.toString());
      expect(server.apiRequests, isEmpty);
      expect(server.requestedAssets, hasLength(1));
    }, timeout: const Timeout(Duration(minutes: 3)));

    test(
      'keeps the assets it could fetch when one asset is unreachable',
      () async {
        server.browserStatus = HttpStatus.gatewayTimeout;
        server.unreachableAssets.add('libsqlite3.x64.android.so');

        final result = await runScript(platform: 'android');

        expect(result.exitCode, isNot(0));
        expect(result.stderr.toString(), contains('libsqlite3.x64.android.so'));
        final reachable = server.requestedAssets
            .map((asset) => asset.name)
            .where((name) => name != 'libsqlite3.x64.android.so')
            .toList();
        expect(reachable, isNotEmpty);
        for (final name in reachable) {
          final bytes = {...androidAssets}[name]!;
          final cached = File(
            '${workspace.path}/.dart_tool/hooks_runner/shared/sqlite3/build/'
            'download-${sha256Hex(bytes).substring(0, 8)}/libsqlite3.so',
          );
          expect(cached.existsSync(), isTrue, reason: name);
        }
      },
      timeout: const Timeout(Duration(minutes: 3)),
    );

    test('fetches only the host architecture for a Linux build', () async {
      server.browserStatus = HttpStatus.ok;

      final result = await runScript(platform: 'linux');

      expect(result.exitCode, 0, reason: result.stderr.toString());
      expect(server.requestedAssets, hasLength(1));
    }, timeout: const Timeout(Duration(minutes: 3)));
  });
}

String sha256Hex(List<int> bytes) => sha256.convert(bytes).toString();

void writeAssetHashes(
  Directory pubCache,
  String releaseTag,
  Map<String, List<int>> assets,
) {
  final packageDir = Directory(
    '${pubCache.path}/hosted/pub.dev/sqlite3-${releaseTag.replaceAll('sqlite3-', '')}'
    '/lib/src/hook',
  )..createSync(recursive: true);
  final entries = assets.entries
      .map((entry) => "  '${entry.key}': '${sha256Hex(entry.value)}',")
      .join('\n');
  File('${packageDir.path}/asset_hashes.dart').writeAsStringSync('''
const String? releaseTag = '$releaseTag';

const Map<String, String> assetNameToSha256Hash = {
$entries
};
''');
}

class _ServedAsset {
  _ServedAsset(this.name, this.bytes);

  final String name;
  final List<int> bytes;
}

class _ReleaseServer {
  _ReleaseServer._(this._server, this.releaseTag, this.assets);

  static Future<_ReleaseServer> start({
    required String releaseTag,
    required Map<String, List<int>> assets,
  }) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final instance = _ReleaseServer._(server, releaseTag, assets);
    unawaited(instance._serve());
    return instance;
  }

  final HttpServer _server;
  final String releaseTag;
  final Map<String, List<int>> assets;

  final List<_ServedAsset> requestedAssets = [];
  final List<String> apiRequests = [];
  final Set<String> unreachableAssets = {};
  int browserStatus = HttpStatus.ok;

  String get browserBaseUrl =>
      'http://${_server.address.address}:${_server.port}/releases/download/$releaseTag';

  String get apiRoot => 'http://${_server.address.address}:${_server.port}';

  Future<void> _serve() async {
    await for (final request in _server) {
      final path = request.uri.path;
      if (path.startsWith('/releases/download/')) {
        final name = path.substring(path.lastIndexOf('/') + 1);
        await _serveAsset(request, name, useApi: false);
      } else if (path.contains('/releases/assets/')) {
        apiRequests.add(path);
        final id = int.parse(path.substring(path.lastIndexOf('/') + 1));
        final entry = assets.entries.elementAt(id);
        await _serveAsset(request, entry.key, useApi: true);
      } else if (path.contains('/releases/tags/')) {
        apiRequests.add(path);
        request.response.headers.contentType = ContentType.json;
        request.response.write(_manifest());
        await request.response.close();
      } else {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
      }
    }
  }

  Future<void> _serveAsset(
    HttpRequest request,
    String name, {
    required bool useApi,
  }) async {
    final bytes = assets[name];
    if (bytes == null || unreachableAssets.contains(name)) {
      request.response.statusCode = HttpStatus.gatewayTimeout;
      await request.response.close();
      return;
    }
    if (!useApi && browserStatus != HttpStatus.ok) {
      request.response.statusCode = browserStatus;
      await request.response.close();
      return;
    }
    requestedAssets.add(_ServedAsset(name, bytes));
    request.response.add(bytes);
    await request.response.close();
  }

  String _manifest() {
    final buffer = StringBuffer('{\n  "assets": [\n');
    var first = true;
    for (var i = 0; i < assets.length; i++) {
      if (!first) {
        buffer.write(',\n');
      }
      first = false;
      buffer.write('''
    {
      "url": "https://api.github.com/repos/simolus3/sqlite3.dart/releases/assets/$i",
      "id": $i,
      "name": "${assets.keys.elementAt(i)}",
      "state": "uploaded"
    }''');
    }
    buffer.write('\n  ]\n}\n');
    return buffer.toString();
  }

  Future<void> close() => _server.close(force: true);
}
