/// Redacts sensitive substrings before persisting log lines to disk.
library;

import 'package:path/path.dart' as p;

final RegExp _authorizationHeader = RegExp(
  r'Authorization:\s*Bearer\s+\S+',
  caseSensitive: false,
);

final RegExp _bearerToken = RegExp(
  r'Bearer\s+[A-Za-z0-9\-._~+/]+=*',
  caseSensitive: false,
);

final RegExp _cookiePair = RegExp(
  r'(LOGIN_INFO|SID|SAPISID|HSID|SSID|APISID|__Secure-[A-Za-z0-9_-]+)=[^;\s]+',
);

final RegExp _windowsAbsPath = RegExp(
  r'[A-Za-z]:\\(?:[^\\:*?"<>|\r\n]+\\)*[^\\:*?"<>|\r\n]+',
);

final RegExp _posixAbsPath = RegExp(
  r'/(?:Users|home|tmp|var|opt)/(?:[^:;,"]+/)*[^:;,"]+',
);

/// Returns [line] with tokens, cookies, and long absolute paths redacted.
String redactLogLine(String line) {
  var out = line;
  out = out.replaceAll(_bearerToken, 'Bearer [REDACTED]');
  out = out.replaceAll(_authorizationHeader, 'Authorization: [REDACTED]');
  out = out.replaceAllMapped(_cookiePair, (m) => '${m.group(1)}=[REDACTED]');
  out = _redactAbsolutePaths(out);
  return out;
}

String _redactAbsolutePaths(String line) {
  String shorten(String path) {
    if (path.length <= 48) return path;
    // `p.basename` splits on the host platform's separator, so on Linux/macOS
    // it leaves Windows back-slash paths untouched. Normalize to `/` first so
    // the basename is correct regardless of the host platform.
    final normalized = path.replaceAll(r'\', '/');
    return '.../${p.basename(normalized)}';
  }

  return line
      .replaceAllMapped(_windowsAbsPath, (m) => shorten(m[0]!))
      .replaceAllMapped(_posixAbsPath, (m) => shorten(m[0]!));
}
