# Research: Craft TTS Transcript Quality

**Feature**: `030-craft-tts-transcript` | **Date**: 2026-07-24

## R1 — Solid vs blank gate

**Decision**: Solid = non-empty `previewWordBoundaries` **and** `segmentWordBoundaries(...)` returns ≥1 segment with non-empty text. Otherwise Craft save passes **no** primary timeline (blank transcript).

**Rationale**: Matches clarification session; avoids saving empty JSON that still creates a confusing `source: ai` row; empty player state already routes to STT.

**Alternatives considered**:
- Duration/`estimateTimeline` multi-line fallback — rejected (spec: fabricated cues worse than none).
- Save `timelineJson: []` row — weaker (orphan AI track, sync noise); prefer omit/delete row.
- Forced alignment — deferred.

## R2 — Leading punctuation / sentence breaks

**Decision**: Preprocess word boundaries before (or inside) `segmentWordBoundaries`:
1. Merge punctuation-only tokens onto the **previous** word’s text (or next word only if first token—prefer previous).
2. Flush on sentence-end punctuation attached to a word **or** after merge.
3. Prefer sentence flush over `preferredWordsPerSegment` when a sentence end is available; keep word-count chunks only inside long sentences.

**Rationale**: Azure WordBoundary emits punctuation as separate events; current 6-word flush can start a line with `.`.

**Alternatives considered**:
- Rely on Azure SentenceBoundary SDK events — incomplete on iOS/macOS plugin; adds platform work out of scope.
- SSML bookmarks — more invasive; not required for v1.

## R3 — Stop Craft estimator on save

**Decision**: Remove `encodeTimelineJson` / `estimateTimeline` / `wavDurationMs` fallback from `CraftController` save path. Leave `transcript_timestamp_estimator.dart` only if other callers exist; otherwise mark unused / delete in implementation if safe.

**Rationale**: Spec FR-004; estimator was the source of single-line and fake multi-line cues on Apple/OpenAI paths.

**Alternatives considered**: Keep estimator behind a debug flag — rejected (product wants blank + STT).

## R4 — Library import/update blank semantics

**Decision**:
- `importCraftedFromText`: when `primaryTimelineJson == null` (or new explicit `omitPrimaryTranscript: true`), insert **audio only**—do **not** insert a primary `TranscriptRow`, and do **not** fall back to `[{text, start:0, duration:0}]`.
- `updateCraftedFromText`: when blank, **delete** existing transcript rows for that target (or at least the primary learning-language AI track) so the player sees empty lines / empty state.
- When solid, write `timelineJson` from segmenter as today (`source: 'ai'`).

**Rationale**: Today’s repository always upserts a transcript with a single-line fallback—that conflicts with FR-004/FR-011. `transcriptLinesForMediaProvider` + `TranscriptEmptyState` already handle empty lines with generate for local audio.

**Alternatives considered**:
- Soft-empty `[]` timeline — rejected for sync/identity clarity.
- Store practice text as untamed single cue — rejected (same as estimator).

## R5 — STT discoverability

**Decision**:
- **Blank items**: rely on existing `TranscriptEmptyState` generate button (`showGenerateButton` for local media)—primary CTA; no mandatory new Craft-only empty UI.
- **Solid synthesis cues**: optional brief snackbar/banner after successful Craft save (or on audio stage) with ARB copy pointing to subtitle/transcript generate/replace; dismiss once per session or until dismissed (SharedPreferences or in-memory session flag—prefer session-first to minimize prefs surface).
- Do **not** auto-launch ASR after save.

**Rationale**: Spec US2/US4; empty state already exists; avoid spamming settings.

**Alternatives considered**:
- Auto-STT on save — out of scope / costs credits unexpectedly.
- New Craft settings toggle — unnecessary for v1.

## R6 — Documentation / ADR

**Decision**: Add **ADR-0063** documenting blank-when-not-solid and removal of Craft duration estimation as default transcript source. Update `docs/features/craft.md` (word-segmented transcript section + blank/STT path). Fix stale claims about secondary tracks if still wrong.

**Rationale**: Constitution V; reverses prior Craft import behavior (estimator fallback in controller).

## R7 — Platforms & BYOK

**Decision**: No iOS/macOS Azure WordBoundary plugin work in this feature. Those platforms (and OpenAI BYOK TTS) take the blank→STT path until a later platform or FA effort.

**Rationale**: Spec out of scope for Linux/Apple boundary wiring; product explicitly chose blank over fake cues.

## Open items for tasks (not blockers)

- Confirm no non-Craft production callers of `estimateTimeline` / `encodeTimelineJson` before delete.
- Exact ARB key names and whether hint appears on Express “Practice now” vs Advanced save only (default: any successful Craft save that wrote a solid transcript).
