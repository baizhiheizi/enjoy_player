<hash>size:28908</hash>

# `docs/features/transcript.md`

- Defines transcript behavior for imported SRT/VTT, cloud and YouTube captions, AI ASR, lookup, auto-translate, blur practice, and echo-region rendering.
- `watchTracks` uses value equality and stream dedupe so unchanged Drift emissions do not rebuild consumers.
- Current line UI keeps 16 px horizontal padding; desktop/mobile density changes vertical padding, list gaps, typography height, and echo controls.
- Active cues use a 3 px rail; secondary text uses an inset border; accessibility combines timing, cue text, state, and recording count.
- Auto-translate requests viewport lines lazily with bounded concurrency and persists results in Drift.
