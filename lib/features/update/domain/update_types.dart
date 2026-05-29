/// Domain types for release update checks (UI-free).
library;

/// Whether the user must update before continuing.
enum UpdateSeverity {
  optional,
  mandatory,
}

/// One downloadable asset from [ReleaseManifest].
class PlatformAsset {
  const PlatformAsset({
    required this.url,
    this.sha256,
    this.file,
  });

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
enum UpdateAvailability {
  upToDate,
  updateAvailable,
  mandatoryUpdate,
}

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
