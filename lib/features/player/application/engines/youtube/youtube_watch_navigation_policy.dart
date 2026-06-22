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

/// Whether the player WebView may navigate to [url] while [videoId] is open.
///
/// Explicit YouTube login uses [`YoutubeLoginScreen`] — not the player WebView.
bool shouldAllowYoutubeWatchNavigation({
  required String url,
  required String videoId,
}) {
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

  if (url.contains('youtube.com') ||
      url.contains('youtu.be') ||
      url.contains('google.com')) {
    return true;
  }

  return false;
}
