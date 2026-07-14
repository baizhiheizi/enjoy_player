/// YouTube InnerTube client profile configuration.
///
/// Each profile spoofs a different YouTube client (IOS, Android VR, Mobile Web)
/// to avoid rate limiting and bot detection. Profiles are fetched from the
/// worker's `GET /youtube/client-profiles` endpoint and cached locally, with
/// built-in compile-time defaults as a cold-start fallback.
library;

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

  factory ClientProfile.fromJson(Map<String, dynamic> json) {
    return ClientProfile(
      name: json['name'] as String? ?? '',
      clientName: json['clientName'] as String? ?? '',
      clientVersion: json['clientVersion'] as String? ?? '',
      clientNameHeader: json['clientNameHeader'] as String? ?? '',
      userAgent: json['userAgent'] as String? ?? '',
      context:
          (json['context'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v.toString()),
          ) ??
          <String, String>{},
    );
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
}

/// Decodes a list of profiles from a JSON array (worker response format).
List<ClientProfile> clientProfilesFromJson(dynamic json) {
  if (json is List) {
    return json
        .whereType<Map<String, dynamic>>()
        .map(ClientProfile.fromJson)
        .where((p) => p.isValid)
        .toList();
  }
  return [];
}

/// Built-in compile-time defaults matching youtube-caption-extractor v1.10.2.
/// Used when the worker is unreachable and no cached profiles exist.
const List<ClientProfile> kBuiltInClientProfiles = [
  ClientProfile(
    name: 'ios',
    clientName: 'IOS',
    clientVersion: '20.10.4',
    clientNameHeader: '5',
    userAgent:
        'com.google.ios.youtube/20.10.4 (iPhone16,2; U; CPU iOS 18_3_2 like Mac OS X;)',
    context: {
      'deviceMake': 'Apple',
      'deviceModel': 'iPhone16,2',
      'platform': 'MOBILE',
      'osName': 'iOS',
      'osVersion': '18.3.2.22D82',
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
    // Desktop WEB profile — primary client for the InnerTube `browse` endpoint
    // used by Discover channel refresh (ADR-0047). Picked first by
    // `YoutubeBrowseClient`'s `preferredProfileOrder`. `IOS` is also used as a
    // browse fallback on Android where desktop profiles sometimes return empty
    // renderer lists (the `ios` profile succeeds on the same
    // `youtubei.googleapis.com` host for `browse` too — ADR-0049).
    // `ANDROID_VR` remains in this list because the YouTube caption fetcher
    // (`/player`) rotates through it; it is not used for `browse`.
    name: 'web',
    clientName: 'WEB',
    clientVersion: '2.20240101.00.00',
    clientNameHeader: '1',
    userAgent:
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
    context: {'platform': 'DESKTOP', 'osName': 'Windows', 'osVersion': '10.0'},
  ),
];
