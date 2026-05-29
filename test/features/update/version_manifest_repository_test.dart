import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:enjoy_player/features/update/data/version_manifest_repository.dart';

void main() {
  test('parses latest.json assets and minSupportedVersion', () async {
    final client = MockClient((request) async {
      return http.Response('''
{
  "version": "0.2.0",
  "build": 42,
  "minSupportedVersion": "0.1.5",
  "notes": "Hello",
  "assets": {
    "android_arm64_v8a": {
      "url": "https://dl.enjoy.bot/player/0.2.0/EnjoyPlayer-v0.2.0-arm64-v8a.apk",
      "sha256": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
    }
  }
}
''', 200);
    });

    final repo = VersionManifestRepository(
      client: client,
      manifestUrl: 'https://example.test/latest.json',
    );
    final manifest = await repo.fetchLatest();
    expect(manifest, isNotNull);
    expect(manifest!.version, '0.2.0');
    expect(manifest.build, 42);
    expect(manifest.minSupportedVersion, '0.1.5');
    expect(manifest.notes, 'Hello');
    expect(manifest.assets['android_arm64_v8a']?.url, contains('arm64'));
  });

  test('returns null on HTTP error', () async {
    final client = MockClient((_) async => http.Response('', 500));
    final repo = VersionManifestRepository(client: client);
    expect(await repo.fetchLatest(), isNull);
  });
}
