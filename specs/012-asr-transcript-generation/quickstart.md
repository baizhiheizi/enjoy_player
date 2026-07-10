# Quickstart — ASR Transcript Generation

**Branch**: `012-asr-transcript-generation` | **Date**: 2026-07-10

A runnable validation guide for the end-to-end ASR transcript generation
flow. Each scenario is intentionally minimal and maps to one or more
requirements in `spec.md`. Detailed implementation code lives in
`tasks.md` (Phase 2) — this document describes **how to verify the
feature**, not how to build it.

---

## Prerequisites

- A clean checkout of `012-asr-transcript-generation`.
- Flutter stable channel (`flutter --version` ≥ 3.24).
- Native toolchains for at least one desktop target (macOS or Windows)
  **and** one mobile target (Android or iOS). Each target follows the
  existing repo setup (see `docs/`).
- For the BYOK paths:
  - Azure Speech: a subscription key + region, configured under
    Settings → AI Providers → Speech → Azure Speech.
  - OpenAI-compatible Whisper: a base URL + API key + model name.
- For the Enjoy path: a signed-in learner with at least one ASR credit
  on the account (the worker enforces credits per minute).
- An audio-only fixture (`test_assets/fixtures/asr/en_5min.m4a`,
  ~5 minutes, single English speaker) and a video fixture with the same
  audio (`test_assets/fixtures/asr/en_5min.mp4`).

## Setup

```bash
# one-time
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
```

After the implementation lands, run the full gate before any push
(Constitution Flutter Quality Gates):

```bash
bash .github/scripts/validate_ci_gates.sh
flutter analyze
flutter test test/features/asr test/features/transcript
```

---

## Scenario A — Generate on a local audio file (P1, US1)

**Maps to**: FR-001, FR-005, FR-007, FR-008, FR-013, FR-021; SC-001,
SC-002, SC-005.

1. Launch the app on **macOS** (or **Windows**).
2. Open `test_assets/fixtures/asr/en_5min.m4a`. The transcript panel
   shows the empty state with the "No transcript" hint and three CTAs:
   **Generate transcript**, **Extract** (hidden — audio-only), and
   **Add subtitle**.
3. Tap **Generate transcript**. A confirmation dialog appears showing
   the chosen language (English) and "May take up to ~30s".
4. Confirm. The CTA enters its inline busy state (`TranscriptBusyButton`).
   Status text cycles "Extracting audio…" → "Recognizing…" → "Saving…".
5. Within 60 seconds the panel renders time-aligned lines. Verify:
   - First line highlight tracks playback position.
   - Tap any line → player seeks to that timestamp.
   - Long-press a word → dictionary lookup works (same UX as imported
     `.srt`).
   - Echo region + blur practice + auto-translate all work without
     special-case behaviour (FR-016 / SC-005).
6. Open the subtitle picker. The new row is listed under **AI** with
   label "Generated (en)", language "English", and is the active
   primary.

**Expected**: 1 track in `transcripts` table with `source = 'ai'`,
`language = 'en'`, deterministic id. No duplicate `ai` row even after
tapping **Re-generate** (Scenario C).

## Scenario B — Generate on a local video file (P1, US1 + US5)

**Maps to**: FR-001, FR-003, FR-004, FR-005, FR-007; SC-002, SC-008.

1. Open `test_assets/fixtures/asr/en_5min.mp4`. Empty state appears.
2. Tap **Generate transcript**. The CTA enters busy state with status
   text "Extracting audio…". Extraction progress is reported (FFmpeg
   stderr → coarse percent).
3. After extraction, status switches to "Recognizing…" then "Saving…".
4. The transcript appears in the panel and the picker. Verify lines
   align with the video's audio.

**Expected**: at most 500 MB of disk I/O during extraction; no UI jank
during recognition. The temp WAV is deleted in `finally`.

## Scenario C — Re-generate at any time (P1, US2)

**Maps to**: FR-002, FR-010, FR-014, FR-015, FR-021, FR-022; SC-004.

1. With the AI transcript from Scenario A still active, open the
   subtitle picker.
2. The **Generate / Re-generate transcript** action is present in the
   actions section (always — US2.1).
3. Tap it. The previous `ai` track stays visible (US2.3). Status text
   on the row cycles "Recognizing…" → "Saving…".
4. On completion, the same row id is reused (SC-004). The active
   primary remains the AI track.
5. While a job is in-flight, tap **Generate / Re-generate transcript**
   again with a different language (e.g. pick "Auto-detect"). The
   controller cancels the prior job's future cleanly (FR-015) and
   starts the new one. No torn state, no overlapping writes.

