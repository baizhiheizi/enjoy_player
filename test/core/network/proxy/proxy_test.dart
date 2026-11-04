import 'package:enjoy_player/core/network/proxy/proxy_http_overrides.dart';
import 'package:enjoy_player/core/network/proxy/proxy_parsers.dart';
import 'package:enjoy_player/core/network/proxy/resolved_proxy.dart';
import 'package:enjoy_player/core/network/proxy/system_proxy_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

const _scutil = '''
<dictionary> {
  ExceptionsList : <array> {
    0 : *.local
    1 : 169.254/16
    2 : intranet.corp
  }
  HTTPEnable : 1
  HTTPPort : 7890
  HTTPProxy : 127.0.0.1
  HTTPSEnable : 1
  HTTPSPort : 7891
  HTTPSProxy : 10.0.0.2
  SOCKSEnable : 0
}
''';

void main() {
  group('parseScutilProxy', () {
    test('parses endpoints and exceptions', () {
      final p = parseScutilProxy(_scutil);
      expect(p.http, const ProxyEndpoint('127.0.0.1', 7890));
      expect(p.https, const ProxyEndpoint('10.0.0.2', 7891));
      expect(p.bypass, ['*.local', '169.254/16', 'intranet.corp']);
      expect(p.source, 'scutil');
    });

    test('returns none when disabled', () {
      expect(
        parseScutilProxy('<dictionary> {\n  HTTPEnable : 0\n}'),
        ResolvedProxy.none,
      );
    });
  });

  group('parseWindowsProxy', () {
    String reg(String enable, String server, [String override = '']) =>
        '''
HKEY_CURRENT_USER\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings
    ProxyEnable    REG_DWORD    $enable
    ProxyServer    REG_SZ    $server
    ProxyOverride    REG_SZ    $override
''';

    test('single endpoint form', () {
      final p = parseWindowsProxy(
        reg('0x1', '127.0.0.1:7890', 'localhost;<local>'),
      );
      expect(p.http, const ProxyEndpoint('127.0.0.1', 7890));
      expect(p.https, isNull);
      expect(p.bypass, ['localhost', '<local>']);
    });

    test('per-protocol form', () {
      final p = parseWindowsProxy(
        reg('0x1', 'http=1.1.1.1:80;https=2.2.2.2:443;socks=3.3.3.3:1080'),
      );
      expect(p.http, const ProxyEndpoint('1.1.1.1', 80));
      expect(p.https, const ProxyEndpoint('2.2.2.2', 443));
    });

    test('disabled', () {
      expect(
        parseWindowsProxy(reg('0x0', '127.0.0.1:7890')),
        ResolvedProxy.none,
      );
    });
  });

  group('parseHostPort', () {
    test('handles schemes, credentials and invalid input', () {
      final parsed = parseHostPort('http://user:pw@proxy.example:8080/');
      expect(parsed, const ProxyEndpoint('proxy.example', 8080, 'user:pw'));
      expect(parsed?.toDirective(), 'user:pw@proxy.example:8080');
      expect(parsed?.toString(), 'proxy.example:8080');
      expect(parseHostPort('socks5://127.0.0.1:1080'), isNull);
      expect(parseHostPort('nohost'), isNull);
      expect(parseHostPort('h:99999'), isNull);
    });
  });

  group('ResolvedProxy.findProxy', () {
    const proxy = ResolvedProxy(
      http: ProxyEndpoint('127.0.0.1', 7890),
      bypass: ['*.local', '.corp.example', 'intranet', '<local>'],
    );

    test('proxies public hosts', () {
      expect(
        proxy.findProxy(Uri.parse('https://youtubei.googleapis.com/x')),
        'PROXY 127.0.0.1:7890',
      );
    });

    test('proxies public hosts with credentials in directive', () {
      const authProxy = ResolvedProxy(
        http: ProxyEndpoint('127.0.0.1', 7890, 'user:pw'),
      );
      expect(
        authProxy.findProxy(Uri.parse('https://youtubei.googleapis.com/x')),
        'PROXY user:pw@127.0.0.1:7890',
      );
    });

    test('bypasses loopback and listed hosts', () {
      for (final url in [
        'http://localhost:3000',
        'http://127.0.0.1',
        'http://[::1]:80',
        'https://printer.local',
        'https://a.corp.example',
        'https://corp.example',
        'http://intranet',
        'http://singlelabel',
      ]) {
        expect(proxy.findProxy(Uri.parse(url)), 'DIRECT', reason: url);
      }
    });

    test('empty proxy is direct', () {
      expect(
        ResolvedProxy.none.findProxy(Uri.parse('https://a.com')),
        'DIRECT',
      );
    });
  });

  group('resolveSystemProxy', () {
    test('uses scutil on macOS', () async {
      final p = await resolveSystemProxy(
        operatingSystem: 'macos',
        run: (exe, args) async => _scutil,
      );
      expect(p.http?.port, 7890);
    });

    test('command failure and unsupported OS resolve to none', () async {
      expect(
        await resolveSystemProxy(
          operatingSystem: 'windows',
          run: (exe, args) async => throw StateError('boom'),
        ),
        ResolvedProxy.none,
      );
      expect(
        await resolveSystemProxy(operatingSystem: 'android'),
        ResolvedProxy.none,
      );
    });
  });

  group('SystemProxyCoordinator', () {
    test('refresh publishes the resolved proxy to findProxy', () async {
      final c = SystemProxyCoordinator(
        reader: () async => parseScutilProxy(_scutil),
      );
      await c.refresh();
      expect(
        c.findProxy(Uri.parse('https://youtubei.googleapis.com')),
        'PROXY 10.0.0.2:7891',
      );
      expect(c.findProxy(Uri.parse('http://localhost')), 'DIRECT');
    });
  });
}
