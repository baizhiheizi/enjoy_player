<!-- hash: app-db-2026-07-16 -->

# lib/data/db/app_database.dart

Root Drift database for Enjoy Player (native SQLite via `drift_flutter`). Tables include `videos`, `audios`, `transcripts`, `echo_sessions`, `recordings`, `dictations`, `sync_queue`, `settings`, `ai_cache`, `transcript_fetch_states`, `youtube_channel_subscriptions`, `youtube_feed_entries`. Each feature owns its DAO under `lib/data/db/daos/`. Migrations use `onUpgrade`; v6→v7 added Discover tables incrementally; v8→v9 added the `idx_transcript_fetch_states_target` composite index via `CREATE INDEX IF NOT EXISTS`. Schema below v6 uses destructive upgrade.
