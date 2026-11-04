import 'resolved_proxy.dart';

ResolvedProxy parseScutilProxy(String output) {
  final values = <String, String>{};
  final exceptions = <String>[];
  var inExceptions = false;
  for (final line in output.split(RegExp(r'\r?\n'))) {
    final trimmed = line.trim();
    if (trimmed.startsWith('ExceptionsList')) {
      inExceptions = true;
      continue;
    }
    if (inExceptions) {
      if (trimmed.startsWith('}')) {
        inExceptions = false;
        continue;
      }
      final m = RegExp(r'^\d+\s*:\s*(.+)$').firstMatch(trimmed);
      if (m != null) exceptions.add(m.group(1)!.trim());
      continue;
    }
    final m = RegExp(r'^(\w+)\s*:\s*(.+)$').firstMatch(trimmed);
    if (m != null) values[m.group(1)!] = m.group(2)!.trim();
  }
  ProxyEndpoint? endpoint(String prefix) {
    if (values['${prefix}Enable'] != '1') return null;
    final host = values['${prefix}Proxy'];
    final port = int.tryParse(values['${prefix}Port'] ?? '');
    if (host == null || host.isEmpty || port == null) return null;
    return ProxyEndpoint(host, port);
  }

  final http = endpoint('HTTP');
  final https = endpoint('HTTPS');
  if (http == null && https == null) return ResolvedProxy.none;
  return ResolvedProxy(
    http: http,
    https: https,
    bypass: exceptions,
    source: 'scutil',
  );
}

ResolvedProxy parseWindowsProxy(String output) {
  final values = <String, String>{};
  final pattern = RegExp(r'^\s*(\w+)\s+REG_\w+\s*(.*?)\s*$');
  for (final line in output.split(RegExp(r'\r?\n'))) {
    final m = pattern.firstMatch(line);
    if (m != null) values[m.group(1)!] = m.group(2)!;
  }
  final enabled = _parseRegDword(values['ProxyEnable']);
  final server = values['ProxyServer'];
  if (!enabled || server == null || server.isEmpty) return ResolvedProxy.none;

  ProxyEndpoint? http;
  ProxyEndpoint? https;
  if (server.contains('=')) {
    for (final entry in server.split(';')) {
      final idx = entry.indexOf('=');
      if (idx < 0) continue;
      final scheme = entry.substring(0, idx).trim().toLowerCase();
      final endpoint = parseHostPort(entry.substring(idx + 1));
      if (scheme == 'http') http = endpoint;
      if (scheme == 'https') https = endpoint;
    }
  } else {
    http = parseHostPort(server);
  }
  if (http == null && https == null) return ResolvedProxy.none;
  final bypass = (values['ProxyOverride'] ?? '')
      .split(';')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
  return ResolvedProxy(
    http: http,
    https: https,
    bypass: bypass,
    source: 'registry',
  );
}

ProxyEndpoint? parseHostPort(String raw) {
  var value = raw.trim();
  if (value.isEmpty) return null;
  final schemeMatch = RegExp(
    r'^([a-zA-Z][a-zA-Z0-9+.-]*)://',
  ).firstMatch(value);
  if (schemeMatch != null) {
    final scheme = schemeMatch.group(1)!.toLowerCase();
    if (scheme != 'http' && scheme != 'https') return null;
    value = value.substring(schemeMatch.end);
  }
  final slash = value.indexOf('/');
  if (slash >= 0) value = value.substring(0, slash);
  String? userInfo;
  final at = value.lastIndexOf('@');
  if (at >= 0) {
    userInfo = value.substring(0, at);
    value = value.substring(at + 1);
  }
  final colon = value.lastIndexOf(':');
  if (colon <= 0) return null;
  final host = value.substring(0, colon);
  final port = int.tryParse(value.substring(colon + 1));
  if (port == null || port <= 0 || port > 65535) return null;
  return ProxyEndpoint(host, port, userInfo);
}

bool _parseRegDword(String? raw) {
  if (raw == null) return false;
  final text = raw.toLowerCase();
  final value = text.startsWith('0x')
      ? int.tryParse(text.substring(2), radix: 16)
      : int.tryParse(text);
  return value != null && value != 0;
}
