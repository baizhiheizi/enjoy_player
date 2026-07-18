/// Coordinates update checks, snooze, and prompting.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:enjoy_player/core/logging/log.dart';
import 'package:enjoy_player/core/release/distribution_channel.dart';
import 'package:enjoy_player/data/db/app_database_provider.dart';
import 'package:enjoy_player/data/db/settings_keys.dart';
import 'package:enjoy_player/features/player/application/player_state_providers.dart';
import 'package:enjoy_player/features/update/application/update_providers.dart';
import 'package:enjoy_player/features/update/domain/update_types.dart';

part 'update_controller.g.dart';

final _log = logNamed('update');

/// Minimum interval between automatic startup checks.
const Duration kUpdateStartupDebounce = Duration(hours: 24);

/// Snooze duration for optional updates.
const Duration kUpdateSnoozeDuration = Duration(hours: 24);

@Riverpod(keepAlive: true)
class UpdateCtrl extends _$UpdateCtrl {
  @override
  UpdateCheckResult? build() => null;

  Future<void> bootstrap() async {
    if (!isDirectDistributionChannel) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(checkForUpdatesStartup());
    });
  }

  Future<UpdateCheckResult> checkForUpdatesStartup() async {
    if (!isDirectDistributionChannel) {
      return const UpdateCheckResult.upToDate();
    }
    if (_isPlaybackActive()) {
      return const UpdateCheckResult.upToDate();
    }
    final last = await _readLastCheck();
    if (last != null &&
        DateTime.now().toUtc().difference(last) < kUpdateStartupDebounce) {
      return const UpdateCheckResult.upToDate();
    }
    return _runCheck(persistLastCheck: true);
  }

  Future<UpdateCheckResult> checkForUpdatesManual() async {
    if (!isDirectDistributionChannel) {
      return const UpdateCheckResult.upToDate();
    }
    return _runCheck(persistLastCheck: true, force: true);
  }

  Future<void> snoozeOptionalUpdate(AppRelease release) async {
    final until = DateTime.now().toUtc().add(kUpdateSnoozeDuration);
    final db = ref.read(deviceGlobalAppDatabaseProvider);
    await db.settingsDao.setValue(
      SettingsKeys.updateSnoozeUntil,
      until.toIso8601String(),
    );
    await db.settingsDao.setValue(
      SettingsKeys.updateSnoozeVersion,
      release.manifest.version,
    );
    state = const UpdateCheckResult.upToDate();
  }

  /// Starts the pending update and yields install progress for the UI.
  Stream<UpdateInstallProgress> applyPendingUpdate() async* {
    final release = state?.release;
    if (release == null) {
      yield const UpdateInstallProgress.failed(
        reason: UpdateInstallFailureReason.internal,
        detail: 'no_pending_release',
      );
      return;
    }
    try {
      yield* ref.read(updateStrategyProvider).applyUpdate(release);
    } catch (e, st) {
      _log.warning('apply update failed', e, st);
      yield UpdateInstallProgress.failed(
        reason: UpdateInstallFailureReason.internal,
        detail: e.toString(),
      );
    }
  }

  Future<void> cancelPendingUpdate() async {
    try {
      await ref.read(updateStrategyProvider).cancelUpdate();
    } catch (e, st) {
      _log.warning('cancel update failed', e, st);
    }
  }

  void dismissOptionalPrompt() {
    if (state?.release?.severity == UpdateSeverity.optional) {
      state = const UpdateCheckResult.upToDate();
    }
  }

  Future<UpdateCheckResult> _runCheck({
    required bool persistLastCheck,
    bool force = false,
  }) async {
    try {
      final info = await PackageInfo.fromPlatform();
      final snooze = await _readSnooze();
      final strategy = ref.read(updateStrategyProvider);
      final result = await strategy.checkForUpdate(
        currentVersion: info.version,
        snoozedVersion: snooze.version,
        snoozeUntil: snooze.until,
      );
      if (persistLastCheck) {
        await _writeLastCheck(DateTime.now().toUtc());
      }
      if (result.hasUpdate && !_isPlaybackActive()) {
        state = result;
      } else if (force && !result.hasUpdate && result.errorMessage == null) {
        state = result;
      } else if (force && result.errorMessage != null) {
        state = result;
      } else if (!result.hasUpdate) {
        state = result;
      }
      return result;
    } catch (e, st) {
      _log.warning('update check failed', e, st);
      final failed = UpdateCheckResult(
        availability: UpdateAvailability.upToDate,
        errorMessage: e.toString(),
      );
      if (force) state = failed;
      return failed;
    }
  }

  bool _isPlaybackActive() {
    return ref.read(playerIsPlayingProvider).value ?? false;
  }

  Future<DateTime?> _readLastCheck() async {
    final raw = await ref
        .read(deviceGlobalAppDatabaseProvider)
        .settingsDao
        .getValue(SettingsKeys.updateLastCheckAt);
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw)?.toUtc();
  }

  Future<({String? version, DateTime? until})> _readSnooze() async {
    final db = ref.read(deviceGlobalAppDatabaseProvider);
    final version = await db.settingsDao.getValue(
      SettingsKeys.updateSnoozeVersion,
    );
    final untilRaw = await db.settingsDao.getValue(
      SettingsKeys.updateSnoozeUntil,
    );
    final until = untilRaw == null
        ? null
        : DateTime.tryParse(untilRaw)?.toUtc();
    return (version: version, until: until);
  }

  Future<void> _writeLastCheck(DateTime at) async {
    await ref
        .read(deviceGlobalAppDatabaseProvider)
        .settingsDao
        .setValue(SettingsKeys.updateLastCheckAt, at.toIso8601String());
  }
}
