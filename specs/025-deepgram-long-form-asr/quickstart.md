# Quickstart: Deepgram Long-Form ASR (Flutter Client)

**Feature**: `025-deepgram-long-form-asr`

Validates Flutter Enjoy-path routing and long-form job adoption. Worker Deepgram internals are covered by enjoy `specs/011-deepgram-long-form-asr/quickstart.md`.

## Prerequisites

- Flutter toolchain matching the repo pin
- Signed-in **Pro** or **Ultra** test account with remaining daily Credits
- Enjoy Worker staging/local with:
  - Deepgram long-form submit/poll live
  - **Media upload** route from [contracts/media-upload.md](contracts/media-upload.md) deployed (blocker if missing)
- Local audio or video **≥ 15 minutes** with no subtitles (or use Re-generate)
- ASR modality set to **Enjoy** (not BYOK)

## Automated checks

From repo root:

```bash
bash .github/scripts/validate_ci_gates.sh --fix   # or: flutter analyze && flutter test
flutter test test/features/asr
flutter test test/features/ai/data/enjoy
```

Expected coverage after implementation (see research § 10):

1. Duration `899` → multipart short-clip path (mocked).
2. Duration `900` → upload + submit + poll sequence (mocked).
3. Idempotency key reused on transport retry; new on fresh Generate.
4. Completed job JSON maps to timed `TranscriptLine`s and upserts `source: ai`.
5. `402` / failed retryable / unsupported_media → localized errors.
6. Long-media confirm appears at 900s.
7. Existing short-clip Enjoy + BYOK controller tests remain green.

## Manual E2E (staging)

1. Point the app AI/Worker base URL at the staging Worker (existing settings / env).
2. Import or open a ≥15 minute local file; clear AI transcript if needed.
3. Generate transcript (Enjoy path). Confirm the long-media dialog at ≥15 minutes.
4. Observe phases: extract (video) → upload → processing/polling → transcript appears.
5. Verify tap-to-seek / highlight on several lines.
6. Kill the app during polling; relaunch; confirm resume or safe reattach without a second Credits settlement for the same attempt.
7. Re-generate; confirm AI track upserts in place (no duplicate AI rows).
8. With Credits exhausted / Free tier: confirm block + upgrade messaging before a stuck spinner.
9. Switch ASR to BYOK Azure (valid keys); generate on long media; confirm Enjoy long-form job is **not** used.

## Short-clip regression

Repeat Generate on a ~5 minute file (Enjoy). Expect sync short-clip behavior without job-polling as the primary UX.

## Cross-repo note

If media upload is not yet on Worker, stop after automated mocked tests and track the Worker upload PR as a merge prerequisite for releasing this Flutter feature.
