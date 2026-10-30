import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

const _scriptPath = '.github/scripts/merge_appcast_xml.sh';

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
  required String signatureAttribute,
  required String signature,
}) {
  return '''
    <item>
      <title>Version $version</title>
      <pubDate>Tue, 21 Oct 2026 10:00:00 +0000</pubDate>
      <sparkle:version>$build</sparkle:version>
      <sparkle:shortVersionString>$version</sparkle:shortVersionString>
      <enclosure url="https://dl.enjoy.bot/player/$version/EnjoyPlayer-$version" sparkle:os="$os" type="application/octet-stream" length="10"
        $signatureAttribute="$signature"
      />
    </item>
''';
}

String _appcast(List<String> items) => '$_header${items.join()}$_footer';

void main() {
  final skipOnWindows = Platform.isWindows
      ? 'The appcast merge harness needs a POSIX shell.'
      : false;

  late Directory sandbox;

  setUp(() {
    sandbox = Directory.systemTemp.createTempSync('appcast_merge_test');
  });

  tearDown(() {
    if (sandbox.existsSync()) {
      sandbox.deleteSync(recursive: true);
    }
  });

  String merge(String newAppcast, String remoteAppcast, String version) {
    final newFile = File(p.join(sandbox.path, 'new.xml'))
      ..writeAsStringSync(newAppcast);
    final remoteFile = File(p.join(sandbox.path, 'remote.xml'))
      ..writeAsStringSync(remoteAppcast);
    final outFile = File(p.join(sandbox.path, 'merged.xml'));

    final result = Process.runSync('bash', [
      _scriptPath,
      newFile.path,
      remoteFile.path,
      outFile.path,
      version,
    ], workingDirectory: Directory.current.path);

    expect(result.exitCode, 0, reason: result.stderr.toString());
    return outFile.readAsStringSync();
  }

  test('keeps the other platform when a publish carries only one of them', () {
    final remote = _appcast([
      _item(
        version: '0.10.2',
        build: 18,
        os: 'macos',
        signatureAttribute: 'sparkle:edSignature',
        signature: 'macsig18',
      ),
      _item(
        version: '0.10.2',
        build: 18,
        os: 'windows',
        signatureAttribute: 'sparkle:dsaSignature',
        signature: 'winsig18',
      ),
    ]);
    final windowsOnly = _appcast([
      _item(
        version: '0.10.3',
        build: 19,
        os: 'windows',
        signatureAttribute: 'sparkle:dsaSignature',
        signature: 'winsig19',
      ),
    ]);

    final merged = merge(windowsOnly, remote, '0.10.3');

    expect(merged, contains('sparkle:os="macos"'));
    expect(merged, contains('sparkle:os="windows"'));
    expect(
      merged,
      contains(
        '<sparkle:shortVersionString>0.10.2</sparkle:shortVersionString>',
      ),
    );
    expect(
      merged,
      contains(
        '<sparkle:shortVersionString>0.10.3</sparkle:shortVersionString>',
      ),
    );
    expect(merged, contains('sparkle:edSignature="macsig18"'));
    expect(merged, contains('sparkle:dsaSignature="winsig19"'));
  }, skip: skipOnWindows);

  test('keeps the windows item when the publish carries only macOS', () {
    final remote = _appcast([
      _item(
        version: '0.10.2',
        build: 18,
        os: 'macos',
        signatureAttribute: 'sparkle:edSignature',
        signature: 'macsig18',
      ),
      _item(
        version: '0.10.2',
        build: 18,
        os: 'windows',
        signatureAttribute: 'sparkle:dsaSignature',
        signature: 'winsig18',
      ),
    ]);
    final macOsOnly = _appcast([
      _item(
        version: '0.10.3',
        build: 19,
        os: 'macos',
        signatureAttribute: 'sparkle:edSignature',
        signature: 'macsig19',
      ),
    ]);

    final merged = merge(macOsOnly, remote, '0.10.3');

    expect(merged, contains('sparkle:os="macos"'));
    expect(merged, contains('sparkle:os="windows"'));
    expect(merged, contains('sparkle:dsaSignature="winsig18"'));
    expect(merged, contains('sparkle:edSignature="macsig19"'));
  }, skip: skipOnWindows);

  test('the published version wins over the remote item of that platform', () {
    final remote = _appcast([
      _item(
        version: '0.10.2',
        build: 18,
        os: 'macos',
        signatureAttribute: 'sparkle:edSignature',
        signature: 'macsig18',
      ),
    ]);
    final newer = _appcast([
      _item(
        version: '0.10.3',
        build: 19,
        os: 'macos',
        signatureAttribute: 'sparkle:edSignature',
        signature: 'macsig19',
      ),
    ]);

    final merged = merge(newer, remote, '0.10.3');

    expect(merged, contains('sparkle:edSignature="macsig19"'));
    expect(merged, isNot(contains('macsig18')));
  }, skip: skipOnWindows);

  test('keeps the newest remote item when the feed holds several versions', () {
    final remote = _appcast([
      _item(
        version: '0.9.0',
        build: 9,
        os: 'macos',
        signatureAttribute: 'sparkle:edSignature',
        signature: 'macsig09',
      ),
      _item(
        version: '0.10.2',
        build: 18,
        os: 'macos',
        signatureAttribute: 'sparkle:edSignature',
        signature: 'macsig18',
      ),
    ]);
    final windowsOnly = _appcast([
      _item(
        version: '0.10.3',
        build: 19,
        os: 'windows',
        signatureAttribute: 'sparkle:dsaSignature',
        signature: 'winsig19',
      ),
    ]);

    final merged = merge(windowsOnly, remote, '0.10.3');

    expect(merged, contains('sparkle:edSignature="macsig18"'));
    expect(merged, isNot(contains('macsig09')));
  }, skip: skipOnWindows);

  test('a publish without a remote feed still emits only its own item', () {
    final macOsOnly = _appcast([
      _item(
        version: '0.10.3',
        build: 19,
        os: 'macos',
        signatureAttribute: 'sparkle:edSignature',
        signature: 'macsig19',
      ),
    ]);
    final merged = merge(macOsOnly, _appcast([]), '0.10.3');

    expect(merged, contains('sparkle:os="macos"'));
    expect(merged, isNot(contains('sparkle:os="windows"')));
  }, skip: skipOnWindows);
}
