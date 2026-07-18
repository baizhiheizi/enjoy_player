/// Platform-specific update install delegation.
library;

import 'package:enjoy_player/features/update/domain/update_types.dart';

/// Checks remote manifest and performs platform-specific install actions.
abstract class UpdateStrategy {
  Future<UpdateCheckResult> checkForUpdate({
    required String currentVersion,
    String? snoozedVersion,
    DateTime? snoozeUntil,
  });

  /// Starts download/install (or opens native updater UI).
  ///
  /// Yields [UpdateInstallProgress] until a terminal phase
  /// ([UpdateInstallPhase.completed], [UpdateInstallPhase.failed], or
  /// [UpdateInstallPhase.canceled]).
  Stream<UpdateInstallProgress> applyUpdate(AppRelease release);

  /// Cancels an in-flight download when supported by the platform strategy.
  Future<void> cancelUpdate();
}
