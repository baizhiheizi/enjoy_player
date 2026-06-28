/// Quantized player position stream.
///
/// Folds [PlayerEngine.position] (ADR-0015) into N-millisecond buckets and
/// drops equal emissions, so downstream widgets only rebuild when the
/// quantized value actually changes. Bucket sizes are centralized in
/// `position_buckets.dart`.
library;

/// Returns a stream that emits a new [Duration] every time the input
/// position crosses a [bucketMs]-sized grid boundary, and deduplicates
/// consecutive equal values.
///
/// The function is pure (no Riverpod) so both `@riverpod`-generated and
/// manual `StreamProvider` callers can share it.
Stream<Duration> quantizedPositionStream(
  Stream<Duration> position, {
  required int bucketMs,
}) {
  return position.map((position) {
    final ms = position.inMilliseconds;
    final quantizedMs = (ms ~/ bucketMs) * bucketMs;
    return Duration(milliseconds: quantizedMs);
  }).distinct();
}
