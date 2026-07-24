# Contract C1: Craft transcript builder

## Inputs

- Ordered `List<CraftWordBoundary>` (`text`, `audioOffsetMs`, `durationMs`)
- Optional `preferredWordsPerSegment` (default 6)

## Preprocess (punctuation merge)

1. Walk tokens in order.
2. If `text` is punctuation-only (trim matches `RegExp(r'^[.。！？!?]+$')` or broader punct class agreed in tasks):
   - Append to previous token’s `text` when a previous token exists.
   - Else drop or attach to following token (must not create a segment that starts with punct-only).
3. Preserve timing: merged punct does not invent a new segment start; duration may extend previous token’s end if needed for flush math (implementation chooses: keep previous duration vs extend to punct token end—prefer **extend end to punct token’s end** so silence after sentence stays with prior line).

## Segment

1. Prefer flush when previous (merged) token ends a sentence (`[.。！？!?]\s*$`).
2. Else flush when current segment word count ≥ `preferredWordsPerSegment` **and** the next token is not punctuation-only (already merged).
3. Join segment texts with a single space for space-delimited languages; do not invent STT wording.
4. `startMs` = first token offset; `durationMs` = lastEnd − start.

## Solid gate

```text
solid = boundaries.isNotEmpty && segments.isNotEmpty
```

If not solid → caller must treat as blank (no `timelineJson`).

## Output JSON

```json
[
  { "text": "Hello world.", "start": 0, "duration": 900 },
  { "text": "How are you?", "start": 1000, "duration": 800 }
]
```

## Non-goals

- Duration estimation from plain text
- Azure SentenceBoundary / SSML bookmarks
- CJK-specific joiners beyond “no leading punct” (space-join residual OK for v1)
