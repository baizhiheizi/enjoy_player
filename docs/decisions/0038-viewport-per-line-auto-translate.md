# ADR-0038 — Viewport-driven per-line auto-translate

**Status**: Accepted  
**Date**: 2026-07-09

**Supersedes**: [ADR-0037](0037-transcript-auto-translate.md) orchestration model (media-wide lazy scheduler). Persistence shape (`source: ai` track, skeleton timeline, picker order, per-line re-translate) from ADR-0037 remains. Display identity for AI cues is defined in [ADR-0039](0039-auto-translate-primary-text-keyed-overlay.md).

## Context

ADR-0037 introduced Auto translate as a media-scoped background job that swept pending lines with playback-priority scheduling, pause/resume on media close, and circuit-breaker job status. That was more complex than needed: learners only need translations for cues they can see, and finished lines already persist in Drift.

## Decision

1. **Setup only on select** — `selectAutoTranslate()` ensures the AI secondary track and sets `secondaryTranscriptId`. It does not start a full-file translate job.

2. **Viewport / build-driven requests** — The transcript list (and echo region) calls `requestTranslateLine(index)` when a built row has empty AI text. `ListView.builder` + `scrollCacheExtent` define which lines are eligible; no visibility package.

3. **Per-line concurrency** — Cap at **2** in-flight calls per media. Idempotent requests skip cached, in-flight, and failed lines. One quiet retry, then mark the line failed until explicit re-translate.

4. **No close/reopen job lifecycle** — Closing media does not pause a daemon; reopening shows cached Drift text and requests only empty lines that enter the viewport again.

## Consequences

**Positive**

- Fewer wasted API calls on long transcripts
- Simpler controller (no scheduler loop / session resume)
- Cache behavior unchanged for already-translated lines

**Trade-offs**

- Lines outside the list cache extent stay empty until scrolled into view
- Manual scroll while paused is the primary way to fill distant cues
