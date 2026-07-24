# Contract C3: STT discoverability for Craft

## Blank Craft media

- Player `transcriptLinesForMediaProvider` yields empty list.
- `TranscriptPanel` shows `TranscriptEmptyState` with **Generate** enabled for local (non-YouTube) media via existing `launchAsrGeneration`.
- No Craft-specific empty widget required if generate already shows for local audio.

## Solid Craft media (replace path)

- Existing subtitle/track picker **Generate** remains available for local media (same as other library audio).
- Optional: after Craft save that wrote a solid transcript, show a **once-per-session** (or until-dismissed) localized snackbar/banner:
  - Message: timings can be regenerated with speech-to-text from the transcript panel if cues look wrong.
  - Must **not** auto-start ASR or imply re-synthesis.

## Failure preservation

- ASR failure leaves prior solid transcript intact; blank stays blank (existing ASR UX).

## Localization

- New hint strings in `app_en.arb` / `app_zh.arb` / `app_zh_CN.arb` if snackbar ships.
- Reuse existing empty-state generate labels where possible.

## Non-goals

- Auto-STT on Craft save
- Forced-alignment marketing copy
- New Settings → Craft toggle for v1
