/// Direct-download channel: manifest check + platform install hooks.
library;

import 'dart:io';

import 'package:auto_updater/auto_updater.dart';
import 'package:flutter/foundation.dart';
import 'package:ota_update/ota_update.dart';

import 'package:enjoy_player/core/application/app_links.dart';
import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/features/update/application/update_evaluator.dart';
import 'package:enjoy_player/features/update/application/update_strategy.dart';
import 'package:enjoy_player/features/update/data/checksum_verifier.dart';
import 'package:enjoy_player/features/update/data/version_manifest_repository.dart';
import 'package:enjoy_player/features/update/domain/update_types.dart';

final _log = logNamed('update.direct');

class DirectUpdateStrategy implements UpdateStrategy {
  DirectUpdateStrategy({VersionManifestRepository? manifestRepository})
    : _manifest = manifestRepository ?? VersionManifestRepository();

  final VersionManifestRepository _manifest;
  static bool _desktopUpdaterInitialized = false;

  @override
  Future<UpdateCheckResult> checkForUpdate({
    required String currentVersion,
    String? snoozedVersion,
    DateTime? snoozeUntil,
  }) async {
    final manifest = await _manifest.fetchLatest();
    if (manifest == null) {
      return const UpdateCheckResult(
        availability: UpdateAvailability.upToDate,
        errorMessage: 'offline',
      );
    }
    return evaluateUpdate(
      currentVersion: currentVersion,
      manifest: manifest,
      snoozedVersion: snoozedVersion,
      snoozeUntil: snoozeUntil,
    );
  }

  @override
  Future<void> applyUpdate(AppRelease release) async {
    if (Platform.isWindows || Platform.isMacOS) {
      await _applyDesktopUpdate();
      return;
    }
    if (Platform.isAndroid) {
      await _applyAndroidSideload(release);
      return;
    }
    _log.warning('applyUpdate unsupported on ${defaultTargetPlatform.name}');
  }

  Future<void> _applyDesktopUpdate() async {
    if (!_desktopUpdaterInitialized) {
      await autoUpdater.setFeedURL(kEnjoyPlayerAppcastUrl);
      _desktopUpdaterInitialized = true;
    }
    await autoUpdater.checkForUpdates();
  }

  Future<void> _applyAndroidSideload(AppRelease release) async {
    final asset = _pickAndroidApk(release.manifest);
    if (asset == null) {
      _log.warning('no Android APK asset in manifest');
      return;
    }
    final expected = normalizeSha256Hex(asset.sha256);
    await for (final event
        in OtaUpdate()
            .execute(asset.url, destinationFilename: 'enjoy_player_update.apk')
            .timeout(const Duration(minutes: 30))) {
      switch (event.status) {
        case OtaStatus.DOWNLOADING:
          _log.fine('APK download ${event.value}%');
        case OtaStatus.INSTALLING:
          _log.info('APK install starting');
        case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
          _log.warning('install permission not granted');
          return;
        case OtaStatus.INTERNAL_ERROR:
        case OtaStatus.DOWNLOAD_ERROR:
          _log.warning('OTA error: ${event.status} ${event.value}');
          return;
        default:
          break;
      }
    }
    if (expected != null) {
      _log.fine('manifest sha256 present; plugin stores APK internally');
    }
  }

  PlatformAsset? _pickAndroidApk(ReleaseManifest manifest) {
    const preferred = ['android_arm64', 'android_arm64_v8a', 'android'];
    for (final key in preferred) {
      final asset = manifest.assets[key];
      if (asset != null) return asset;
    }
    for (final key in manifest.assets.keys) {
      if (key.startsWith('android')) return manifest.assets[key];
    }
    return null;
  }
}
