/// Per-`AiKind` cache policy: TTL, L2 row cap, L2 row age cutoff.
///
/// Defaults are conservative (30 min TTL, 4096 row cap, 30 d age cutoff).
/// See `specs/015-ai-cache-hierarchy/data-model.md` for the per-kind
/// defaults.
library;

import 'package:enjoy_player/features/ai/domain/ai_kind.dart';

class AiKindPolicy {
  const AiKindPolicy({
    required this.ttl,
    required this.l2RowCap,
    required this.l2AgeCutoff,
  });

  /// L1 entry TTL. `Duration.zero` and below are treated as "never expire"
  /// at the call site (the auto-translate line kind uses this).
  final Duration ttl;

  /// Per-kind Drift L2 row cap. `0` means "unbounded" (the auto-translate
  /// line kind uses a large cap, not unbounded, to keep Drift from
  /// exploding across sessions).
  final int l2RowCap;

  /// Per-kind Drift L2 row age cutoff. Rows older than
  /// `DateTime.now() - l2AgeCutoff` are pruned on startup.
  final Duration l2AgeCutoff;

  /// Returns true when this policy's TTL means "never expire". Used by the
  /// cache to skip the TTL check.
  bool get isTtlInfinite => ttl == Duration.zero;
}

const _defaultPolicies = <AiKind, AiKindPolicy>{
  AiKind.translation: AiKindPolicy(
    ttl: Duration(minutes: 30),
    l2RowCap: 4096,
    l2AgeCutoff: Duration(days: 30),
  ),
  AiKind.dictionary: AiKindPolicy(
    ttl: Duration(minutes: 30),
    l2RowCap: 4096,
    l2AgeCutoff: Duration(days: 30),
  ),
  AiKind.contextualTranslation: AiKindPolicy(
    ttl: Duration(minutes: 30),
    l2RowCap: 2048,
    l2AgeCutoff: Duration(days: 14),
  ),
  AiKind.autoTranslateLine: AiKindPolicy(
    ttl: Duration(minutes: 30),
    l2RowCap: 8192,
    l2AgeCutoff: Duration(days: 30),
  ),
};

/// Default policies keyed by [AiKind]. Modifying the returned map mutates
/// the global default — clone it before mutating in tests.
Map<AiKind, AiKindPolicy> get defaultAiKindPolicies =>
    Map<AiKind, AiKindPolicy>.from(_defaultPolicies);
