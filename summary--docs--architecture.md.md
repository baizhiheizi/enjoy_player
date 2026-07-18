<hash>size:6746</hash>

# `docs/architecture.md`

- Defines feature-first `lib/features`, shared `lib/core` and `lib/data`, Riverpod 3, Drift, and the single-player rule.
- Documents runtime media flow, Drift table roles, per-user DB caching, REST service layering, routing, and long-list performance patterns.
- Schema is at v14; below v6 destructive, v6+ incremental. Recent steps: v13→v14 `localMtimeMs` (ADR-0050); v12→v13 `source_type`/`feed_url` (ADR-0051); v11→v12 `ai_cache` (ADR-0045).
- Per-user `AppDatabase` LRU cap of 2 (ADR-0012). GoRouter + ShellRoute; errorBuilder renders NotFoundScreen.
- Sliver child identity via stable `ValueKey<String>` + `findChildIndexCallback` (`findSliverIndexByPrefixedId`).