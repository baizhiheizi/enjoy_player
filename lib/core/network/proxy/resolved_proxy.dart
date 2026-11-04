import 'dart:io';

final class ProxyEndpoint {
  const ProxyEndpoint(this.host, this.port, [this.userInfo]);

  final String host;
  final int port;
  final String? userInfo;

  String toDirective() => userInfo != null && userInfo!.isNotEmpty
      ? '$userInfo@$host:$port'
      : '$host:$port';

  @override
  String toString() => '$host:$port';

  @override
  bool operator ==(Object other) =>
      other is ProxyEndpoint &&
      other.host == host &&
      other.port == port &&
      other.userInfo == userInfo;

  @override
  int get hashCode => Object.hash(host, port, userInfo);
}

final class ResolvedProxy {
  const ResolvedProxy({
    this.http,
    this.https,
    this.bypass = const [],
    this.source = 'none',
  });

  static const ResolvedProxy none = ResolvedProxy();

  final ProxyEndpoint? http;
  final ProxyEndpoint? https;
  final List<String> bypass;
  final String source;

  bool get isEmpty => http == null && https == null;

  String findProxy(Uri uri) {
    final host = uri.host;
    if (host.isEmpty || isLoopbackHost(host) || bypassesHost(host)) {
      return 'DIRECT';
    }
    final endpoint = uri.scheme == 'https' ? (https ?? http) : (http ?? https);
    return endpoint == null ? 'DIRECT' : 'PROXY ${endpoint.toDirective()}';
  }

  bool bypassesHost(String host) {
    final h = host.toLowerCase();
    for (final raw in bypass) {
      final rule = raw.trim().toLowerCase();
      if (rule.isEmpty) continue;
      if (rule == '<local>') {
        if (!h.contains('.') && !h.contains(':')) return true;
        continue;
      }
      if (rule.startsWith('*.')) {
        final suffix = rule.substring(1);
        if (h.endsWith(suffix) || h == rule.substring(2)) return true;
      } else if (rule.startsWith('.')) {
        if (h.endsWith(rule) || h == rule.substring(1)) return true;
      } else if (rule.endsWith('*')) {
        if (h.startsWith(rule.substring(0, rule.length - 1))) return true;
      } else if (h == rule) {
        return true;
      }
    }
    return false;
  }

  String describe() {
    if (isEmpty) return 'direct source=$source';
    final parts = <String>[
      if (http != null) 'http=$http',
      if (https != null) 'https=$https',
    ];
    return 'proxy source=$source ${parts.join(' ')}';
  }

  @override
  bool operator ==(Object other) =>
      other is ResolvedProxy &&
      other.http == http &&
      other.https == https &&
      other.source == source &&
      _listEquals(other.bypass, bypass);

  @override
  int get hashCode => Object.hash(http, https, source, Object.hashAll(bypass));
}

bool isLoopbackHost(String host) {
  if (host.toLowerCase() == 'localhost') return true;
  final address = InternetAddress.tryParse(host);
  return address != null && address.isLoopback;
}

bool _listEquals(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
