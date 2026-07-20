import 'package:flutter_test/flutter_test.dart';
import 'package:ota_update/ota_update.dart';

import 'package:enjoy_player/features/update/application/direct_update_strategy.dart';
import 'package:enjoy_player/features/update/domain/update_types.dart';

void main() {
  group('DirectUpdateStrategy.mapOtaEvent', () {
    test('maps downloading percent 0-100 to 0-1', () {
      final progress = DirectUpdateStrategy.mapOtaEvent(
        OtaEvent(OtaStatus.DOWNLOADING, '42'),
      );
      expect(progress?.phase, UpdateInstallPhase.downloading);
      expect(progress?.percent, closeTo(0.42, 0.001));
    });

    test('clamps oversized percent values', () {
      final progress = DirectUpdateStrategy.mapOtaEvent(
        OtaEvent(OtaStatus.DOWNLOADING, '150'),
      );
      expect(progress?.percent, 1.0);
    });

    test('maps installing to openingInstaller', () {
      final progress = DirectUpdateStrategy.mapOtaEvent(
        OtaEvent(OtaStatus.INSTALLING, null),
      );
      expect(progress?.phase, UpdateInstallPhase.openingInstaller);
    });

    test('maps checksum error', () {
      final progress = DirectUpdateStrategy.mapOtaEvent(
        OtaEvent(OtaStatus.CHECKSUM_ERROR, 'mismatch'),
      );
      expect(progress?.phase, UpdateInstallPhase.failed);
      expect(progress?.failureReason, UpdateInstallFailureReason.checksum);
    });

    test('maps permission error', () {
      final progress = DirectUpdateStrategy.mapOtaEvent(
        OtaEvent(OtaStatus.PERMISSION_NOT_GRANTED_ERROR, null),
      );
      expect(progress?.failureReason, UpdateInstallFailureReason.permission);
    });

    test('maps canceled', () {
      final progress = DirectUpdateStrategy.mapOtaEvent(
        OtaEvent(OtaStatus.CANCELED, null),
      );
      expect(progress?.phase, UpdateInstallPhase.canceled);
    });

    test('maps download error', () {
      final progress = DirectUpdateStrategy.mapOtaEvent(
        OtaEvent(OtaStatus.DOWNLOAD_ERROR, 'network'),
      );
      expect(progress?.failureReason, UpdateInstallFailureReason.download);
    });
  });

  group('DirectUpdateStrategy.pickAndroidApkForTest', () {
    final manifest = ReleaseManifest(
      version: '1.2.3',
      build: 4,
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

    test('prefers abi-matching asset', () {
      final asset = DirectUpdateStrategy.pickAndroidApkForTest(
        manifest,
        'arm64-v8a',
      );
      expect(asset?.url, 'https://example.com/arm64.apk');
    });

    test('selects armeabi-v7a when that is the device abi', () {
      final asset = DirectUpdateStrategy.pickAndroidApkForTest(
        manifest,
        'armeabi-v7a',
      );
      expect(asset?.url, 'https://example.com/v7a.apk');
    });

    test('falls back when abi unknown', () {
      final asset = DirectUpdateStrategy.pickAndroidApkForTest(manifest, null);
      expect(asset?.url, 'https://example.com/arm64.apk');
    });
  });
}
