/// Result-sharing single-flight slot for async work that must not overlap.
library;

import 'dart:async';

/// One joinable in-flight slot for an op that produces a value.
///
/// The value-sharing counterpart to `SingleFlightGate`'s void slot:
/// concurrent callers of [run] coalesce onto the first caller's future and
/// share its result — and its error. The slot is claimed before the thunk is
/// invoked, so a joining caller never starts competing work, and the slot is
/// cleared only if the settling op still owns it.
///
/// [run] hands the thunk a release callback for slots that must be freed in
/// the same tick as the work finishes. A drain gate needs that: its follow-up
/// request would be dropped when a caller lands between the work's
/// completion and the slot's release. Without the callback the slot is held
/// until the result is delivered.
///
/// Call sites that must observe a join (e.g. to schedule a follow-up pass)
/// check [pending] first; per-site policy stays at the call site.
class InFlightOp<T> {
  Future<T>? _pending;

  /// The op currently holding the slot, or `null`.
  Future<T>? get pending => _pending;

  /// Joins the op holding the slot, or claims the slot for [op] and awaits
  /// it to completion.
  ///
  /// [op] is a thunk so a joining caller never starts the work. It receives a
  /// callback that releases the slot while the op is still running. Errors
  /// propagate identically to the leader and every joiner through the
  /// shared future.
  Future<T> run(Future<T> Function(void Function() release) op) async {
    final existing = _pending;
    if (existing != null) {
      return existing;
    }
    final completer = Completer<T>();
    final shared = completer.future;
    _pending = shared;
    void release() {
      if (identical(_pending, shared)) _pending = null;
    }

    try {
      completer.complete(await op(release));
    } catch (e, st) {
      completer.completeError(e, st);
    } finally {
      release();
    }
    return shared;
  }
}
