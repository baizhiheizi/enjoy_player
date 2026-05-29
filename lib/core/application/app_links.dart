/// Public URLs for the Enjoy Player app.
library;

/// Canonical open-source repository.
const String kEnjoyPlayerGitHubUrl =
    'https://github.com/an-lee/enjoy_player';

/// Base URL for Enjoy Player release artifacts and update feeds (no trailing slash).
const String kEnjoyPlayerDownloadBaseUrl = 'https://dl.enjoy.bot/player';

/// Sparkle / WinSparkle appcast consumed by [auto_updater] on desktop direct builds.
const String kEnjoyPlayerAppcastUrl = '$kEnjoyPlayerDownloadBaseUrl/appcast.xml';

/// JSON manifest for semver checks and Android sideload APK URLs.
const String kEnjoyPlayerLatestJsonUrl =
    '$kEnjoyPlayerDownloadBaseUrl/latest.json';
