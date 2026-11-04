import 'dart:async';
import 'dart:io';

import 'package:enjoy_player/core/network/proxy/proxy_config.dart';
import 'package:enjoy_player/core/network/proxy/proxy_http_overrides.dart';
import 'package:enjoy_player/core/network/proxy/proxy_probe.dart';
import 'package:enjoy_player/core/network/proxy/resolved_proxy.dart';
import 'package:flutter_test/flutter_test.dart';

const _systemProxy = ResolvedProxy(
  http: ProxyEndpoint('127.0.0.1', 7890),
  source: 'scutil',
);

void main() {
  final public = Uri.parse('https://youtubei.googleapis.com/x');

  group('ProxyMode precedence', () {
    test('parse falls back to system', () {
      expect(ProxyMode.parse('manual'), ProxyMode.manual);
      expect(ProxyMode.parse('direct'), ProxyMode.direct);
      expect(ProxyMode.parse('garbage'), ProxyMode.system);
      expect(ProxyMode.parse(null), ProxyMode.system);
    });

    test('manual wins over the system proxy', () async {
      final c = SystemProxyCoordinator(reader: () async => _systemProxy);
      await c.applyConfig(
        const ProxyConfig(mode: ProxyMode.manual, url: 'http://10.0.0.9:8080'),
      );
      expect(c.findProxy(public), 'PROXY 10.0.0.9:8080');
      expect(c.findProxy(Uri.parse('http://localhost:1')), 'DIRECT');
    });

    test('direct ignores the system proxy', () async {
      final c = SystemProxyCoordinator(reader: () async => _systemProxy);
      await c.applyConfig(const ProxyConfig(mode: ProxyMode.direct));
      expect(c.findProxy(public), 'DIRECT');
    });

    test('system mode uses the reader', () async {
      final c = SystemProxyCoordinator(reader: () async => _systemProxy);
      await c.applyConfig(const ProxyConfig());
      expect(c.findProxy(public), 'PROXY 127.0.0.1:7890');
    });

    test('manual with an invalid address is direct', () async {
      final c = SystemProxyCoordinator(reader: () async => _systemProxy);
      await c.applyConfig(
        const ProxyConfig(mode: ProxyMode.manual, url: 'socks5://h:1'),
      );
      expect(c.findProxy(public), 'DIRECT');
    });

    test('resolved notifies on config change', () async {
      final c = SystemProxyCoordinator(reader: () async => _systemProxy);
      await c.applyConfig(const ProxyConfig());
      var notified = 0;
      c.resolved.addListener(() => notified++);
      await c.applyConfig(const ProxyConfig(mode: ProxyMode.direct));
      expect(notified, 1);
      expect(c.current.source, 'direct');
    });
  });

  group('transportFailureHint', () {
    test('names the mode', () async {
      final c = SystemProxyCoordinator(reader: () async => _systemProxy);
      await c.applyConfig(const ProxyConfig());
      expect(c.transportFailureHint(), contains('127.0.0.1:7890'));
      expect(c.transportFailureHint(), contains('Manual'));
      await c.applyConfig(
        const ProxyConfig(mode: ProxyMode.manual, url: '1.2.3.4:80'),
      );
      expect(c.transportFailureHint(), contains('manual proxy'));
      await c.applyConfig(const ProxyConfig(mode: ProxyMode.direct));
      expect(c.transportFailureHint(), isNull);
    });

    test('system mode without a detected proxy suggests TUN', () async {
      final c = SystemProxyCoordinator(reader: () async => ResolvedProxy.none);
      await c.applyConfig(const ProxyConfig());
      expect(c.transportFailureHint(), contains('TUN'));
    });
  });

  group('probeConnectivity', () {
    test('reports reachable and unreachable targets', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((req) {
        req.response.statusCode = 204;
        unawaited(req.response.close());
      });
      final dead = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final deadPort = dead.port;
      await dead.close(force: true);
      addTearDown(() async {
        await server.close(force: true);
      });

      final c = SystemProxyCoordinator(reader: () async => ResolvedProxy.none);
      await c.applyConfig(const ProxyConfig(mode: ProxyMode.direct));
      final results = await probeConnectivity(
        coordinator: c,
        clientFactory: () => HttpClient()..findProxy = c.findProxy,
        targets: [
          ProxyProbeTarget(
            label: 'ok',
            uri: Uri.parse('http://127.0.0.1:${server.port}/'),
          ),
          ProxyProbeTarget(
            label: 'dead',
            uri: Uri.parse('http://127.0.0.1:$deadPort/'),
          ),
        ],
      );
      expect(results[0].reachable, isTrue);
      expect(results[0].statusCode, 204);
      expect(results[0].route, 'DIRECT');
      expect(results[1].reachable, isFalse);
      expect(results[1].error, isNotNull);
    });
  });
}
