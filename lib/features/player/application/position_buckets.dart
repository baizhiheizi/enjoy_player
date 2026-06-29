/// Single source of truth for player position quantization buckets.
///
/// See [lib/features/player/application/quantized_position.dart] for the
/// dedup behavior and the rationale for per-bucket tuning. The transport
/// scrubber uses finer buckets than the transcript highlight so the slider
/// tracks finger drags while the cue highlight skips per-tick rebuilds
/// that flood the Windows accessibility bridge (flutter/flutter#182444).
library;

const int kPositionBucketEchoApplyMs = 400;

const int kPositionBucketDisplayMs = 400;

const int kPositionBucketScrubberMs = 50;
