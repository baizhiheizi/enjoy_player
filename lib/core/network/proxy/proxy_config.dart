import 'proxy_parsers.dart';
import 'resolved_proxy.dart';

enum ProxyMode {
  system,
  manual,
  direct;

  static ProxyMode parse(String? raw) {
    for (final mode in values) {
      if (mode.name == raw) return mode;
    }
    return ProxyMode.system;
  }
}

final class ProxyConfig {
  const ProxyConfig({this.mode = ProxyMode.system, this.url = ''});

  final ProxyMode mode;
  final String url;

  @override
  bool operator ==(Object other) =>
      other is ProxyConfig && other.mode == mode && other.url == url;

  @override
  int get hashCode => Object.hash(mode, url);
}

ProxyEndpoint? parseManualProxyUrl(String input) => parseHostPort(input);

ResolvedProxy resolveConfiguredProxy(ProxyConfig config) {
  switch (config.mode) {
    case ProxyMode.direct:
      return const ResolvedProxy(source: 'direct');
    case ProxyMode.manual:
      final endpoint = parseManualProxyUrl(config.url);
      if (endpoint == null) return const ResolvedProxy(source: 'manual');
      return ResolvedProxy(http: endpoint, https: endpoint, source: 'manual');
    case ProxyMode.system:
      return ResolvedProxy.none;
  }
}
