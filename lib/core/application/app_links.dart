/// Public URLs for the Enjoy Player app.
library;

/// Custom URL scheme the app registers for inbound deep links —
/// `enjoyplayer://auth/callback` and `enjoyplayer://checkout/return`.
const String kEnjoyPlayerUrlScheme = 'enjoyplayer';

/// Canonical open-source repository.
const String kEnjoyPlayerGitHubUrl = 'https://github.com/an-lee/enjoy_player';

/// Base URL for Enjoy Player release artifacts and update feeds (no trailing slash).
const String kEnjoyPlayerDownloadBaseUrl = 'https://dl.enjoy.bot/player';

/// Sparkle / WinSparkle appcast consumed by [auto_updater] on desktop direct builds.
const String kEnjoyPlayerAppcastUrl =
    '$kEnjoyPlayerDownloadBaseUrl/appcast.xml';

/// JSON manifest for semver checks and Android sideload APK URLs.
const String kEnjoyPlayerLatestJsonUrl =
    '$kEnjoyPlayerDownloadBaseUrl/latest.json';

/// Developer contact details shown in Settings → About for feedback/support.
const String kDeveloperContactEmail = 'an.lee.work@gmail.com';
const String kDeveloperContactWeChatId = 'an-lee';
const String kDeveloperContactMixinId = '1051445';
