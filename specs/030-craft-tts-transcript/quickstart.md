# Quickstart validation: Craft TTS Transcript Quality

**Feature**: `030-craft-tts-transcript`  
**Contracts**: [contracts/README.md](./contracts/README.md) · **Data model**: [data-model.md](./data-model.md)

## Prerequisites

- Signed-in Enjoy account with TTS credits (Enjoy default Azure path)
- Device/OS that can return Azure word timings for a solid-path check (Android or Windows recommended)
- Second check on iOS/macOS **or** OpenAI BYOK TTS for blank-path check
- ASR configured so player Generate transcript works for local audio

## Automated (preferred)

```bash
cd /home/an-lee/projects/enjoy_player
flutter test test/features/craft/domain/word_boundary_segmenter_test.dart
# plus any new controller/repo tests added for blank-vs-solid
flutter analyze
bash .github/scripts/validate_ci_gates.sh --fix
```

**Expect**: Segmenter tests cover standalone `.` tokens (no leading punct lines), sentence preference, and solid gate; repo/controller tests prove `null` timeline → no transcript row.

## Manual status (implement)

Automated gates above are green on `030-craft-tts-transcript`. Manual A–D
below were **not** executed in the implement session (no device matrix);
verify on Android/Windows (solid) and iOS/macOS or OpenAI BYOK (blank) before
release.

## Manual A — Solid cues (word timings)

1. Open Craft → Advanced (or Express through to audio) on Android/Windows.
2. Synthesize a short multi-sentence paragraph with clear `.` / `?` punctuation (≥2 sentences).
3. Save / Practice now.
4. Open transcript panel.

**Expect**:
- Multiple timed lines; no line starts with `.` `?` `!` alone.
- Line ends align with sentence ends for well-punctuated text.
- Wording matches the synth/practice text (not an ASR rewrite).

## Manual B — Blank when not solid

1. Craft save on a path without word timings (iOS/macOS Enjoy TTS, or OpenAI BYOK TTS).
2. Open the new library item.

**Expect**:
- Audio plays.
- Transcript panel shows **empty / Generate** state (no fake full-duration or proportional cues).
- Tap Generate → ASR completes → timed transcript appears; audio unchanged.

## Manual C — Replace solid cues via STT

1. From Manual A item, open subtitle/transcript controls → Generate / replace via ASR.
2. Confirm new cues replace practice track per existing ASR rules.
3. Optionally force an ASR failure (offline) and confirm prior synthesis cues remain.

## Manual D — Discoverability

1. Blank item: empty state Generate is obvious without Settings.
2. If snackbar hint shipped for solid saves: appears once; does not auto-run ASR.

## Performance spot-check

- Note Craft save time for ~300-character text before/after; regression should feel negligible (≤10% if measured).

## Out of scope checks (must not appear)

- No forced-alignment UI or copy.
- No automatic STT on every Craft save.
- No Deepgram TTS switch as part of this feature.
