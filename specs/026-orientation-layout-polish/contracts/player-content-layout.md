# Contract: Player Video + Transcript Content Layout

**Feature**: 026-orientation-layout-polish  
**Consumers**: `VideoPlayerLayout`; widget tests  
**Pure API** (name indicative): `usePlayerSideBySideLayout({required double width, required double height})`

## Predicate

```text
usePlayerSideBySideLayout(width, height) → bool
```

| Inputs | Result | Layout |
|--------|--------|--------|
| `width > height` | `true` | side-by-side (Row: video \| transcript) |
| `width <= height` | `false` | stacked (Column: video above transcript) |

Call site MUST pass **layout constraints** (`constraints.maxWidth` / `constraints.maxHeight`) from `VideoPlayerLayout`’s `LayoutBuilder`, not a stale cached size.

## Explicit non-inputs

The following MUST NOT decide stack vs side-by-side:

- `EnjoyThemeTokens.breakpointTranscriptSideBySide` (720) — still used elsewhere (e.g. transport bar packing)
- Device form factor (phone/tablet/desktop)
- Media type alone (YouTube vs local) — same rule when both video stage and transcript are shown

## Invariants across layout switches

- Active `PlayerEngine` / session MUST remain the same instance across predicate flips.
- In-memory transcript split width (`_transcriptWidthPx`) SHOULD survive rebuilds; when side-by-side becomes active again, width is re-clamped to `[min, max]` for the new total width.
- Stacked layout keeps the existing 16:9 video stage behavior.
- Side-by-side keeps existing splitter min (**360** logical px, capped by max fraction) and commit callback to persisted `splitPx`.

## Acceptance fixtures (widget tests)

| Surface (W×H) | Expect |
|---------------|--------|
| 900×600 | side-by-side |
| 800×1000 | stacked (wide portrait; formerly would be side-by-side at 720 gate) |
| 700×400 | side-by-side (landscape below 720 width) |
| 600×600 | stacked |
| 500×700 | stacked |
