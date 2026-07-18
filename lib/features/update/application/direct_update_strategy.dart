/// Direct-download channel: manifest check + platform install hooks.
library;

import 'dart:async';
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
  DirectUpdateStrategy({
    VersionManifestRepository? manifestRepository,
    OtaUpdate Function()? otaUpdateFactory,
  }) : _manifest = manifestRepository ?? VersionManifestRepository(),
       _otaUpdateFactory = otaUpdateFactory ?? OtaUpdate.new;

  final VersionManifestRepository _manifest;
  final OtaUpdate Function() _otaUpdateFactory;
  static bool _desktopUpdaterInitialized = false;

  OtaUpdate? _activeOta;

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
  Stream<UpdateInstallProgress> applyUpdate(AppRelease release) async* {
    if (Platform.isWindows || Platform.isMacOS) {
      yield* _applyDesktopUpdate();
      return;
    }
    if (Platform.isAndroid) {
      yield* _applyAndroidSideload(release);
      return;
    }
    _log.warning('applyUpdate unsupported on ${defaultTargetPlatform.name}');
    yield const UpdateInstallProgress.failed(
      reason: UpdateInstallFailureReason.internal,
      detail: 'unsupported_platform',
    );
  }

  @override
  Future<void> cancelUpdate() async {
    final ota = _activeOta;
    if (ota == null) return;
    try {
      await ota.cancel();
    } catch (e, st) {
      _log.warning('cancel update failed', e, st);
    }
  }

  Stream<UpdateInstallProgress> _applyDesktopUpdate() async* {
    yield const UpdateInstallProgress.preparing();
    try {
      if (!_desktopUpdaterInitialized) {
        await autoUpdater.setFeedURL(kEnjoyPlayerAppcastUrl);
        _desktopUpdaterInitialized = true;
      }
      await autoUpdater.checkForUpdates();
      yield const UpdateInstallProgress.openingInstaller();
      yield const UpdateInstallProgress.completed();
    } catch (e, st) {
      _log.warning('desktop update failed', e, st);
      yield UpdateInstallProgress.failed(
        reason: UpdateInstallFailureReason.internal,
        detail: e.toString(),
      );
    }
  }

  Stream<UpdateInstallProgress> _applyAndroidSideload(
    AppRelease release,
  ) async* {
    yield const UpdateInstallProgress.preparing();

    String? abi;
    try {
      abi = await _otaUpdateFactory().getAbi();
    } catch (e, st) {
      _log.fine('getAbi failed; falling back to preferred keys', e, st);
    }

    final asset = _pickAndroidApk(release.manifest, abi);
    if (asset == null) {
      _log.warning('no Android APK asset in manifest (abi=$abi)');
      yield const UpdateInstallProgress.failed(
        reason: UpdateInstallFailureReason.internal,
        detail: 'no_apk_asset',
      );
      return;
    }

    final expected = normalizeSha256Hex(asset.sha256);
    // Fresh instance per attempt — ota_update caches the first stream on the
    // Dart object and would otherwise reuse a closed/finished stream on retry.
    final ota = _otaUpdateFactory();
    _activeOta = ota;

    var terminalEmitted = false;

    try {
      await for (final event
          in ota
              .execute(
                asset.url,
                destinationFilename: 'enjoy_player_update.apk',
                sha256checksum: expected,
              )
              .timeout(const Duration(minutes: 30))) {
        final mapped = mapOtaEvent(event);
        if (mapped == null) continue;

        // INSTALLING is emitted after optional checksum verification and just
        // before the system installer intent — surface both stages.
        if (mapped.phase == UpdateInstallPhase.openingInstaller) {
          if (expected != null) {
            yield const UpdateInstallProgress.verifying();
          }
          yield mapped;
          // Default install path closes the plugin stream after INSTALLING.
          yield const UpdateInstallProgress.completed();
          terminalEmitted = true;
          break;
        }

        yield mapped;
        if (mapped.isTerminal) {
          terminalEmitted = true;
          break;
        }
      }
      if (!terminalEmitted) {
        // Stream ended without an explicit terminal; treat as handoff success.
        yield const UpdateInstallProgress.completed();
      }
    } on TimeoutException catch (e, st) {
      _log.warning('OTA timed out', e, st);
      yield const UpdateInstallProgress.failed(
        reason: UpdateInstallFailureReason.download,
        detail: 'timeout',
      );
    } on OtaUpdateException catch (e, st) {
      _log.warning('OTA input error', e, st);
      yield UpdateInstallProgress.failed(
        reason: UpdateInstallFailureReason.internal,
        detail: e.message,
      );
    } catch (e, st) {
      _log.warning('OTA unexpected error', e, st);
      yield UpdateInstallProgress.failed(
        reason: UpdateInstallFailureReason.internal,
        detail: e.toString(),
      );
    } finally {
      if (identical(_activeOta, ota)) {
        _activeOta = null;
      }
    }
  }

  /// Maps a plugin [OtaEvent] to app progress, or null to ignore.
  @visibleForTesting
  static UpdateInstallProgress? mapOtaEvent(OtaEvent event) {
    switch (event.status) {
      case OtaStatus.DOWNLOADING:
        final percent = _parsePercent(event.value);
        _log.fine('APK download ${(percent * 100).round()}%');
        return UpdateInstallProgress.downloading(percent);
      case OtaStatus.INSTALLING:
        _log.info('APK install starting');
        // Plugin emits INSTALLING after checksum (when provided) and just
        // before the system installer intent.
        return const UpdateInstallProgress.openingInstaller();
      case OtaStatus.INSTALLATION_DONE:
        return const UpdateInstallProgress.completed();
      case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
        _log.warning('install permission not granted');
        return const UpdateInstallProgress.failed(
          reason: UpdateInstallFailureReason.permission,
        );
      case OtaStatus.DOWNLOAD_ERROR:
        _log.warning('OTA download error: ${event.value}');
        return UpdateInstallProgress.failed(
          reason: UpdateInstallFailureReason.download,
          detail: event.value,
        );
      case OtaStatus.CHECKSUM_ERROR:
        _log.warning('OTA checksum error: ${event.value}');
        return UpdateInstallProgress.failed(
          reason: UpdateInstallFailureReason.checksum,
          detail: event.value,
        );
      case OtaStatus.ALREADY_RUNNING_ERROR:
        _log.warning('OTA already running');
        return const UpdateInstallProgress.failed(
          reason: UpdateInstallFailureReason.alreadyRunning,
        );
      case OtaStatus.INSTALLATION_ERROR:
        _log.warning('OTA installation error: ${event.value}');
        return UpdateInstallProgress.failed(
          reason: UpdateInstallFailureReason.installation,
          detail: event.value,
        );
      case OtaStatus.INTERNAL_ERROR:
        _log.warning('OTA internal error: ${event.value}');
        return UpdateInstallProgress.failed(
          reason: UpdateInstallFailureReason.internal,
          detail: event.value,
        );
      case OtaStatus.CANCELED:
        _log.info('OTA canceled');
        return const UpdateInstallProgress.canceled();
    }
  }

  static double _parsePercent(String? raw) {
    if (raw == null || raw.isEmpty) return 0;
    final value = double.tryParse(raw);
    if (value == null) return 0;
    // Plugin reports 0–100 integers as strings.
    final fraction = value > 1.0 ? value / 100.0 : value;
    if (fraction.isNaN || fraction.isInfinite) return 0;
    return fraction.clamp(0.0, 1.0);
  }

  @visibleForTesting
  static PlatformAsset? pickAndroidApkForTest(
    ReleaseManifest manifest,
    String? abi,
  ) => _pickAndroidApkStatic(manifest, abi);

  PlatformAsset? _pickAndroidApk(ReleaseManifest manifest, String? abi) =>
      _pickAndroidApkStatic(manifest, abi);

  static PlatformAsset? _pickAndroidApkStatic(
    ReleaseManifest manifest,
    String? abi,
  ) {
    final preferred = <String>[];
    final normalized = abi?.trim().toLowerCase();
    if (normalized != null && normalized.isNotEmpty) {
      // Device ABI from ota_update, e.g. arm64-v8a / armeabi-v7a / x86_64.
      preferred.addAll(_keysForAbi(normalized));
    }
    preferred.addAll(const [
      'android_arm64',
      'android_arm64_v8a',
      'android_armeabi_v7a',
      'android_x86_64',
      'android',
    ]);

    final seen = <String>{};
    for (final key in preferred) {
      if (!seen.add(key)) continue;
      final asset = manifest.assets[key];
      if (asset != null) return asset;
    }
    for (final key in manifest.assets.keys) {
      if (key.startsWith('android')) return manifest.assets[key];
    }
    return null;
  }

  static List<String> _keysForAbi(String abi) {
    // Match keys emitted by generate_update_feeds / release_android.sh.
    if (abi.contains('arm64') || abi == 'aarch64') {
      return const ['android_arm64_v8a', 'android_arm64', 'android-arm64-v8a'];
    }
    if (abi.contains('armeabi') || abi == 'armv7' || abi == 'armeabi-v7a') {
      return const ['android_armeabi_v7a', 'android-armeabi-v7a'];
    }
    if (abi.contains('x86_64') || abi == 'x64') {
      return const ['android_x86_64', 'android-x86_64'];
    }
    if (abi.contains('x86')) {
      return const ['android_x86', 'android-x86'];
    }
    return const [];
  }
}
