<size>27863</size>

# `lib/data/db/app_database.dart`

- `@DriftDatabase` with tables: `Videos`, `Audios`, `Transcripts`, `TranscriptFetchStates`, `EchoSessions`, `Recordings`, `Dictations`, `SyncQueue`, `SettingsKv`, `YoutubeChannelSubscriptions`, `YoutubeFeedEntries`.
- DAOs: `VideoDao`, `AudioDao`, `TranscriptDao`, `TranscriptFetchStateDao`, `EchoSessionDao`, `RecordingDao`, `DictationDao`, `SyncQueueDao`, `SettingsDao` + more.
- `transcripts` — `targetType` + `targetId` timeline JSON.
- `transcript_fetch_states` — composite index `idx_transcript_fetch_states_target`.
- Recovery: `_addColumnIfMissing` checks `pragma_table_info` before `ALTER TABLE ADD COLUMN` so half-migrated DBs self-heal.
- Per-user isolation in `app_database_provider.dart` (bounded `LinkedHashMap`, cap 2).
