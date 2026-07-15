import 'dart:convert';

import 'package:enjoy_player/features/transcript/data/client_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ClientProfile', () {
    test('fromJson parses a valid profile', () {
      final json = {
        'name': 'ios',
        'clientName': 'IOS',
        'clientVersion': '20.10.4',
        'clientNameHeader': '5',
        'userAgent': 'com.google.ios.youtube/20.10.4',
        'context': {
          'deviceMake': 'Apple',
          'deviceModel': 'iPhone16,2',
          'platform': 'MOBILE',
          'osName': 'iOS',
          'osVersion': '18.3.2.22D82',
        },
      };
      final profile = ClientProfile.fromJson(json);
      expect(profile.name, 'ios');
      expect(profile.clientName, 'IOS');
      expect(profile.clientVersion, '20.10.4');
      expect(profile.clientNameHeader, '5');
      expect(profile.userAgent, 'com.google.ios.youtube/20.10.4');
      expect(profile.context['deviceMake'], 'Apple');
      expect(profile.context['platform'], 'MOBILE');
      expect(profile.isValid, isTrue);
    });

    test('fromJson accepts worker wire shape after camelCase conversion', () {
      // Matches GET /youtube/client-profiles after ApiClient snake→camel.
      final json = {
        'name': 'IOS',
        'version': '20.12.1',
        'clientNameHeader': '5',
        'userAgent':
            'com.google.ios.youtube/20.12.1 (iPhone17,1; U; CPU iOS 18_5 like Mac OS X;)',
        'context': {
          'deviceMake': 'Apple',
          'deviceModel': 'iPhone17,1',
          'platform': 'MOBILE',
          'osName': 'iOS',
          'osVersion': '18.5.22F5053c',
        },
      };
      final profile = ClientProfile.fromJson(json);
      expect(profile.name, 'ios');
      expect(profile.clientName, 'IOS');
      expect(profile.clientVersion, '20.12.1');
      expect(profile.clientNameHeader, '5');
      expect(profile.userAgent, contains('20.12.1'));
      expect(profile.context['deviceMake'], 'Apple');
      expect(profile.isValid, isTrue);
    });

    test('fromJson tolerates nested Map<dynamic, dynamic> context', () {
      // jsonDecode + key conversion yields Map<dynamic, dynamic> nests.
      final decoded = jsonDecode(
        '{"name":"WEB","version":"2.20250709.00.00",'
        '"clientNameHeader":"1","userAgent":"ua",'
        '"context":{"platform":"DESKTOP"}}',
      );
      expect(decoded, isA<Map>());
      final profile = ClientProfile.fromJson(
        Map<String, dynamic>.from(decoded as Map),
      );
      expect(profile.name, 'web');
      expect(profile.clientName, 'WEB');
      expect(profile.clientVersion, '2.20250709.00.00');
      expect(profile.context['platform'], 'DESKTOP');
      expect(profile.isValid, isTrue);
    });

    test('fromJson handles missing fields', () {
      final profile = ClientProfile.fromJson({});
      expect(profile.name, '');
      expect(profile.clientName, '');
      expect(profile.isValid, isFalse);
    });

    test('fromJson handles null context', () {
      final json = {
        'name': 'ios',
        'clientName': 'IOS',
        'clientVersion': '20.10.4',
        'clientNameHeader': '5',
        'userAgent': 'com.google.ios.youtube/20.10.4',
      };
      final profile = ClientProfile.fromJson(json);
      expect(profile.context, isEmpty);
      expect(profile.isValid, isTrue);
    });

    test('toJson round-trips', () {
      final original = kBuiltInClientProfiles.first;
      final json = original.toJson();
      final restored = ClientProfile.fromJson(json);
      expect(restored.name, original.name);
      expect(restored.clientName, original.clientName);
      expect(restored.clientVersion, original.clientVersion);
      expect(restored.userAgent, original.userAgent);
      expect(restored.isValid, isTrue);
    });

    test('isValid returns false when name is empty', () {
      const profile = ClientProfile(
        name: '',
        clientName: 'IOS',
        clientVersion: '1.0',
        clientNameHeader: '5',
        userAgent: 'agent',
        context: {},
      );
      expect(profile.isValid, isFalse);
    });

    test('isValid returns false when clientName is empty', () {
      const profile = ClientProfile(
        name: 'ios',
        clientName: '',
        clientVersion: '1.0',
        clientNameHeader: '5',
        userAgent: 'agent',
        context: {},
      );
      expect(profile.isValid, isFalse);
    });

    test('isValid returns false when userAgent is empty', () {
      const profile = ClientProfile(
        name: 'ios',
        clientName: 'IOS',
        clientVersion: '1.0',
        clientNameHeader: '5',
        userAgent: '',
        context: {},
      );
      expect(profile.isValid, isFalse);
    });
  });

  group('clientProfilesFromJson', () {
    test('parses a list of profiles', () {
      final json = [
        {
          'name': 'ios',
          'clientName': 'IOS',
          'clientVersion': '20.10.4',
          'clientNameHeader': '5',
          'userAgent': 'ua1',
          'context': <String, String>{},
        },
        {
          'name': 'android_vr',
          'clientName': 'ANDROID_VR',
          'clientVersion': '1.62.20',
          'clientNameHeader': '28',
          'userAgent': 'ua2',
          'context': <String, String>{},
        },
      ];
      final profiles = clientProfilesFromJson(json);
      expect(profiles.length, 2);
      expect(profiles[0].name, 'ios');
      expect(profiles[1].name, 'android_vr');
    });

    test('parses worker wire list with dynamic nested maps', () {
      final decoded = jsonDecode('''
[
  {
    "name": "IOS",
    "version": "20.12.1",
    "clientNameHeader": "5",
    "userAgent": "ua-ios",
    "context": {"deviceMake": "Apple", "platform": "MOBILE"}
  },
  {
    "name": "WEB",
    "version": "2.20250709.00.00",
    "clientNameHeader": "1",
    "userAgent": "ua-web",
    "context": {}
  }
]
''');
      final profiles = clientProfilesFromJson(decoded);
      expect(profiles, hasLength(2));
      expect(profiles[0].name, 'ios');
      expect(profiles[0].clientName, 'IOS');
      expect(profiles[0].clientVersion, '20.12.1');
      expect(profiles[0].context['deviceMake'], 'Apple');
      expect(profiles[1].name, 'web');
      expect(profiles[1].clientName, 'WEB');
    });

    test('filters out invalid profiles', () {
      final json = [
        {
          'name': 'ios',
          'clientName': 'IOS',
          'clientVersion': '20.10.4',
          'clientNameHeader': '5',
          'userAgent': 'ua',
          'context': <String, String>{},
        },
        {
          'name': '',
          'clientName': '',
          'clientVersion': '',
          'clientNameHeader': '',
          'userAgent': '',
          'context': <String, String>{},
        },
      ];
      final profiles = clientProfilesFromJson(json);
      expect(profiles.length, 1);
      expect(profiles[0].name, 'ios');
    });

    test('returns empty list for non-list input', () {
      expect(clientProfilesFromJson(null), isEmpty);
      expect(clientProfilesFromJson('string'), isEmpty);
      expect(clientProfilesFromJson({}), isEmpty);
    });
  });

  group('kBuiltInClientProfiles', () {
    test('contains at least 3 profiles', () {
      expect(kBuiltInClientProfiles.length, greaterThanOrEqualTo(3));
    });

    test('all built-in profiles are valid', () {
      for (final profile in kBuiltInClientProfiles) {
        expect(profile.isValid, isTrue, reason: '${profile.name} is invalid');
      }
    });

    test('profiles are in correct fallback order', () {
      expect(kBuiltInClientProfiles.map((p) => p.name).toList(), [
        'ios',
        'android_vr',
        'mweb',
        'web',
      ]);
      expect(kBuiltInClientProfiles[0].clientVersion, '20.12.1');
      expect(kBuiltInClientProfiles[3].clientVersion, '2.20250709.00.00');
    });
  });

  group('resolveCaptionClientProfiles', () {
    test('empty remote returns built-ins in preferred order', () {
      final resolved = resolveCaptionClientProfiles(const []);
      expect(resolved.map((p) => p.clientKey).toList(), [
        'IOS',
        'ANDROID_VR',
        'MWEB',
        'WEB',
      ]);
    });

    test('worker IOS+WEB keeps ANDROID_VR and MWEB gap-fill', () {
      final remote = clientProfilesFromJson([
        {
          'name': 'IOS',
          'version': '20.99.0',
          'clientNameHeader': '5',
          'userAgent': 'com.google.ios.youtube/20.99.0',
          'context': {'platform': 'MOBILE'},
        },
        {
          'name': 'WEB',
          'version': '2.20259999.00.00',
          'clientNameHeader': '1',
          'userAgent': 'Mozilla/5.0',
          'context': {'platform': 'DESKTOP'},
        },
      ]);
      final resolved = resolveCaptionClientProfiles(remote);
      expect(resolved.map((p) => p.clientKey).toList(), [
        'IOS',
        'ANDROID_VR',
        'MWEB',
        'WEB',
      ]);
      expect(resolved[0].clientVersion, '20.99.0');
      expect(resolved[3].clientVersion, '2.20259999.00.00');
      expect(resolved[1].name, 'android_vr');
      expect(resolved[2].name, 'mweb');
    });

    test('remote ANDROID slots between ANDROID_VR and MWEB', () {
      const android = ClientProfile(
        name: 'android',
        clientName: 'ANDROID',
        clientVersion: '21.02.35',
        clientNameHeader: '3',
        userAgent: 'com.google.android.youtube/21.02.35',
        context: {'platform': 'MOBILE', 'osName': 'Android'},
      );
      final resolved = resolveCaptionClientProfiles([android]);
      expect(resolved.map((p) => p.clientKey).toList(), [
        'IOS',
        'ANDROID_VR',
        'ANDROID',
        'MWEB',
        'WEB',
      ]);
    });

    test('unknown remote clients append after preferred ladder', () {
      const tv = ClientProfile(
        name: 'tv',
        clientName: 'TVHTML5',
        clientVersion: '7.20240101',
        clientNameHeader: '7',
        userAgent: 'Mozilla/5.0 (SMART-TV)',
        context: {},
      );
      final resolved = resolveCaptionClientProfiles([tv]);
      expect(resolved.last.clientKey, 'TVHTML5');
      expect(resolved.map((p) => p.clientKey).take(4).toList(), [
        'IOS',
        'ANDROID_VR',
        'MWEB',
        'WEB',
      ]);
    });
  });
}
