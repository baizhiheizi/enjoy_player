part of 'youtube_session.dart';

/// WebView mount/unmount lifecycle and open-time init instrumentation.
mixin YoutubeSessionWebViewLifecycle on YoutubeSessionBase {
  final GlobalKey webViewHostKey = GlobalKey();
  final ValueNotifier<int> _mountTick = ValueNotifier(0);

  bool _mountRequested = false;
  bool _webViewMounted = false;
  Completer<void>? _surfaceDetached;
  Completer<void>? _webViewMountedWaiter;
  Stopwatch? _initStopwatch;

  /// Read-only view: host-tree rebuilds observe, only the session mutates.
  ValueListenable<int> get mountTick => _mountTick;

  bool get shouldMountWebView => _mountRequested && !_disposed;
  bool get webViewMounted => _webViewMounted;

  void noteWebViewMounted() {
    _webViewMounted = true;
    final waiter = _webViewMountedWaiter;
    _webViewMountedWaiter = null;
    if (waiter != null && !waiter.isCompleted) {
      waiter.complete();
    }
  }

  void noteWebViewUnmounted() {
    _webViewMounted = false;
    final waiter = _surfaceDetached;
    _surfaceDetached = null;
    if (waiter != null && !waiter.isCompleted) {
      waiter.complete();
    }
  }

  /// Completes when the WebView next mounts, or immediately if it already is.
  ///
  /// The waiter is armed lazily so consecutive mount/unmount cycles each get
  /// their own signal (same shape as [_surfaceDetached]). A waiter left
  /// hanging by [closeStreams] is bounded by the caller's mount timeout, as
  /// the flag-polling loop it replaces was.
  Future<void> awaitWebViewMounted() {
    if (_webViewMounted) return Future<void>.value();
    return (_webViewMountedWaiter ??= Completer<void>()).future;
  }

  /// Completes when the WebView widget has unmounted, or immediately if it
  /// is not mounted. Does not wait for native view destruction.
  Future<void> awaitSurfaceDetached() async {
    if (!_webViewMounted) return;
    final waiter = _surfaceDetached ??= Completer<void>();
    return waiter.future;
  }

  void requestMount() {
    if (_disposed) return;
    if (_mountRequested) return;
    _mountRequested = true;
    bumpMountTick();
  }

  /// Notifies host-tree listeners that session-derived UI changed.
  void bumpMountTick() => _mountTick.value++;

  /// Deferred variant for teardown paths that run during widget unmount —
  /// notifying synchronously there locks the tree.
  void scheduleMountTickBump() {
    scheduleMicrotask(bumpMountTick);
  }

  /// Starts (or restarts) open-time init instrumentation.
  void startInitTiming() => _initStopwatch = Stopwatch()..start();

  void logInitPhase(String phase, void Function(String message) log) {
    final ms = _initStopwatch?.elapsedMilliseconds;
    final message = 'youtube init $phase${ms != null ? ' +${ms}ms' : ''}';
    if (phase == 'load_stop' || phase == 'first_playing') {
      log(message);
    }
  }
}
