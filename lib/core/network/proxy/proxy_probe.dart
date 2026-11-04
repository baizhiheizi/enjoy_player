import 'dart:async';
import 'dart:io';

import 'proxy_http_overrides.dart';

final class ProxyProbeTarget {
  const ProxyProbeTarget({required this.label, required this.uri});

  final String label;
  final Uri uri;
}

final class ProxyProbeResult {
  const ProxyProbeResult({
    required this.label,
    required this.route,
    required this.reachable,
    required this.elapsed,
    this.statusCode,
    this.error,
  });

  final String label;
  final String route;
  final bool reachable;
  final Duration elapsed;
  final int? statusCode;
  final String? error;
}

Future<List<ProxyProbeResult>> probeConnectivity({
  required SystemProxyCoordinator coordinator,
  required List<ProxyProbeTarget> targets,
  HttpClient Function()? clientFactory,
  Duration timeout = const Duration(seconds: 8),
}) async {
  await coordinator.refresh();
  final results = <ProxyProbeResult>[];
  for (final target in targets) {
    results.add(
      await _probeOne(
        coordinator: coordinator,
        target: target,
        clientFactory: clientFactory ?? HttpClient.new,
        timeout: timeout,
      ),
    );
  }
  return results;
}

Future<ProxyProbeResult> _probeOne({
  required SystemProxyCoordinator coordinator,
  required ProxyProbeTarget target,
  required HttpClient Function() clientFactory,
  required Duration timeout,
}) async {
  final route = coordinator.findProxy(target.uri);
  final watch = Stopwatch()..start();
  final client = clientFactory();
  try {
    final request = await client.getUrl(target.uri).timeout(timeout);
    final response = await request.close().timeout(timeout);
    await response.drain<void>().timeout(timeout);
    return ProxyProbeResult(
      label: target.label,
      route: route,
      reachable: true,
      elapsed: watch.elapsed,
      statusCode: response.statusCode,
    );
  } on Object catch (e) {
    return ProxyProbeResult(
      label: target.label,
      route: route,
      reachable: false,
      elapsed: watch.elapsed,
      error: e.runtimeType.toString(),
    );
  } finally {
    client.close(force: true);
  }
}
