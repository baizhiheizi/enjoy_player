/// Result-sharing single-flight slot for async work that must not overlap.
library;

/// One joinable in-flight slot for an op that produces a value.
///
/// The value-sharing counterpart to `SingleFlightGate`'s void slot:
/// concurrent callers of [run] coalesce onto the first caller's future and
/// share its result — and its error. The slot is claimed before the thunk is
/// invoked, so a joining caller never starts competing work, and the slot is
/// cleared only if the settling op still owns it.
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
  /// [op] is a thunk so a joining caller never starts the work. Errors
  /// propagate identically to the leader and every joiner through the
  /// shared future.
  Future<T> run(Future<T> Function() op) async {
    final existing = _pending;
    if (existing != null) {
      return existing;
    }
    final future = op();
    _pending = future;
    try {
      return await future;
    } finally {
      if (identical(_pending, future)) _pending = null;
    }
  }
}
