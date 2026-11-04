import 'dart:async';
import 'dart:io';

import 'package:enjoy_player/core/logging/log.dart';

import 'resolved_proxy.dart';
import 'system_proxy_resolver.dart';

typedef SystemProxyReader = Future<ResolvedProxy> Function();

final class SystemProxyCoordinator {
  SystemProxyCoordinator({
    SystemProxyReader? reader,
    this.refreshInterval = const Duration(seconds: 60),
  }) : _reader =
           reader ??
           (() =>
               resolveSystemProxy(operatingSystem: Platform.operatingSystem));

  final SystemProxyReader _reader;
  final Duration refreshInterval;
  Timer? _timer;
  ResolvedProxy _current = ResolvedProxy.none;
  bool _resolvedOnce = false;

  ResolvedProxy get current => _current;

  Future<void> start() async {
    await refresh();
    _timer?.cancel();
    _timer = Timer.periodic(refreshInterval, (_) => unawaited(refresh()));
  }

  Future<void> refresh() async {
    final next = await _reader();
    final changed = !_resolvedOnce || next != _current;
    _current = next;
    _resolvedOnce = true;
    if (changed) {
      logNamed('network.proxy').info('network proxy: ${next.describe()}');
    }
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }

  String findProxy(Uri uri) {
    final resolved = _current;
    if (resolved.isEmpty) return HttpClient.findProxyFromEnvironment(uri);
    return resolved.findProxy(uri);
  }
}

final class ProxyHttpOverrides extends HttpOverrides {
  ProxyHttpOverrides(this.coordinator);

  final SystemProxyCoordinator coordinator;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.findProxy = coordinator.findProxy;
    return client;
  }
}

Future<SystemProxyCoordinator> installSystemProxyOverrides() async {
  final coordinator = SystemProxyCoordinator();
  HttpOverrides.global = ProxyHttpOverrides(coordinator);
  await coordinator.start();
  return coordinator;
}
