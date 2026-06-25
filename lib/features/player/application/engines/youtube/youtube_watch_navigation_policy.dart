/// Navigation allow/deny rules for the YouTube player [InAppWebView].
///
/// See ADR-0025 — blocks Google sign-in hijacks during watch-page playback.
library;

/// True when [url] is YouTube/Google silent sign-in (observed on `m.youtube.com`
/// watch loads without existing session cookies).
bool isPassiveGoogleSignInUrl(String url) {
  if (!url.contains('accounts.google.com')) return false;
  if (url.contains('passive=true')) return true;
  if (url.contains('signin_passive')) return true;
  return false;
}

/// True when [loadStopUrl] is a YouTube watch/consent surface worth treating as
/// "page ready" (excludes `about:`, Google account, etc.).
bool isYoutubeWatchPageLoadStopUrl(String? loadStopUrl) {
  if (loadStopUrl == null || loadStopUrl.isEmpty) return false;
  if (loadStopUrl == 'about:blank' || loadStopUrl.startsWith('about:')) {
    return false;
  }
  if (loadStopUrl.contains('accounts.google.com')) return false;
  if (loadStopUrl.contains('consent.youtube.com')) return false;
  return loadStopUrl.contains('youtube.com') ||
      loadStopUrl.contains('youtu.be');
}

/// Maps platform [NavigationAction.isForMainFrame] to a strict bool.
///
/// Unknown / null is treated as subframe so CDN and segment loads are never
/// blocked (Android, iOS, macOS, Windows).
bool resolveYoutubeNavigationIsForMainFrame(bool? isForMainFrame) =>
    isForMainFrame ?? false;

/// YouTube media and static asset hosts (not matched by `google.com` alone).
bool isYoutubePlaybackOrStaticAssetUrl(String url) {
  return url.contains('googlevideo.com') ||
      url.contains('ytimg.com') ||
      url.contains('ggpht.com') ||
      url.contains('googleusercontent.com');
}

/// Whether the player WebView may navigate to [url] while [videoId] is open.
///
/// Explicit YouTube login uses [`YoutubeLoginScreen`] — not the player WebView.
///
/// Applies on **all platforms** (Android, iOS, macOS, Windows). Pass
/// [isForMainFrame] from [NavigationAction.isForMainFrame]: on Windows some
/// iframe document loads use `isForMainFrame: false`; on Android/iOS/macOS
/// subframe navigations also arrive with `isForMainFrame: false` and must not
/// be blocked.
bool shouldAllowYoutubeWatchNavigation({
  required String url,
  required String videoId,
  required bool isForMainFrame,
}) {
  // Never block CDN / static asset requests (e.g. googlevideo.com segments).
  if (!isForMainFrame) {
    return true;
  }

  if (url == 'about:blank' || url.startsWith('about:')) {
    return true;
  }
  if (videoId.isEmpty) {
    return false;
  }

  // Never leave the watch surface for Google account flows (passive or active).
  if (url.contains('accounts.google.com')) {
    return false;
  }

  if (url.contains('consent.youtube.com') ||
      url.contains('myaccount.google.com') ||
      url.contains('gstatic.com') ||
      url.contains('googleapis.com')) {
    return true;
  }

  if (isYoutubePlaybackOrStaticAssetUrl(url)) {
    return true;
  }

  if (url.contains('youtube.com') ||
      url.contains('youtu.be') ||
      url.contains('google.com')) {
    return true;
  }

  return false;
}
