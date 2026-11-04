import 'dart:io';

import 'package:enjoy_player/core/logging/log.dart';

import 'proxy_parsers.dart';
import 'resolved_proxy.dart';

typedef ProxyCommandRunner =
    Future<String?> Function(String executable, List<String> arguments);

Future<String?> runProxyCommand(
  String executable,
  List<String> arguments,
) async {
  final result = await Process.run(
    executable,
    arguments,
  ).timeout(const Duration(seconds: 5));
  if (result.exitCode != 0) return null;
  return result.stdout as String;
}

Future<ResolvedProxy> resolveSystemProxy({
  required String operatingSystem,
  ProxyCommandRunner run = runProxyCommand,
}) async {
  try {
    switch (operatingSystem) {
      case 'macos':
        final out = await run('/usr/sbin/scutil', const ['--proxy']);
        return out == null ? ResolvedProxy.none : parseScutilProxy(out);
      case 'windows':
        final out = await run('reg', const [
          'query',
          r'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings',
        ]);
        return out == null ? ResolvedProxy.none : parseWindowsProxy(out);
    }
  } on Object catch (e) {
    logNamed('network.proxy').warning('system proxy read failed: $e');
  }
  return ResolvedProxy.none;
}
