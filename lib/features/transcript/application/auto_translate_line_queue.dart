/// Scheduling queue for on-demand per-line auto-translate requests.
library;

import 'dart:collection';

import '../domain/auto_translate.dart';

/// Viewport-prioritized queue of transcript lines waiting for translation.
///
/// Owns the in-flight set, the waiting order and the force-refresh marks.
/// The effects the queue cannot perform on its own — starting a translation,
/// reading the playback anchor, and publishing the in-flight set — are
/// injected, so the ordering and concurrency rules stay unit-testable without
/// Riverpod.
class AutoTranslateLineQueue {
  AutoTranslateLineQueue({
    required this.isLineFailed,
    required this.startTranslate,
    required this.currentCueAnchor,
    required this.publishInFlight,
  });

  /// Whether [lineIndex] already failed and must not be scheduled again.
  final bool Function(int lineIndex) isLineFailed;

  /// Starts the translation of [lineIndex].
  final void Function(int lineIndex, {required bool forceRefresh})
  startTranslate;

  /// The playback cue the waiting order is anchored on.
  final int Function() currentCueAnchor;

  /// Publishes the lines currently being translated.
  final void Function(Set<int> inFlightIndexes) publishInFlight;

  final Set<int> _inFlight = <int>{};
  final ListQueue<int> _waiting = ListQueue<int>();
  final Set<int> _forceRefreshLines = <int>{};

  /// The waiting lines, in the order they will be started.
  List<int> get waitingOrder => List<int>.unmodifiable(_waiting);

  /// Whether [lineIndex] is currently being translated.
  bool isInFlight(int lineIndex) => _inFlight.contains(lineIndex);

  /// Whether [lineIndex] is waiting for a free translation slot.
  bool isWaiting(int lineIndex) => _waiting.contains(lineIndex);

  /// Whether a new translation may start without exceeding the concurrency
  /// limit.
  bool get hasFreeSlot => _inFlight.length < kAutoTranslateMaxConcurrency;

  /// Marks [lineIndex] as being translated.
  void markInFlight(int lineIndex) {
    _inFlight.add(lineIndex);
    publishInFlight(Set<int>.from(_inFlight));
  }

  /// Marks [lineIndex] as no longer being translated.
  void releaseInFlight(int lineIndex) {
    _inFlight.remove(lineIndex);
    publishInFlight(Set<int>.from(_inFlight));
  }

  /// Marks [lineIndex] so its next translation bypasses the cache.
  void markForceRefresh(int lineIndex) => _forceRefreshLines.add(lineIndex);

  /// Whether [lineIndex] is marked for a cache-bypassing translation.
  bool isForceRefreshPending(int lineIndex) =>
      _forceRefreshLines.contains(lineIndex);

  /// Consumes the force-refresh mark of [lineIndex].
  bool consumeForceRefresh(int lineIndex) =>
      _forceRefreshLines.remove(lineIndex);

  /// Removes [lineIndex] from the waiting order.
  void removeWaiting(int lineIndex) => _waiting.remove(lineIndex);

  /// Empties the waiting order, keeping the in-flight and force-refresh sets.
  void clearWaiting() => _waiting.clear();

  /// Empties every set and publishes the empty in-flight set.
  void clear() {
    _waiting.clear();
    _forceRefreshLines.clear();
    _inFlight.clear();
    publishInFlight(Set<int>.from(_inFlight));
  }

  /// Queues [lineIndex] for a later translation.
  ///
  /// A line that is already waiting keeps its position. [preferFront] puts
  /// the line ahead of the earlier requests, which is what a user-initiated
  /// re-translation asks for.
  void enqueue(int lineIndex, {bool preferFront = false}) {
    if (_waiting.contains(lineIndex)) return;
    if (preferFront) {
      _waiting.addFirst(lineIndex);
    } else {
      _waiting.add(lineIndex);
    }
  }

  /// Reorders the waiting lines around the playback anchor.
  ///
  /// Lines further than [kAutoTranslateViewportWindow] away from the anchor
  /// are dropped: a seek moved the user away from them, so translating them
  /// would waste the budget of the lines now on screen.
  void reprioritize({int? anchor}) {
    if (_waiting.isEmpty) return;
    final raw = anchor ?? currentCueAnchor();
    final focus = raw < 0 ? 0 : raw;
    final nearby = _waiting
        .where((i) => (i - focus).abs() <= kAutoTranslateViewportWindow)
        .toList();
    final ordered = orderPendingLineIndexes(
      anchorIndex: focus,
      pending: nearby,
    );
    _waiting
      ..clear()
      ..addAll(ordered);
  }

  /// Starts as many waiting lines as the concurrency limit allows.
  void drain() {
    reprioritize();
    while (_waiting.isNotEmpty &&
        _inFlight.length < kAutoTranslateMaxConcurrency) {
      final next = _waiting.removeFirst();
      if (_inFlight.contains(next) || isLineFailed(next)) continue;
      startTranslate(next, forceRefresh: _forceRefreshLines.contains(next));
    }
  }
}
