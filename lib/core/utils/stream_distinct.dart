/// Stream dedupe helpers — skip emissions whose value compares equal to the
/// last value the subscriber already saw.
///
/// Used to absorb redundant Drift re-emissions (and any upstream re-mapping
/// that produces a new container but no semantic change) before the value
/// reaches Riverpod listeners.
library;

import 'dart:async';

/// Returns a stream that forwards [this] emissions for which [equals] returns
/// `false` against the previously forwarded value.
///
/// The dedupe state is per-subscriber: each subscription to the returned
/// stream keeps its own "last seen" reference. This matches Drift's
/// per-subscriber behavior and avoids cross-talk between consumers.
extension StreamDistinctExt<T> on Stream<T> {
  Stream<T> distinctBy(bool Function(T previous, T current) equals) {
    late StreamController<T> controller;
    StreamSubscription<T>? upstream;

    controller = StreamController<T>(
      onListen: () {
        var hasLast = false;
        late T last;
        upstream = listen(
          (value) {
            if (hasLast && equals(last, value)) return;
            last = value;
            hasLast = true;
            controller.add(value);
          },
          onError: controller.addError,
          onDone: () {
            if (!controller.isClosed) controller.close();
          },
        );
      },
      onPause: () => upstream?.pause(),
      onResume: () => upstream?.resume(),
      onCancel: () async {
        final sub = upstream;
        upstream = null;
        await sub?.cancel();
      },
    );
    return controller.stream;
  }
}
