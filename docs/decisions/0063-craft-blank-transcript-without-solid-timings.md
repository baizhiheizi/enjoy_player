# ADR-0063: Craft blank transcript without solid timings

## Status

Accepted

## Context

Craft synthesizes practice audio and historically wrote a timed transcript from
Azure word boundaries, falling back to proportional duration estimates when
boundaries were missing (common on Apple platforms and OpenAI BYOK TTS).
Estimated cues were coarse and often worse than no transcript. Azure punctuation
tokens could also start practice lines with `.` / `?`.

Forced alignment and Deepgram TTS were researched and deferred.

## Decision

1. **Solid timings only**: Craft save writes a primary AI transcript
   (`source: 'ai'`) only when word boundaries are non-empty **and** the
   segmenter produces ≥1 non-empty line after punctuation merge.
2. **Blank otherwise**: Pass `primaryTimelineJson: null` — import/update omit
   or delete transcript rows. Audio still saves successfully.
3. **STT escape hatch**: Learners generate or replace cues via the existing
   player ASR flow (`launchAsrGeneration`). No auto-STT on Craft save.
4. **Segmenter quality**: Merge standalone punctuation onto the previous word;
   prefer sentence-end flushes over blind word-count chops.

## Consequences

- iOS/macOS and OpenAI BYOK Craft items open with an empty transcript and a
  clear Generate affordance.
- Android/Windows Azure word timings produce cleaner shadow/echo lines.
- Duration-based `TranscriptTimestampEstimator` is no longer used on Craft save.
- Retro-fixing older estimated Craft transcripts is out of scope.
