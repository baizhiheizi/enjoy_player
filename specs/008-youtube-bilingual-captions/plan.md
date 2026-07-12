# Implementation Plan: YouTube Bilingual Captions

**Branch**: `main` (work on a feature branch `008-youtube-bilingual-captions`) | **Date**: 2026-07-09 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/008-youtube-bilingual-captions/spec.md`

## Summary

Fetch a YouTube video's original-language caption **and** a caption translated
into the signed-in learner's native language in a **single** worker request, then
store the original as the **primary** transcript and the translation as the
**secondary** transcript so both appear automatically. The worker's
`POST /youtube/transcripts` endpoint now accepts a `languages` array (first entry
= source, rest = translation targets) and returns a `transcripts[]` list (with a
`partial` status when some are missing). The Flutter client adopts the worker's
`wait_ms` server-side long-poll to replace the fixed 2 s × 30 client sleep loop,
cutting request count per video several-fold while keeping time-to-first-caption
at parity. No DB schema change is required: `EchoSessions.secondaryTranscriptId`,
`Transcripts`, and `TranscriptFetchStates` already support multi-track storage.

## Technical Context

**Language/Version**: Dart ^3.12.0, Flutter stable (channel stable), Riverpod 3.x
(`flutter_riverpod` ^3.3.1, `riverpod_annotation` ^4.0.2).

**Primary Dependencies**:
- `http` ^1.4.0 (requests via `ApiClient`, which auto-converts camelCase↔snake_case).
- `drift` ^2.31 / `drift_flutter` ^0.2.8 (DAOs on `AppDatabase`).
- `logging` ^1.3.0 via `logNamed` (no `print()`).
- `flutter_inappwebview` (YouTube playback — unchanged by this feature).

**Storage**: Drift `AppDatabase`. Affected DAOs/tables: `transcriptDao`
(`Transcripts`), `echoSessionDao` (`EchoSessions`, incl. `secondaryTranscriptId`),
`transcriptFetchStateDao` (`TranscriptFetchStates`). **No schema migration.**

**Testing**: `flutter test` — unit tests for language-pair selection, request
body building, multi-language response parsing (`ready`/`partial`/`generating`/
`failed`), primary/secondary assignment, and the new long-poll loop. Repository
tests use a fake `YoutubeTranscriptsClient`. `dart run build_runner build` is
**not** required (no new `@riverpod`/Drift annotations are mandatory for the
core change — see Research for the one optional provider touch).

**Target Platform**: Android, iOS, macOS, Windows. No Flutter web.

**Project Type**: Flutter native mobile/desktop app.

**Performance Goals**:
- Time-to-first-caption for the **original** caption MUST NOT regress beyond a
  small constant versus today's single-caption fetch (target: within ~10% of the
  pre-change median on a given video).
- Total transcript **requests per video** MUST drop from the current ~up-to-30
  fixed-interval polls toward ≤ a handful by using server-side `wait_ms` and the
  `Retry-After` header.
- Reopen of an already-fetched video: **0** transcript requests (unchanged).
- Dual-caption transcript scroll: no dropped frames on long videos; large
  payloads already decode off the main isolate via `ApiClient.compute`.

**Constraints**:
- Local-first; cloud/bilingual fetch only when signed in.
- Single `media_kit` player rule and YouTube-WebView rule are untouched.
- The repository layer stays UI-free; the native language is **passed in** as a
  parameter, not read from widgets/providers inside the repo.
- Backward compatible with worker deployments: the single-language path
  (`language:`, flat response, Apify fallback) is preserved for the
  source-only case so the Apify fallback is **not** lost.

**Scale/Scope**: Library of many YouTube videos; each video may carry 1–2 cloud
caption tracks plus local/sidecar/embedded tracks. Transcripts up to multi-thousand
lines; dual timelines double per-item work in list builders (kept off the build
hot path by the existing line model).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Post-design re-check (after Phase 0 + Phase 1):** ✅ PASS — no changes. The
design confirms: no DB migration (persistence stays in Drift DAOs); the
repository stays UI-free with the native language injected as a parameter; no
new providers/singletons are required; large payloads decode off the main
isolate via the existing `ApiClient` path; and docs + ADR updates are scheduled.
No Constitution exception is needed.

### I. Architecture and Code Quality

- ✅ All changes stay inside the existing feature/data boundaries:
  - `lib/data/api/services/ai/youtube_transcripts_api.dart` (API contract).
  - `lib/features/transcript/data/transcript_repository.dart` (orchestration).
  - `lib/features/transcript/application/transcript_fetch_controller.dart`
    (read `effectiveNativeLanguage` inside the shared `_runResolve` helper and
    forward it to the repository — a single read site that covers both the
    open path and the manual "refresh from cloud" path, FR-010).
    `lib/features/player/application/player_open_side_effects.dart` is **unchanged**
    (it already passes `signedIn`; the native-language read now lives in the
    controller, which still keeps the repository UI-free).
  - `lib/core/application/app_language_catalog.dart` (`workerLanguageBase`) is
    reused; no new cross-feature shortcut.
- ✅ Domain models stay UI-free; persistence flows through Drift DAOs.
- ✅ Riverpod remains the orchestration mechanism; no new mutable global
  singleton. (Native language is read from the existing
  `appPreferencesCtrlProvider` **inside the controller's `_runResolve` helper** —
  the single shared path used by both `resolveOnOpen` and `refreshFromCloud` —
  and passed down as a parameter, so the refresh route is never starved of it.)
- ✅ No `print()`; logging via `logNamed`. No new `media_kit` `Player()`.

### II. Testing Defines the Contract

Required automated tests:
- **Unit (API client)**: the multi-language method sends `languages`,
  `captionFetch`, `forceRefresh`, `waitMs` with the correct (camelCase) keys.
- **Unit (repository)**:
  - language-pair selection: source only when `source == native` or native
    unknown; `[source, native]` otherwise (deduped, base codes).
  - `ready` with 1 and 2 transcripts → stores rows + assigns primary/secondary.
  - `partial` (missing translation) → stores original, sets primary, leaves
    secondary unset, returns **success** (not error). Also test the
    **source-missing** partial (only the translation ready): stores the
    translation, sets NO primary from a non-existent source row (falls back to
    the existing primary sort), returns **success**.
  - `generating` → polls again; `failed` → records error outcome, keeps any
    stored tracks.
  - long-poll: uses `waitMs` on each request and respects `Retry-After`.
- **Unit (fetch controller)**: native language is threaded from preferences into
  the repository only when signed in — for **both** entry points
  (`resolveOnOpen` on open AND `refreshFromCloud` on manual cloud refresh), since
  they share `_runResolve`. This is the explicit coverage for FR-010.
- No `build_runner` run is required for the minimal change; if an optional
  provider parameter is added via annotation, run `dart run build_runner build`.

### III. User Experience Consistency

- ✅ No new user-visible strings are required for automatic primary/secondary
  assignment (existing `subtitlesPrimary` / `subtitlesTranslation` labels apply).
  Any added label must live in ARB files.
- ✅ Both tracks remain selectable in the existing subtitle picker; no new
  tappable primitives are introduced. Haptics/tooltips/keyboard affordances are
  unchanged.
- 📝 `docs/features/youtube.md` (Transcripts section) and
  `docs/features/transcript.md` will be updated to describe bilingual fetch.

### IV. Performance Is a Requirement

- ✅ Performance budget stated above (request-count reduction, time-to-caption
  parity, 0-request reopen).
- ✅ Large dual-timeline payloads decode off the main isolate (existing
  `ApiClient.compute` path for >48 KB). No heavy work in list item builders.
- ✅ QR-006 / SC-006 dual-caption scroll responsiveness is explicitly verified
  across all platforms in task T035 (long-video frame-timing check).

### V. Documentation and Traceability

- 📝 Update `docs/features/youtube.md` and `docs/features/transcript.md`.
- ✅ **MUST** create an ADR recording the multi-language worker contract adoption
  and the polling-strategy decision (long-poll now; ETag/SSE deferred). Per
  Constitution V, the polling-strategy and always-vs-conditional-multi-path
  decisions are architectural, non-obvious, and costly to reverse/rediscover, so
  an ADR is **required** (not optional). Finalised in task T030.
- No constitution exception required.

## Project Structure

### Documentation (this feature)

```text
specs/008-youtube-bilingual-captions/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit-tasks — NOT created here)
```

### Source Code (repository root)

```text
lib/
├── data/
│   └── api/services/ai/
│       └── youtube_transcripts_api.dart        # add multi-language + wait_ms
├── core/
│   └── application/app_language_catalog.dart   # reuse workerLanguageBase
└── features/
    ├── transcript/
    │   ├── data/transcript_repository.dart     # bilingual fetch + assignment
    │   └── application/transcript_fetch_controller.dart  # read native lang in _runResolve
    └── player/
        └── application/player_open_side_effects.dart    # UNCHANGED (passes signedIn only)

test/
├── features/transcript/
│   ├── transcript_repository_multi_lang_test.dart
│   └── transcript_fetch_controller_native_lang_test.dart
└── data/api/services/ai/
    └── youtube_transcripts_api_test.dart

docs/
├── features/youtube.md          # update Transcripts section
├── features/transcript.md       # update bilingual behavior
└── decisions/0036-youtube-bilingual-transcripts.md   # required ADR (T030)
```

**Structure Decision**: No new modules, tables, or providers are required. The
change is additive inside the existing transcript data + application layers and
the worker AI API service, exactly matching the feature-first layout. The native
language is read inside the controller's shared `_runResolve` helper (which both
`resolveOnOpen` and `refreshFromCloud` call) and threaded down as a parameter,
keeping the repository a pure data orchestrator with no UI/provider coupling —
and guaranteeing the manual-refresh path (FR-010) sees the same native language.

## Complexity Tracking

> No Constitution Check violations require justification. Table left empty by
> design.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| _(none)_  | —          | —                                   |
