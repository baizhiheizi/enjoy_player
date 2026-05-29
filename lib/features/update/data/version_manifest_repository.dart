/// Fetches and parses the remote `latest.json` update manifest.
library;

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:enjoy_player/core/application/app_links.dart';
import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/features/update/domain/update_types.dart';

final _log = logNamed('update.manifest');

class VersionManifestRepository {
  VersionManifestRepository({http.Client? client, String? manifestUrl})
      : _client = client ?? http.Client(),
        _manifestUrl = manifestUrl ?? kEnjoyPlayerLatestJsonUrl;

  final http.Client _client;
  final String _manifestUrl;

  Future<ReleaseManifest?> fetchLatest() async {
    try {
      final response = await _client
          .get(Uri.parse(_manifestUrl))
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) {
        _log.warning('manifest HTTP ${response.statusCode}');
        return null;
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;
      return _parseManifest(decoded);
    } catch (e, st) {
      _log.warning('manifest fetch failed', e, st);
      return null;
    }
  }

  ReleaseManifest? _parseManifest(Map<String, dynamic> json) {
    final version = json['version'] as String?;
    if (version == null || version.isEmpty) return null;
    final build = json['build'];
    final minSupported =
        (json['minSupportedVersion'] as String?) ?? version;
    final notes = (json['notes'] as String?) ?? '';
    final assetsRaw = json['assets'];
    if (assetsRaw is! Map<String, dynamic>) return null;

    final assets = <String, PlatformAsset>{};
    for (final entry in assetsRaw.entries) {
      final value = entry.value;
      if (value is! Map<String, dynamic>) continue;
      final url = value['url'] as String?;
      if (url == null || url.isEmpty) continue;
      assets[entry.key] = PlatformAsset(
        url: url,
        sha256: value['sha256'] as String?,
        file: value['file'] as String?,
      );
    }
    return ReleaseManifest(
      version: version,
      build: build is int ? build : int.tryParse('$build') ?? 0,
      minSupportedVersion: minSupported,
      notes: notes,
      assets: assets,
    );
  }
}
