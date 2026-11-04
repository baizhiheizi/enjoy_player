import 'dart:async';
import 'dart:io';

import 'package:enjoy_player/core/logging/log.dart';
import 'package:flutter/foundation.dart';

import 'proxy_config.dart';
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
  final ValueNotifier<ResolvedProxy> _resolved = ValueNotifier(
    ResolvedProxy.none,
  );
  Timer? _timer;
  ProxyConfig _config = const ProxyConfig();
  bool _resolvedOnce = false;

  ValueListenable<ResolvedProxy> get resolved => _resolved;

  ResolvedProxy get current => _resolved.value;

  ProxyConfig get config => _config;

  Future<void> start() async {
    await refresh();
    _timer?.cancel();
    _timer = Timer.periodic(refreshInterval, (_) => unawaited(refresh()));
  }

  Future<void> applyConfig(ProxyConfig config) async {
    if (config == _config && _resolvedOnce) return;
    _config = config;
    await refresh();
  }

  Future<void> refresh() async {
    final config = _config;
    final next = config.mode == ProxyMode.system
        ? await _reader()
        : resolveConfiguredProxy(config);
    if (config != _config) return;
    final changed = !_resolvedOnce || next != _resolved.value;
    _resolved.value = next;
    _resolvedOnce = true;
    if (changed) {
      logNamed(
        'network.proxy',
      ).info('network proxy: mode=${config.mode.name} ${next.describe()}');
    }
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    _resolved.dispose();
  }

  String findProxy(Uri uri) {
    final resolved = _resolved.value;
    switch (_config.mode) {
      case ProxyMode.direct:
        return 'DIRECT';
      case ProxyMode.manual:
        return resolved.findProxy(uri);
      case ProxyMode.system:
        if (resolved.isEmpty) return HttpClient.findProxyFromEnvironment(uri);
        return resolved.findProxy(uri);
    }
  }

  String? transportFailureHint() {
    final resolved = _resolved.value;
    switch (_config.mode) {
      case ProxyMode.direct:
        return null;
      case ProxyMode.manual:
        return 'requests are failing through your manual proxy '
            '(${resolved.http ?? 'invalid address'}) - check '
            'Settings > Network';
      case ProxyMode.system:
        final endpoint = resolved.http ?? resolved.https;
        if (endpoint == null) {
          return 'no system proxy was detected - if your VPN runs in '
              'system-proxy mode, enable TUN mode or set a manual proxy in '
              'Settings > Network';
        }
        return 'requests are bypassing or failing through your system proxy '
            '($endpoint) - check your VPN mode or switch Settings > Network '
            'to Manual';
    }
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

SystemProxyCoordinator installSystemProxyOverrides() {
  final coordinator = SystemProxyCoordinator();
  HttpOverrides.global = ProxyHttpOverrides(coordinator);
  unawaited(coordinator.start());
  return coordinator;
}
