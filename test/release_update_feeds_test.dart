import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

const _scriptPath = '.github/scripts/verify_update_feeds.sh';

const _header = '''
<?xml version="1.0" encoding="utf-8"?>
<rss xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" version="2.0">
  <channel>
    <title>Enjoy Player</title>
    <link>https://enjoy.bot</link>
    <description>Enjoy Player direct-download updates</description>
    <language>en</language>
''';

const _footer = '''
  </channel>
</rss>
''';

String _item({
  required String version,
  required int build,
  required String os,
  String? signatureAttribute,
  String? signature,
}) {
  final signatureLine = signatureAttribute == null
      ? ''
      : '        $signatureAttribute="$signature"\n';
  return '''
    <item>
      <title>Version $version</title>
      <pubDate>Tue, 21 Oct 2026 10:00:00 +0000</pubDate>
      <sparkle:version>$build</sparkle:version>
      <sparkle:shortVersionString>$version</sparkle:shortVersionString>
      <enclosure url="https://dl.enjoy.bot/player/$version/EnjoyPlayer-$version" sparkle:os="$os" type="application/octet-stream" length="10"
$signatureLine      />
    </item>
''';
}

String _appcast(List<String> items) => '$_header${items.join()}$_footer';

String _manifest(List<String> platforms) {
  final assets = platforms
      .map(
        (platform) =>
            '    "$platform": {"url": "https://dl.enjoy.bot/player/0.10.3/x", "sha256": "ab", "file": "x"}',
      )
      .join(',\n');
  return '''
{
  "version": "0.10.3",
  "build": 19,
  "minSupportedVersion": "0.10.3",
  "notes": "",
  "assets": {
$assets
  }
}
''';
}

void main() {
  final skipReason = Platform.isWindows
      ? 'The update feed gate needs a POSIX shell.'
      : (_hasJq ? false : 'The update feed gate needs jq on PATH.');

  late Directory sandbox;

  setUp(() {
    sandbox = Directory.systemTemp.createTempSync('update_feeds_test');
  });

  tearDown(() {
    if (sandbox.existsSync()) {
      sandbox.deleteSync(recursive: true);
    }
  });

  ProcessResult verify(String manifest, String appcast) {
    final manifestFile = File(p.join(sandbox.path, 'latest.json'))
      ..writeAsStringSync(manifest);
    final appcastFile = File(p.join(sandbox.path, 'appcast.xml'))
      ..writeAsStringSync(appcast);

    return Process.runSync('bash', [
      _scriptPath,
      manifestFile.path,
      appcastFile.path,
    ], workingDirectory: Directory.current.path);
  }

  test(
    'accepts a feed whose manifest and appcast cover the same platforms',
    () {
      final result = verify(
        _manifest(['macos', 'windows', 'linux']),
        _appcast([
          _item(
            version: '0.10.3',
            build: 19,
            os: 'macos',
            signatureAttribute: 'sparkle:edSignature',
            signature: 'macsig19',
          ),
          _item(
            version: '0.10.3',
            build: 19,
            os: 'windows',
            signatureAttribute: 'sparkle:dsaSignature',
            signature: 'winsig19',
          ),
        ]),
      );

      expect(result.exitCode, 0, reason: result.stderr.toString());
    },
    skip: skipReason,
  );

  test('refuses a manifest that offers a platform the appcast drops', () {
    final result = verify(
      _manifest(['macos', 'windows']),
      _appcast([
        _item(
          version: '0.10.3',
          build: 19,
          os: 'windows',
          signatureAttribute: 'sparkle:dsaSignature',
          signature: 'winsig19',
        ),
      ]),
    );

    expect(result.exitCode, isNot(0));
    expect(result.stderr, contains('no macos item'));
  }, skip: skipReason);

  test('refuses an appcast item without a signature', () {
    final result = verify(
      _manifest(['macos', 'windows']),
      _appcast([
        _item(
          version: '0.10.3',
          build: 19,
          os: 'macos',
          signatureAttribute: 'sparkle:edSignature',
          signature: 'macsig19',
        ),
        _item(version: '0.10.3', build: 19, os: 'windows'),
      ]),
    );

    expect(result.exitCode, isNot(0));
    expect(result.stderr, contains('unsigned'));
  }, skip: skipReason);

  test('refuses an appcast item the manifest does not offer', () {
    final result = verify(
      _manifest(['macos']),
      _appcast([
        _item(
          version: '0.10.3',
          build: 19,
          os: 'macos',
          signatureAttribute: 'sparkle:edSignature',
          signature: 'macsig19',
        ),
        _item(
          version: '0.10.3',
          build: 19,
          os: 'windows',
          signatureAttribute: 'sparkle:dsaSignature',
          signature: 'winsig19',
        ),
      ]),
    );

    expect(result.exitCode, isNot(0));
    expect(result.stderr, contains('no windows asset'));
  }, skip: skipReason);

  test('accepts a publish that ships no Sparkle platform', () {
    final result = verify(_manifest(['linux']), _appcast([]));

    expect(result.exitCode, 0, reason: result.stderr.toString());
  }, skip: skipReason);

  test('refuses a manifest without an assets map', () {
    final result = verify('{"version": "0.10.3"}', _appcast([]));

    expect(result.exitCode, isNot(0));
    expect(result.stderr, contains('assets'));
  }, skip: skipReason);
}

bool get _hasJq {
  final result = Process.runSync('jq', ['--version']);
  return result.exitCode == 0;
}
