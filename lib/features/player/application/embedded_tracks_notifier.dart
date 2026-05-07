/// Notifier that signals when embedded subtitle tracks have been found for a
/// media item — consumed by the player UI to show a one-time snackbar.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'embedded_tracks_notifier.g.dart';

/// Holds the last "tracks found" event: (mediaId, count).
/// Null means no pending notification.
typedef EmbeddedTracksEvent = ({String mediaId, int count});

@Riverpod(keepAlive: true)
class EmbeddedTracksNotifier extends _$EmbeddedTracksNotifier {
  @override
  EmbeddedTracksEvent? build() => null;

  void notifyFound(String mediaId, int count) {
    state = (mediaId: mediaId, count: count);
  }

  void consume() {
    state = null;
  }
}
