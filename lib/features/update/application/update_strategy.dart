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
  Future<void> applyUpdate(AppRelease release);
}
