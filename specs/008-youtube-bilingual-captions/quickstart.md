# Quickstart: YouTube Bilingual Captions

**Feature**: [spec.md](./spec.md) · **Plan**: [plan.md](./plan.md)

A validation/run guide — not an implementation reference. Implementation detail
lives in `tasks.md` (produced by `/speckit-tasks`).

## Prerequisites

- A device/emulator on Android, iOS, macOS, or Windows (no web).
- Signed in to an Enjoy account with:
  - a **learning** language set (e.g. `en`),
  - a **native** language set that **differs** from the content language of the
    test video (e.g. `zh`).
- A test YouTube video whose stored **content language** is known and non-`und`
  (e.g. an English talk → `en`), and for which the worker can produce both the
  original caption and a `zh` translation. A second video whose content language
  equals the learner's native language (e.g. a `zh` video) for the skip case.

> Worker base must be reachable (default `https://worker.enjoy.bot`; see
> `kDefaultAiApiBaseUrl`). Use a dev/preview worker if available.

## Commands

```bash
# No codegen step is required for the minimal change. Run only if a provider
# annotation was touched:
dart run build_runner build        # only if @riverpod/Drift annotations changed

flutter analyze                    # must be clean
flutter test                       # all unit/widget tests green
```

Targeted tests to run for this feature:

```bash
flutter test test/data/api/services/ai/youtube_transcripts_api_test.dart
flutter test test/features/transcript/transcript_repository_multi_lang_test.dart
flutter test test/features/transcript/transcript_fetch_controller_native_lang_test.dart
```

## Validation scenarios

Each scenario is independently verifiable.

### V1 — Bilingual captions in one request (happy path)

1. Sign in; ensure learning=`en`, native=`zh`.
2. Open an English YouTube video (content language `en`).
3. **Expect**: one `POST /youtube/transcripts` per poll cycle carrying
   `languages: ["en","zh"]` (verify via diagnostic logs —
   `HTTP → POST .../youtube/transcripts`).
4. **Expect**: the transcript panel shows the **English** caption as the primary
   subtitle and the **Chinese** caption as the secondary (translation) subtitle,
   automatically selected.
5. **Expect**: both tracks appear in the subtitle picker under Primary and
   Translation.

Pass criteria: matches [contracts/youtube-transcripts-api.md](./contracts/youtube-transcripts-api.md)
multi-language `ready` handling and data-model primary/secondary assignment.

### V2 — Partial (translation missing) does not error

1. Open a video where the worker can produce the original but **not** the
   translation (or force a `partial` via a language the worker cannot translate).
2. **Expect**: the original caption is stored and shown as primary; no error
   banner is shown; secondary is simply unset.
3. **Expect**: fetch state records `success`, and `missingLanguages` appears in
   diagnostic logs.

### V3 — Skip when content language == native

1. With native=`zh`, open a video whose content language is also `zh`.
2. **Expect**: the request uses the **single-language** path (`language: "zh"`,
   no `languages`), preserving the Apify fallback. Only one caption track is
   fetched.

### V4 — Unknown content language falls back to local

1. Open a YouTube video with content language `und`/empty.
2. **Expect**: no cloud transcript request is sent; only local/sidecar tracks are
   shown (unchanged behaviour).

### V5 — Reopen is instant and network-free

1. After V1 succeeds, fully close and reopen the **same** video.
2. **Expect**: both caption tracks appear instantly from local storage; **zero**
   `POST /youtube/transcripts` requests (verify in logs).

### V6 — Long-poll reduces request count

1. Open a fresh video whose captions are still generating.
2. **Expect**: captions appear promptly with markedly fewer POSTs than the prior
   fixed 2 s × 30 loop (target: a handful of long-poll POSTs over ~60–75 s).
   Each `202 generating` response carries `Retry-After: 5`, which the client
   honours before re-posting.

### V7 — Manual refresh re-pulls both

1. From the subtitle picker, choose **Refresh from cloud**.
2. **Expect**: a single bilingual request is issued (when languages differ) with
   `forceRefresh: true`; both tracks update in place.

## Performance check (manual evidence)

- Capture before/after request counts for V1 + V6 (diagnostic logs count
  `POST /youtube/transcripts`).
- Confirm V1 time-to-first-caption is within ~10% of the pre-change baseline on
  the same video/network.
- Confirm dual-caption scrolling on a long video (>20 min) stays smooth.

## References

- Worker contract (now superseded by the cache-only API): [specs/013-client-yt-transcripts/contracts/worker-cache-api.md](../../013-client-yt-transcripts/contracts/worker-cache-api.md) — see issue #320.
- Entities & state transitions: [data-model.md](./data-model.md)
- Design decisions: [research.md](./research.md)
