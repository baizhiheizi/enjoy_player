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
      expect(kBuiltInClientProfiles[0].name, 'ios');
      expect(kBuiltInClientProfiles[1].name, 'android_vr');
      expect(kBuiltInClientProfiles[2].name, 'mweb');
    });
  });
}
