/// How a YouTube channel subscription was added in Discover.
library;

/// Stored in Drift as the enum name (`recommended`, `user`).
enum YoutubeSubscriptionSource {
  /// Bundled recommended catalog.
  recommended,

  /// User pasted a URL, @handle, or channel id.
  user,
}

/// What kind of YouTube source this subscription represents.
/// Stored in Drift as the enum name (`channel`, `playlist`).
enum YoutubeSourceType {
  /// YouTube channel or user handle (both resolve to a channel).
  channel,

  /// YouTube playlist.
  playlist,
}
