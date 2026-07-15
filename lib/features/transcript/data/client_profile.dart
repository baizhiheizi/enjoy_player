/// YouTube InnerTube client profile configuration.
///
/// Each profile spoofs a different YouTube client (IOS, Android VR, Mobile Web,
/// WEB) for anti-bot mitigation. Profiles are **not** tied to the Flutter host
/// OS — the same ladder runs on Android, iOS, and desktop.
///
/// Live versions come from the worker's `GET /youtube/client-profiles`
/// endpoint and are merged with [kBuiltInClientProfiles] via
/// [resolveCaptionClientProfiles]. Built-ins are the cold-start fallback and
/// fill gaps when the worker publishes a subset (today often only IOS + WEB).
library;

import 'package:enjoy_player/core/json/json_cast.dart';

/// A single client profile for spoofing a YouTube client.
class ClientProfile {
  const ClientProfile({
    required this.name,
    required this.clientName,
    required this.clientVersion,
    required this.clientNameHeader,
    required this.userAgent,
    required this.context,
  });

  /// Parses either the local camelCase shape (`clientName` / `clientVersion`)
  /// or the worker wire shape after [convertKeysToCamel]
  /// (`name` + `version`, where `name` is the InnerTube client name like
  /// `"IOS"`).
  factory ClientProfile.fromJson(Map<String, dynamic> json) {
    final rawName = json['name'] as String? ?? '';
    final hasLocalClientName = json['clientName'] is String;
    final clientName = json['clientName'] as String? ?? rawName;
    // Local caches store a lowercase slug in `name` plus `clientName`.
    // The worker publishes `name` as the InnerTube client name only.
    final name = hasLocalClientName ? rawName : rawName.toLowerCase();
    return ClientProfile(
      name: name,
      clientName: clientName,
      clientVersion:
          json['clientVersion'] as String? ?? json['version'] as String? ?? '',
      clientNameHeader: json['clientNameHeader'] as String? ?? '',
      userAgent: json['userAgent'] as String? ?? '',
      context: _contextFromJson(json['context']),
    );
  }

  static Map<String, String> _contextFromJson(Object? value) {
    final map = castJsonObjectOrNull(value);
    if (map == null) return <String, String>{};
    return map.map((k, v) => MapEntry(k, v.toString()));
  }

  final String name;
  final String clientName;
  final String clientVersion;
  final String clientNameHeader;
  final String userAgent;
  final Map<String, String> context;

  Map<String, dynamic> toJson() => {
    'name': name,
    'clientName': clientName,
    'clientVersion': clientVersion,
    'clientNameHeader': clientNameHeader,
    'userAgent': userAgent,
    'context': context,
  };

  /// Validates that required fields are non-empty.
  bool get isValid =>
      name.isNotEmpty &&
      clientName.isNotEmpty &&
      clientVersion.isNotEmpty &&
      userAgent.isNotEmpty;

  /// Uppercased InnerTube `clientName` used as the merge key.
  String get clientKey => clientName.toUpperCase();
}

/// Preferred caption-fetch ladder. Order is deliberate for 2026 YouTube:
/// IOS (no PoToken for captions) → ANDROID_VR → optional ANDROID → MWEB → WEB.
///
/// Host OS must **not** reorder this list — profiles are spoofed identities.
const List<String> kPreferredCaptionClientOrder = [
  'IOS',
  'ANDROID_VR',
  'ANDROID',
  'MWEB',
  'WEB',
];

/// Decodes a list of profiles from a JSON array (worker response format).
List<ClientProfile> clientProfilesFromJson(dynamic json) {
  if (json is List) {
    return json
        .map(castJsonObjectOrNull)
        .whereType<Map<String, dynamic>>()
        .map(ClientProfile.fromJson)
        .where((p) => p.isValid)
        .toList();
  }
  return [];
}

/// Merges [remote] worker profiles with [builtIns] into the caption ladder.
///
/// - Remote entries win on the same [ClientProfile.clientKey] (fresher versions).
/// - Missing preferred clients are filled from [builtIns].
/// - Result is ordered by [kPreferredCaptionClientOrder], then any extras.
/// - Empty / all-invalid [remote] yields [builtIns] in preferred order.
List<ClientProfile> resolveCaptionClientProfiles(
  List<ClientProfile> remote, {
  List<ClientProfile> builtIns = kBuiltInClientProfiles,
}) {
  final byKey = <String, ClientProfile>{};
  for (final profile in builtIns) {
    if (profile.isValid) byKey[profile.clientKey] = profile;
  }
  for (final profile in remote) {
    if (profile.isValid) byKey[profile.clientKey] = profile;
  }
  if (byKey.isEmpty) return const [];

  final ordered = <ClientProfile>[];
  final seen = <String>{};
  for (final key in kPreferredCaptionClientOrder) {
    final profile = byKey[key];
    if (profile == null) continue;
    ordered.add(profile);
    seen.add(key);
  }
  for (final profile in [...remote, ...builtIns]) {
    if (!profile.isValid) continue;
    final key = profile.clientKey;
    if (seen.contains(key)) continue;
    ordered.add(byKey[key]!);
    seen.add(key);
  }
  return ordered;
}

/// Built-in compile-time defaults for cold start and gap-fill.
/// Used when the worker is unreachable and no cached profiles exist, and to
/// supply ANDROID_VR / MWEB when the worker still publishes only IOS + WEB.
const List<ClientProfile> kBuiltInClientProfiles = [
  ClientProfile(
    name: 'ios',
    clientName: 'IOS',
    clientVersion: '20.12.1',
    clientNameHeader: '5',
    userAgent:
        'com.google.ios.youtube/20.12.1 (iPhone17,1; U; CPU iOS 18_5 like Mac OS X;)',
    context: {
      'deviceMake': 'Apple',
      'deviceModel': 'iPhone17,1',
      'platform': 'MOBILE',
      'osName': 'iOS',
      'osVersion': '18.5.22F5053c',
    },
  ),
  ClientProfile(
    name: 'android_vr',
    clientName: 'ANDROID_VR',
    clientVersion: '1.62.20',
    clientNameHeader: '28',
    userAgent:
        'com.google.android.apps.youtube.vr.oculus/1.62.20 (Linux; U; Android 12L; eureka-user Build/SQ3A.220605.009.A1) gzip',
    context: {
      'deviceMake': 'Oculus',
      'deviceModel': 'Quest 3',
      'platform': 'MOBILE',
      'osName': 'Android',
      'osVersion': '12L',
      'androidSdkVersion': '32',
    },
  ),
  ClientProfile(
    name: 'mweb',
    clientName: 'MWEB',
    clientVersion: '2.20251209.01.00',
    clientNameHeader: '2',
    userAgent:
        'Mozilla/5.0 (iPhone; CPU iPhone OS 17_5_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1',
    context: {'platform': 'MOBILE', 'osName': 'iOS', 'osVersion': '17.5.1'},
  ),
  ClientProfile(
    // Desktop WEB — last-resort caption fallback (often needs PoToken).
    // Kept for Discover-era compatibility and rare cases where mobile
    // clients are throttled. Not preferred for captions in 2026.
    name: 'web',
    clientName: 'WEB',
    clientVersion: '2.20250709.00.00',
    clientNameHeader: '1',
    userAgent:
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
    context: {'platform': 'DESKTOP', 'osName': 'Windows', 'osVersion': '10.0'},
  ),
];
