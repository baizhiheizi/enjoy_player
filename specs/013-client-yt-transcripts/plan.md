# Implementation Plan: Client-Side YouTube Transcript Fetching

**Branch**: `013-client-yt-transcripts` | **Date**: 2026-07-12 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/013-client-yt-transcripts/spec.md`

## Summary

Move YouTube transcript fetching from server-side worker polling to client-side direct YouTube API calls. Redesign the worker API to a GET-based cache layer with upload-for-caching. Add a remotely configurable client profile system. Implement a three-tier fallback chain: local persistence → worker cache GET → direct YouTube InnerTube API.

**Technical approach**: Port the `youtube-caption-extractor` TypeScript library's two-step HTTP flow (InnerTube POST → caption track GET) to Dart using `package:http`. Use `dart:convert`'s `HtmlUnescape` + regex for entity/tag stripping. Wire profiles through a worker-queryable configuration with built-in fallbacks.

## Technical Context

**Language/Version**: Dart ^3.10, Flutter stable 3.x

**Primary Dependencies**: Riverpod (state), Drift (persistence), `package:http` (network), `dart:convert` (JSON + HTML unescape)

**Storage**: Drift `AppDatabase` — `transcripts` table (existing), `settings` table for profile cache (existing), `transcript_fetch_states` (existing)

**Testing**: `flutter test` with in-memory Drift (`NativeDatabase.memory()`) for repository/DAO tests, `http.MockClient` for API tests, `Override` for provider tests

**Target Platform**: Android, iOS, macOS, Windows (no Flutter web)

**Project Type**: Flutter native mobile/desktop app

**Performance Goals**: Direct fetch completion in <5s (common case), <2s cached/local, local re-open in <500ms, 5000+ line transcripts parsed off main isolate

**Constraints**: Local-first, no `media_kit` `Player()` outside player engine, no `print()`, feature-first architecture, ARB localization for user-facing strings

**Scale/Scope**: One new fetcher class (~200 lines), one profile model (~60 lines), one profile provider (~80 lines), modified repository (~200 lines changed), modified API client interface (~40 lines added)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### I. Architecture and Code Quality

- All new code lives under `lib/features/transcript/data/` (fetcher, profiles) and `lib/features/transcript/application/` (profile provider).
- Worker API changes stay in `lib/data/api/services/ai/` (existing location for `YoutubeTranscriptsClient`).
- Domain models (`TranscriptLine`, `TranscriptTrack`, `TranscriptFetchStatus`) remain UI-free.
- Persistence continues through Drift DAOs (`transcriptDao`, `settingsDao`).
- Riverpod used for profile caching and fetch orchestration.
- No `media_kit` involvement, no `print()` calls (use `logNamed`).
- **PASS**

### II. Testing Defines the Contract

Automated tests required:
- `YoutubeCaptionFetcher` unit tests: profile fallback, track selection, json3 parsing, entity/tag cleaning, error handling
- `ClientProfileProvider` unit tests: fetch, cache, refresh, built-in fallback
- `TranscriptRepository` unit tests: fallback chain (local → worker → direct), upload after direct fetch, bilingual handling
- `YoutubeTranscriptsApi` unit tests: GET cache, POST upload methods
- `TranscriptFetchCtrl` unit tests: updated `resolveOnOpen` flow with new chain

If behavior cannot be automated: the InnerTube endpoint is a public API that can be called from test environments; no manual-only testing needed for core logic.

- **PASS**

### III. User Experience Consistency

- User-facing strings: "no transcript available", retry label, status messages — all go through ARB localization.
- Shared UI patterns: transcript panel, subtitle track picker, and loading indicators reuse existing widgets.
- Haptics/tooltips: no new tappable controls introduced by this feature.
- `docs/features/youtube.md` and `docs/features/transcript.md` updated.
- **PASS**

### IV. Performance Is a Requirement

- Direct fetch: ≤5s for video with available captions on good network.
- Local re-open: ≤500ms (Drift read from in-memory cache).
- Worker cache hit: ≤2s.
- Fallback chain total: ≤15s or timeout.
- Transcript parsing for 5,000+ lines: offloaded via `compute()` (separate isolate).
- Profile fetch: non-blocking, async at startup.
- Upload: fire-and-forget, never blocks UI.
- **PASS**

### V. Documentation and Traceability

- New ADR: `docs/decisions/0043-client-youtube-transcripts.md`
- Updated: `docs/features/youtube.md`, `docs/features/transcript.md`
- Spec + plan in `specs/013-client-yt-transcripts/`
- No constitution exceptions needed.
- **PASS**

## Project Structure

### Documentation (this feature)

```text
specs/013-client-yt-transcripts/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   ├── youtube-innertube-api.md
│   └── worker-cache-api.md
└── tasks.md             # Phase 2 output (/speckit-tasks)
```

### Source Code (repository root)

```text
lib/
├── features/transcript/
│   ├── application/
│   │   ├── client_profile_provider.dart       # NEW: profile fetch/cache/refresh
│   │   ├── transcript_fetch_controller.dart   # MODIFY: rewire resolveOnOpen
│   │   └── transcript_repository_provider.dart # MODIFY: inject new dependencies
│   ├── data/
│   │   ├── client_profile.dart                # NEW: model + built-in defaults
│   │   ├── youtube_caption_fetcher.dart        # NEW: direct YouTube InnerTube fetch
│   │   ├── transcript_repository.dart          # MODIFY: fallback chain, upload flow
│   │   └── transcript_timeline_parse.dart      # MODIFY: support json3 format
│   └── domain/
│       └── transcript_fetch_status.dart        # MODIFY: add fetchSource enum
├── data/api/services/ai/
│   ├── youtube_transcripts_api.dart            # MODIFY: add GET/upload/profile methods
│   └── ai_api_providers.dart                   # MODIFY: new providers
├── data/db/
│   └── settings_keys.dart                      # MODIFY: add client_profiles key
└── core/utils/
    └── html_clean.dart                         # NEW: entity decode + tag strip helpers

test/
├── features/transcript/
│   ├── data/
│   │   ├── youtube_caption_fetcher_test.dart   # NEW
│   │   └── client_profile_test.dart            # NEW
│   ├── application/
│   │   └── client_profile_provider_test.dart   # NEW
│   ├── transcript_repository_fallback_test.dart # NEW
│   └── transcript_fetch_controller_test.dart   # MODIFY
├── data/api/services/ai/
│   └── youtube_transcripts_api_test.dart       # MODIFY
└── core/utils/
    └── html_clean_test.dart                    # NEW

docs/
├── features/youtube.md                         # MODIFY
├── features/transcript.md                      # MODIFY
└── decisions/0043-client-youtube-transcripts.md # NEW
```

**Structure Decision**: New fetcher logic stays in `lib/features/transcript/data/` since it's a data-source concern of the transcript feature. Profile configuration lives alongside the fetcher. API contract changes are minimal additions to the existing `YoutubeTranscriptsClient` interface in `lib/data/api/`. Worker-specific API methods extend the existing `YoutubeTranscriptsApi`.

## Complexity Tracking

No constitution violations. No justification needed.
