# Contract C2: Craft save blank transcript

## CraftController save

| Condition | Action |
|-----------|--------|
| `previewWordBoundaries` non-empty and segmenter returns ≥1 segment | `primaryTimelineJson = segmentsToTimelineJson(segments)` |
| Otherwise | Pass **null** / omit timeline; **do not** call `encodeTimelineJson` / `estimateTimeline` |

Save must still succeed when timeline is omitted (audio written).

## `MediaLibraryRepository.importCraftedFromText`

| `primaryTimelineJson` | Behavior |
|-----------------------|----------|
| Non-null non-empty JSON array of lines | Insert `TranscriptRow` `source: 'ai'` with that `timelineJson` |
| `null` (blank) | Insert `AudioRow` only; **no** primary transcript insert; **no** `{text, start:0, duration:0}` fallback |

Signature may keep optional `String? primaryTimelineJson`; semantics of `null` change from “fallback single line” to “blank”.

## `MediaLibraryRepository.updateCraftedFromText`

| Timeline | Behavior |
|----------|----------|
| Solid JSON | Upsert primary AI transcript as today |
| Blank (`null`) | Update audio fields; **delete** transcript rows for this `Audio` target (or all tracks for target—prefer delete all for that mediaId to avoid stale AI cues) |

## Invariants

- `provider` / `source` flags unchanged.
- Blank is not an error and must not surface `CraftSaveFailure` solely due to missing timings.
- Dedupe-on-create unchanged when content hash matches (may return old item that still has estimated cues—retro-migration out of scope).

## Tests (contract-level)

1. Import with `null` timeline → audio exists; `listForTarget` transcripts empty.
2. Update solid → blank → transcripts empty; audio uri updated.
3. Import with solid JSON → one AI transcript; first line does not start with `.`
