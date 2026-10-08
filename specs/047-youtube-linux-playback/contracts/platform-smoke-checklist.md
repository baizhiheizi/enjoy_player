# Contract: Per-Platform YouTube Smoke Checklist (regression gate)

**Purpose**: prove the shared browser-dependency upgrade (6.1.5 → 6.2.0-beta.3)
changed nothing on the four healthy platforms (spec US5 / FR-010 / SC-007).
Executed manually from the feature-branch build on each platform before merge;
results recorded per data-model Entity 5.

## Checklist (identical steps on every platform)

| # | Step | Pass criterion |
|---|------|----------------|
| C1 | Open a known public YouTube video by pasting its URL | Video renders and plays (audio + video) |
| C2 | Play/pause toggle ×3 | State flips correctly, no stuck transport |
| C3 | Seek to 3 arbitrary positions | Frame + audio land on target; position readout follows |
| C4 | Change playback speed to 0.5× / 1× / 2× | Rate changes take effect; position stream continues |
| C5 | Open a video with captions; open the transcript panel | Captions fetched; language-aware selection behaves as before |
| C6 | Let a transcript track for ~60 s | Highlight follows audio as before |
| C7 | Tap a Discover feed YouTube tile | Opens and plays, no intermediate error state |
| C8 | Attempt Google sign-in navigation inside the player | Navigation cancelled; playback continues anonymously |
| C9 | Close player; reopen same video | Position resumes as before |
| C10 | Rapid open: local file ↔ YouTube ×4 | No ghost audio, no leaked surface, second open succeeds |
| C11 | Cold-start the app, hover/warm a YouTube item | Warm-up behaves as before (no new errors in diagnostic log) |
| C12 | Note any console/diagnostic errors during C1–C11 | Zero new error signatures vs. the previous release's baseline |

## Recording format

One row per platform (`android | ios | macos | windows`) in the PR description:

```text
Platform: <name>   Build: <branch>@<sha>   Date: <yyyy-mm-dd>   Executor: <who>
C1..C12: pass|fail (notes on any fail)
behaviorDiff: none | <description>     # "none" required to merge
```

## Merge rule

- All four platforms: `behaviorDiff: none` → merge proceeds.
- Any diff → fix, or an explicit decision records which platform accepts which
  risk and why (spec US5 scenario 3 — no silent trades). The decision lands in
  the ADR, not in the PR thread alone.

## Why manual

Native browser-engine behavior (rendering, codecs, page player) is not
observable in the Dart test suite; the constitution accepts documented manual
verification for such flows. C1–C12 is that documentation, fixed so the gate
is repeatable rather than vibes-based.
