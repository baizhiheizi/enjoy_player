/// Domain types for release update checks (UI-free).
library;

/// Whether the user must update before continuing.
enum UpdateSeverity { optional, mandatory }

/// One downloadable asset from [ReleaseManifest].
class PlatformAsset {
  const PlatformAsset({required this.url, this.sha256, this.file});

  final String url;
  final String? sha256;
  final String? file;
}

/// Parsed `latest.json` feed.
class ReleaseManifest {
  const ReleaseManifest({
    required this.version,
    required this.build,
    required this.minSupportedVersion,
    required this.notes,
    required this.assets,
  });

  final String version;
  final int build;
  final String minSupportedVersion;
  final String notes;
  final Map<String, PlatformAsset> assets;
}

/// Latest release info compared to the running app.
class AppRelease {
  const AppRelease({
    required this.manifest,
    required this.severity,
    required this.currentVersion,
  });

  final ReleaseManifest manifest;
  final UpdateSeverity severity;
  final String currentVersion;
}

/// Outcome of comparing the running app to the remote manifest.
enum UpdateAvailability { upToDate, updateAvailable, mandatoryUpdate }

class UpdateCheckResult {
  const UpdateCheckResult({
    required this.availability,
    this.release,
    this.errorMessage,
  });

  const UpdateCheckResult.upToDate()
    : availability = UpdateAvailability.upToDate,
      release = null,
      errorMessage = null;

  final UpdateAvailability availability;
  final AppRelease? release;
  final String? errorMessage;

  bool get hasUpdate =>
      availability == UpdateAvailability.updateAvailable ||
      availability == UpdateAvailability.mandatoryUpdate;
}

/// Stages of an in-progress download/install handoff.
enum UpdateInstallPhase {
  preparing,
  downloading,
  verifying,
  openingInstaller,
  completed,
  failed,
  canceled,
}

/// Typed failure reasons surfaced to the update prompt UI.
enum UpdateInstallFailureReason {
  download,
  checksum,
  permission,
  alreadyRunning,
  installation,
  canceled,
  internal,
  unknown,
}

/// Progress event emitted while applying a direct update.
class UpdateInstallProgress {
  const UpdateInstallProgress({
    required this.phase,
    this.percent,
    this.failureReason,
    this.failureDetail,
  });

  const UpdateInstallProgress.preparing()
    : phase = UpdateInstallPhase.preparing,
      percent = null,
      failureReason = null,
      failureDetail = null;

  const UpdateInstallProgress.downloading(this.percent)
    : phase = UpdateInstallPhase.downloading,
      failureReason = null,
      failureDetail = null;

  const UpdateInstallProgress.verifying()
    : phase = UpdateInstallPhase.verifying,
      percent = null,
      failureReason = null,
      failureDetail = null;

  const UpdateInstallProgress.openingInstaller()
    : phase = UpdateInstallPhase.openingInstaller,
      percent = null,
      failureReason = null,
      failureDetail = null;

  const UpdateInstallProgress.completed()
    : phase = UpdateInstallPhase.completed,
      percent = null,
      failureReason = null,
      failureDetail = null;

  const UpdateInstallProgress.canceled()
    : phase = UpdateInstallPhase.canceled,
      percent = null,
      failureReason = UpdateInstallFailureReason.canceled,
      failureDetail = null;

  const UpdateInstallProgress.failed({
    required UpdateInstallFailureReason reason,
    String? detail,
  }) : phase = UpdateInstallPhase.failed,
       percent = null,
       failureReason = reason,
       failureDetail = detail;

  final UpdateInstallPhase phase;

  /// Download fraction in `0.0…1.0` when [phase] is [UpdateInstallPhase.downloading].
  final double? percent;
  final UpdateInstallFailureReason? failureReason;
  final String? failureDetail;

  bool get isTerminal =>
      phase == UpdateInstallPhase.completed ||
      phase == UpdateInstallPhase.failed ||
      phase == UpdateInstallPhase.canceled;
}
