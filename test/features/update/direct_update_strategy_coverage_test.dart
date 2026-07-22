import 'package:flutter_test/flutter_test.dart';
import 'package:ota_update/ota_update.dart';

import 'package:enjoy_player/features/update/application/direct_update_strategy.dart';
import 'package:enjoy_player/features/update/domain/update_types.dart';

void main() {
  group('DirectUpdateStrategy.mapOtaEvent additional statuses', () {
    test('maps INSTALLATION_DONE to completed', () {
      final progress = DirectUpdateStrategy.mapOtaEvent(
        OtaEvent(OtaStatus.INSTALLATION_DONE, null),
      );
      expect(progress?.phase, UpdateInstallPhase.completed);
    });

    test('maps ALREADY_RUNNING_ERROR', () {
      final progress = DirectUpdateStrategy.mapOtaEvent(
        OtaEvent(OtaStatus.ALREADY_RUNNING_ERROR, null),
      );
      expect(progress?.phase, UpdateInstallPhase.failed);
      expect(
        progress?.failureReason,
        UpdateInstallFailureReason.alreadyRunning,
      );
    });

    test('maps INSTALLATION_ERROR with detail', () {
      final progress = DirectUpdateStrategy.mapOtaEvent(
        OtaEvent(OtaStatus.INSTALLATION_ERROR, 'package corrupt'),
      );
      expect(progress?.phase, UpdateInstallPhase.failed);
      expect(progress?.failureReason, UpdateInstallFailureReason.installation);
      expect(progress?.failureDetail, 'package corrupt');
    });

    test('maps INTERNAL_ERROR with detail', () {
      final progress = DirectUpdateStrategy.mapOtaEvent(
        OtaEvent(OtaStatus.INTERNAL_ERROR, 'disk full'),
      );
      expect(progress?.phase, UpdateInstallPhase.failed);
      expect(progress?.failureReason, UpdateInstallFailureReason.internal);
      expect(progress?.failureDetail, 'disk full');
    });

    test('DOWNLOADING with null value defaults to 0', () {
      final progress = DirectUpdateStrategy.mapOtaEvent(
        OtaEvent(OtaStatus.DOWNLOADING, null),
      );
      expect(progress?.phase, UpdateInstallPhase.downloading);
      expect(progress?.percent, 0.0);
    });

    test('DOWNLOADING with empty string defaults to 0', () {
      final progress = DirectUpdateStrategy.mapOtaEvent(
        OtaEvent(OtaStatus.DOWNLOADING, ''),
      );
      expect(progress?.percent, 0.0);
    });

    test('DOWNLOADING with non-numeric string defaults to 0', () {
      final progress = DirectUpdateStrategy.mapOtaEvent(
        OtaEvent(OtaStatus.DOWNLOADING, 'abc'),
      );
      expect(progress?.percent, 0.0);
    });

    test('DOWNLOADING with fractional value <= 1 uses it directly', () {
      final progress = DirectUpdateStrategy.mapOtaEvent(
        OtaEvent(OtaStatus.DOWNLOADING, '0.75'),
      );
      expect(progress?.percent, closeTo(0.75, 0.001));
    });

    test('DOWNLOADING with value 1.0 uses it directly', () {
      final progress = DirectUpdateStrategy.mapOtaEvent(
        OtaEvent(OtaStatus.DOWNLOADING, '1.0'),
      );
      expect(progress?.percent, 1.0);
    });

    test('DOWNLOADING with value 100 maps to 1.0', () {
      final progress = DirectUpdateStrategy.mapOtaEvent(
        OtaEvent(OtaStatus.DOWNLOADING, '100'),
      );
      expect(progress?.percent, 1.0);
    });

    test('DOWNLOADING with negative value clamps to 0', () {
      final progress = DirectUpdateStrategy.mapOtaEvent(
        OtaEvent(OtaStatus.DOWNLOADING, '-5'),
      );
      expect(progress?.percent, 0.0);
    });
  });

  group('DirectUpdateStrategy.pickAndroidApkForTest additional ABIs', () {
    final manifest = ReleaseManifest(
      version: '2.0.0',
      build: 10,
      minSupportedVersion: '1.0.0',
      notes: '',
      assets: {
        'android_arm64_v8a': PlatformAsset(
          url: 'https://example.com/arm64.apk',
          sha256: 'a' * 64,
        ),
        'android_armeabi_v7a': PlatformAsset(
          url: 'https://example.com/v7a.apk',
          sha256: 'b' * 64,
        ),
        'android_x86_64': PlatformAsset(
          url: 'https://example.com/x64.apk',
          sha256: 'c' * 64,
        ),
      },
    );

    test('selects x86_64 asset for x86_64 abi', () {
      final asset = DirectUpdateStrategy.pickAndroidApkForTest(
        manifest,
        'x86_64',
      );
      expect(asset?.url, 'https://example.com/x64.apk');
    });

    test('selects x86_64 asset for x64 abi', () {
      final asset = DirectUpdateStrategy.pickAndroidApkForTest(manifest, 'x64');
      expect(asset?.url, 'https://example.com/x64.apk');
    });

    test('selects arm64 for aarch64 abi', () {
      final asset = DirectUpdateStrategy.pickAndroidApkForTest(
        manifest,
        'aarch64',
      );
      expect(asset?.url, 'https://example.com/arm64.apk');
    });

    test('selects v7a for armv7 abi', () {
      final asset = DirectUpdateStrategy.pickAndroidApkForTest(
        manifest,
        'armv7',
      );
      expect(asset?.url, 'https://example.com/v7a.apk');
    });

    test('returns null when no android assets exist', () {
      final noAndroid = ReleaseManifest(
        version: '2.0.0',
        build: 10,
        minSupportedVersion: '1.0.0',
        notes: '',
        assets: {
          'linux_x86_64': PlatformAsset(
            url: 'https://example.com/linux.tar.gz',
            sha256: 'd' * 64,
          ),
        },
      );
      final asset = DirectUpdateStrategy.pickAndroidApkForTest(
        noAndroid,
        'arm64-v8a',
      );
      expect(asset, isNull);
    });

    test('falls back to any android-prefixed key', () {
      final oddKeys = ReleaseManifest(
        version: '2.0.0',
        build: 10,
        minSupportedVersion: '1.0.0',
        notes: '',
        assets: {
          'android_custom_build': PlatformAsset(
            url: 'https://example.com/custom.apk',
            sha256: 'e' * 64,
          ),
        },
      );
      final asset = DirectUpdateStrategy.pickAndroidApkForTest(
        oddKeys,
        'arm64-v8a',
      );
      expect(asset?.url, 'https://example.com/custom.apk');
    });

    test('handles empty abi string', () {
      final asset = DirectUpdateStrategy.pickAndroidApkForTest(manifest, '');
      expect(asset?.url, 'https://example.com/arm64.apk');
    });

    test('handles abi with whitespace', () {
      final asset = DirectUpdateStrategy.pickAndroidApkForTest(
        manifest,
        '  arm64-v8a  ',
      );
      expect(asset?.url, 'https://example.com/arm64.apk');
    });
  });
}
