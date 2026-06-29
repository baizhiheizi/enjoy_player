/// How a YouTube channel subscription was added in Discover.
library;

/// Stored in Drift as the enum name (`recommended`, `user`).
enum YoutubeSubscriptionSource {
  /// Bundled recommended catalog.
  recommended,

  /// User pasted a URL, @handle, or channel id.
  user,
}
