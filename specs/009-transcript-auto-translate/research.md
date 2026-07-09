# Research: Transcript Auto-Translate

**Feature**: [spec.md](./spec.md) · **Plan**: [plan.md](./plan.md)

All open questions from Technical Context are resolved below. No
`NEEDS CLARIFICATION` markers remain.

---

## R1 — Persist as an `ai` transcript track (not ephemeral-only)

**Decision**: Store auto-translated cues as a durable `Transcripts` row with
`source: 'ai'`, `language` = target reading language (profile native), and
`timelineJson` aligned 1:1 with the primary cue timings. Set
`echo_sessions.secondaryTranscriptId` to that row’s id when Auto translate is
selected.

**Rationale**: Spec FR-009/FR-010 require persist + resume. The schema already
allows `source: 'ai'` and the picker already badges it (`subtitlesProviderAi`),
but nothing writes `ai` today — this feature owns that path. Reusing
`secondaryTranscriptId` means the existing transcript list /
`TranscriptSecondaryMatcher` path renders translations with no parallel display
pipeline. Deterministic id via `enjoyTranscriptId(..., language, 'ai')` upserts
in place across sessions.

**Alternatives considered**:
- **Ephemeral in-memory only** — fails reopen / credit-saving requirements.
- **New Drift table for translated lines** — more migration + dual render paths;
  rejected while `Transcripts` already fits.
- **Reuse YouTube native caption as “auto”** — different product (fetched
  captions vs generated from primary text); Auto translate remains a separate
  option (spec assumption).

---

## R2 — Line skeleton + progressive fill (matcher-safe)

**Decision**: When Auto translate starts (or resumes), ensure the AI track’s
`timelineJson` has **one entry per primary line**, copying each primary
`startMs` / `durationMs`. `text` is empty until that line succeeds; the UI
treats empty secondary text as pending (when the Auto translate job is active)
and non-empty as ready. Persist after each successful line (or small batch) via
`TranscriptDao.upsert`.

**Rationale**: `TranscriptSecondaryMatcher` matches by time, not index. Sparse
timelines cause wrong fallback attachments. A full skeleton keeps alignment
correct while still allowing progressive display.

**Alternatives considered**:
- **Append-only completed lines** — breaks matcher for gaps; rejected.
- **Index-based overlay bypassing matcher** — duplicates list plumbing; only
  needed if timings diverge; rejected for v1 because we copy primary timings.

---

## R3 — Scheduler: priority queue, low concurrency, bounded retry

**Decision**: New application controller `AutoTranslateCtrl` (Riverpod
`@Riverpod` / keepAlive family keyed by `mediaId`), modeled after
`TranscriptFetchCtrl` patterns (`_inFlight` coalescing, hydrate-from-DB,
friendly UI state). Behavior:

| Concern | Choice |
|---------|--------|
| API | Existing single-line `translationServiceProvider.translate(...)` |
| Priority | Distance from current playback cue index (then viewport hint if available); re-rank on seek |
| Concurrency | Cap at **2** in-flight line requests |
| Retry | Per-line: up to **3** attempts, exponential backoff (e.g. 1s → 2s → 4s), jitter optional |
| Credits / auth | Map via `guardAiCall`; stop scheduling new lines on `AuthFailure` / `CreditsFailure` with calm job-level status |
| Debounce seeks | Re-prioritize without cancelling in-flight successes; do not stampede |

**Rationale**: No batch translate API exists. Lookup already proves the single-line
contract. Fetch controller is the closest “long background job + UI state”
template; lookup sections prove auth/credits UX.

**Alternatives considered**:
- **Translate entire transcript in one LLM prompt** — different capability,
  worse latency/cost control, harder resume; out of scope.
- **Unlimited parallel requests** — risk of rate limits, jank, credit spikes.
- **Translate only on tap** — contradicts spec “lazy background fill.”

---

## R4 — Picker UX: dedicated Auto translate option + Re-translate

**Decision**:
1. In the translation `RadioGroup`, after **None**, add an **Auto translate**
   option tile (distinct from track rows; no delete on the virtual row).
2. Selecting it: eligibility checks → ensure/create AI track →
   `setSecondaryTranscript(mediaId, aiTrackId)` → start/resume scheduler.
3. When the AI track already exists, selecting Auto translate points secondary
   at that id (same as selecting the AI row if shown). Prefer **filtering the
   AI track out of the generic track list** *or* treating Auto translate as the
   canonical selector for `source: 'ai'` so learners are not shown two
   competing rows for the same artifact — implementation picks one consistent
   presentation (recommended: Auto translate tile is the selector; AI row is
   hidden from the translation list to avoid duplication).
