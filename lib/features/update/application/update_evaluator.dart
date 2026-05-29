/// Compares running version to a remote [ReleaseManifest].
library;

import 'package:enjoy_player/features/update/domain/semver_compare.dart';
import 'package:enjoy_player/features/update/domain/update_types.dart';

UpdateCheckResult evaluateUpdate({
  required String currentVersion,
  required ReleaseManifest manifest,
  String? snoozedVersion,
  DateTime? snoozeUntil,
  DateTime? now,
}) {
  final clock = now ?? DateTime.now().toUtc();

  if (!isVersionLessThan(currentVersion, manifest.version)) {
    return const UpdateCheckResult.upToDate();
  }

  final mandatory = isVersionLessThan(
    currentVersion,
    manifest.minSupportedVersion,
  );
  if (mandatory) {
    return UpdateCheckResult(
      availability: UpdateAvailability.mandatoryUpdate,
      release: AppRelease(
        manifest: manifest,
        severity: UpdateSeverity.mandatory,
        currentVersion: currentVersion,
      ),
    );
  }

  if (snoozedVersion == manifest.version &&
      snoozeUntil != null &&
      clock.isBefore(snoozeUntil)) {
    return const UpdateCheckResult.upToDate();
  }

  return UpdateCheckResult(
    availability: UpdateAvailability.updateAvailable,
    release: AppRelease(
      manifest: manifest,
      severity: UpdateSeverity.optional,
      currentVersion: currentVersion,
    ),
  );
}