**Expected**: at all times exactly one `source: 'ai'` row for the
chosen `(mediaId, language)` pair. Repeated taps do not stack jobs.

## Scenario D — BYOK Azure path (P1, US3)

**Maps to**: FR-005, FR-018; SC-006.

1. Settings → AI Providers → Speech → set provider to "BYOK" →
   Azure Speech. Enter subscription key + region. Save.
2. Open an unenrolled media file. Tap **Generate transcript**.
3. The result is produced through `ByokAsrAzureCapability` — verify
   via log line `ai.azure.asr.transcribe (region=…, lang=…, bytes=…)`.
4. Verify the row id is deterministic and that no Enjoy credits are
   consumed (no `enjoy.credits.deduct` log line).

**Negative test**: clear the BYOK key, attempt generation. The picker
shows the friendly "Set up Azure Speech" message with a deep-link to
AI Providers (FR-018). No silent Enjoy fallback.

## Scenario E — BYOK OpenAI Whisper path (P1, US3, plain-text fallback)

**Maps to**: FR-005, FR-009; SC-006.

1. Settings → AI Providers → Speech → BYOK → OpenAI-compatible.
   Configure base URL + API key + model. Save.
2. Open the 5-minute audio fixture. Generate.
3. The BYOK Whisper endpoint returns text only — verify the panel still
   renders time-aligned lines via the duration-distributed fallback
   (`AsrTimelineBuilder` plain-text path). Each line has a `startMs`
   and `durationMs` derived from the media duration.

**Expected**: lines are usable with playback tracking and dictionary
lookup; timestamps approximate but consistent. No track is created if
the Whisper response is empty (FR / US4.3).

## Scenario F — Auto-detect + language propagation (P2, US6)

**Maps to**: FR-011, FR-012.

1. Set the media row's language to `es` (Spanish) via the existing
   media-edit flow, even though the audio is English.
2. Generate transcript and choose "Auto-detect".
3. On success the resulting track's `language` is `en`, and the media
   row's `language` field is updated to `en` (US6.3).

## Scenario G — Long media confirmation (P2, US1 QR-008)

**Maps to**: FR-008, QR-008.

1. Open a 45-minute video fixture (or skip with a stubbed duration).
2. Tap **Generate transcript**. A pre-flight dialog warns about
   expected duration / credits and asks for confirmation.
3. Confirm → generation proceeds; cancel → no job is started.

## Scenario H — Failure modes (P1, US3, US5)

**Maps to**: FR-017, FR-018, FR-019; SC-007.

Each step should display a **localized, friendly** message — never a
raw exception string. Verify on:

| Step | Expected key |
|---|---|
| No audio track in container | `asrErrorNoAudioTrack` |
| FFmpeg missing on Windows PATH | `asrErrorFfmpegUnavailable` |
| BYOK Azure key cleared | `asrErrorByokMissing` (link → Settings) |
| Enjoy path with 0 credits | `asrErrorCreditsExhausted` (link → Upgrade) |
| Network offline | `asrErrorNetwork` (with **Retry**) |
| Whisper returns empty text | `asrErrorNoSpeech` (no track created) |

## Scenario I — Platform smoke (P1, US5)

**Maps to**: FR-004; SC-008.

Repeat Scenario B on each of the four supported targets. The Generate
CTA is **disabled with an explanatory tooltip** when FFmpeg is
unavailable (e.g. remove `ffmpeg.exe` from the bundled directory and
clear PATH on Windows), and Import / other paths remain usable.

## Scenario J — Re-generate replaces, never duplicates (P1, US2; SC-004)

**Maps to**: FR-010; SC-004.

1. Generate for media + language `en`.
2. Inspect `transcripts` table — exactly 1 row with `source = 'ai'`,
   `language = 'en'`.
3. Re-generate twice in a row.
4. Re-inspect — still exactly 1 row. `updatedAt` advances; `createdAt`
   preserved.

## Scenario K — Active primary preserved on re-generate (P1, US2)

**Maps to**: FR-021.

1. With an `ai` track active, open the picker. Note its id.
2. Re-generate.
3. Verify the active primary session row still references the same
   row id (echo session lookup unchanged). The active track id is the
   deterministic id; replacing the row keeps session continuity.

## Verification commands

Run all of these before pushing:

```bash
bash .github/scripts/validate_ci_gates.sh          # format + codegen drift
flutter analyze                                    # lints
dart run build_runner build --delete-conflicting-outputs
flutter test                                       # full suite
flutter test test/features/asr                    # new ASR suite
flutter test test/features/transcript              # updated transcript suite
```

For desktop / mobile smoke, follow Scenarios A through K on each
target. Record evidence (screenshots or screen recordings) in the PR
description per Constitution Principle IV.