4. **Re-translate** appears only when Auto translate is the active secondary
   selection (actions section or tile trailing control); confirm when the job
   is largely complete / large line count (QR-007).

**Rationale**: Spec FR-001/FR-014/FR-016 and SC-001/SC-006. Existing
`NoneOptionTile` / `TrackOptionTile` split is the right extension point
(`subtitle_track_picker_sheet.dart` + tiles module).

**Alternatives considered**:
- **Only show AI track after first run** — weak discoverability for first-time
  Auto translate.
- **Always show both Auto translate tile and AI track** — confusing duplicate
  selection; avoid unless product insists.

---

## R5 — Target language & eligibility

**Decision**: Target = `AppPreferencesState.effectiveNativeLanguage` (read in
the controller, not the repository). Source = active primary track language.
Strip with `workerLanguageBase` for the translate API. Block when:

- signed out → `AuthRequiredCallout`-style guidance;
- no primary / empty timeline → friendly unavailable;
- `workerLanguageBase(source) == workerLanguageBase(target)` → explain, no
  requests;
- native missing → guide to profile language settings.

**Rationale**: Matches ADR-0036 bilingual intent and lookup translation
conventions (ADR-0019). Keeps repository UI-free.

**Alternatives considered**:
- **Per-job language picker in v1** — useful later; spec Assumptions defer it.
- **Use learning language as target** — wrong for “read along in my language.”

---

## R6 — Primary change / stale translation invalidation

**Decision**: Store `referenceId` on the AI row as the **primary transcript id**
used as the translation source, plus a cheap **content fingerprint** (e.g. hash
of primary line count + concatenated startMs + text lengths, or full text hash
for shorter transcripts) in `label` metadata or a dedicated convention
documented in data-model. On Auto translate select / resume:

- if `referenceId` ≠ current primary id → rebuild skeleton + reschedule (or
  require Re-translate with clear copy);
- if fingerprint mismatch → same.

Re-translate clears texts (or rebuilds skeleton) and resets per-line retry
state; newer job generation id wins if a prior run is still draining.

**Rationale**: FR-015 and User Story 5. Avoids silently wrong bilingual pairs.

**Alternatives considered**:
- **Ignore staleness** — violates FR-015.
- **Schema column for fingerprint** — cleaner long-term; defer migration unless
  encoding in `referenceId`/`label` proves fragile (v1 prefers no migration).

---

## R7 — Schema migration

**Decision**: **No Drift schema migration for v1.** Reuse `Transcripts` +
`EchoSessions`. Job progress is derived from empty vs non-empty AI line texts
plus in-memory controller state; job-level errors live in controller UI state
(optionally mirrored later).

**Rationale**: Constitution prefers minimal surface; existing tables suffice
(R1/R2). A future ADR may add `auto_translate_jobs` if we need durable
job-level errors across process death beyond “empty lines remain pending.”

**Alternatives considered**:
- New job/line-status tables — stronger observability; deferred to keep v1
  shippable without migration risk.

---

## R8 — Coexistence with YouTube bilingual captions

**Decision**: Auto translate does **not** replace or disable YouTube bilingual
fetch. If a native translation track already exists, it remains selectable.
Auto translate remains available when the learner wants generated translation
from the **current primary text** (or when no suitable track exists). Selecting
Auto translate switches secondary to the AI track; selecting the YouTube
translation track switches away (FR-013).

**Rationale**: Spec Assumptions + ADR-0036.

---

## R9 — Documentation / ADR

**Decision**: Update `docs/features/transcript.md` (remove Future bullet for
auto-translate; document picker + job behavior). Add **ADR-0037** (next free
number after 0036) for: AI-track persistence, progressive skeleton, scheduler
priorities, and primary-staleness rules — costly to reverse.

**Rationale**: Constitution V + QR-005.

---

## R10 — Testing strategy

**Decision**:
- **Unit**: priority ordering, retry/backoff, skeleton build, staleness checks,
  eligibility gates (pure Dart).
- **Unit/repository**: upsert AI track, set secondary, progressive timeline
  merge, reopen resume (empty vs filled).
- **Widget**: picker shows Auto translate + Re-translate affordance; selection
  wires secondary; friendly blocked states.
- **Manual**: long-transcript playback smoothness (SC-003/SC-008) — automate
  only if a cheap fake translator harness exists.

**Rationale**: Constitution II; matches prior transcript feature test layout.
