# Quickstart: Craft from Text (AI-generated audio materials)

**Feature**: [spec.md](./spec.md) · **Plan**: [plan.md](./plan.md) · **Contracts**: [contracts/README.md](./contracts/README.md) · **Data model**: [data-model.md](./data-model.md)

> Run these scenarios in order to verify the Craft from text feature works end-to-end. Each scenario lists **prerequisites**, **steps**, **expected outcomes**, and **how to confirm** the underlying invariant. The scenarios double as manual QA during implementation and as smoke tests before merge.

---

## Scenario 0 — Static checks (no runtime)

**Prerequisites**: feature branch checked out, `flutter` on PATH.

**Steps**:

```bash
bash .github/scripts/check_dart_format.sh
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

**Expected**: format clean; build_runner produces new `craft_controller.g.dart` and updated `ai_capability_providers.g.dart`; analyze reports no errors; unit + widget tests pass.

**How to confirm**: `git status` shows only `*.g.dart` regeneration and the new Craft files.

---

## Scenario 1 — Discover Craft from text in the import chooser (P1, Story 1)

**Prerequisites**: signed-in user, empty or non-empty library.

**Steps**:

1. Launch the app on Android, iOS, macOS, and Windows.
2. Tap **Import** on Home or Library.
3. Inspect the bottom sheet.

**Expected**: three entries in order — **From file**, **From YouTube URL**, **Craft from text**. The Craft tile uses the shared list-tile pattern (leading icon + label); the icon is `auto_awesome_outlined` (or themed equivalent).

**How to confirm**: open `lib/features/library/presentation/library_actions.dart` and verify the third `ListTile` exists; open `lib/l10n/app_en.arb` and verify `importCraftFromText` key exists with the expected value.

---

## Scenario 2 — Speak directly end-to-end (P1, Story 3)

**Prerequisites**: signed in; AI providers at defaults (Enjoy AI for TTS); network online.

**Steps**:

1. Tap Import → Craft from text.
2. Choose mode **Speak directly**.
3. Paste ~200 characters of English text (e.g. a paragraph from a public-domain short story).
4. Confirm the target language picker shows your profile learning language.
5. Tap **Craft**.

**Expected**:

- Sheet closes; import-blocking dialog appears with the label "Crafting your audio…".
- Within ~20 seconds, dialog closes and the player opens with a new audio item.
- The new audio item's primary transcript equals the pasted text (single-line timeline).
- The library grid shows the new item with a **Craft** badge in the top-right.
- Reopening the item shows the same audio + transcript without re-running Craft.

**How to confirm**: in the database inspector (or by querying Drift via a debug `print` in a temporary scaffold), the new `AudioRow` has `provider = 'craft'`, `source = 'craft-direct'`, `sourceText = <your text>`. The `Transcripts` row has `language = <learning tag>`, `source = 'ai'`, `timelineJson = '[{"text": "...", "start": 0, "duration": <ms>}]'`.

---

## Scenario 3 — Translate then speak end-to-end (P1, Story 2)

**Prerequisites**: signed in; AI providers at defaults; network online.

**Steps**:

1. Tap Import → Craft from text.
2. Choose mode **Translate then speak**.
3. Paste ~300 characters of English text into the source field.
4. Set source language = English (US), target language = your profile learning language (e.g. zh-CN).
5. Tap **Craft**.

**Expected**:

- Within ~30 seconds, the player opens with a new audio item.
- Primary transcript is in the target language (Chinese in this example).
- Secondary transcript (visible when the transcript overlay is expanded) is the original English text.
- Library badge shows **Craft**.

**How to confirm**: two `Transcripts` rows for the new audio id — one with the target language as primary, one with the source language as secondary (both `source = 'ai'`). `AudioRow.translationKey = 'en'`, `AudioRow.language = 'zh'`.

---

## Scenario 4 — Same-language affordance (P1, Story 2 acceptance #5)

**Prerequisites**: signed in; learning language = English (US).

**Steps**:

1. Open Craft sheet.
2. Choose mode **Translate then speak**.
3. Type ~200 characters of English text into the source field.
4. Set source language = English (US).
5. Observe the sheet.

**Expected**: an inline suggestion chip appears: "Looks like this is already in your learning language." with a **Speak directly** button. Tap it; mode flips to Speak directly without losing the entered text. No translation API call is made (verifiable via network inspector or via `guardAiCall` log).

**How to confirm**: in the Craft controller, after the suggestion is shown, switching to Speak directly does NOT call `TranslationService.translate`. The synthesized audio matches the original English text.

---

## Scenario 5 — TTS BYOK (OpenAI-compatible) end-to-end (P2, Story 4)

**Prerequisites**: signed in; valid OpenAI-compatible TTS endpoint + API key; BYOK is not currently active.

**Steps**:

1. Open Settings → AI providers.
2. On the TTS card, select BYOK → OpenAI-compatible. Enter base URL, API key, model (e.g. `tts-1`).
3. Save. Return to Home.
4. Tap Import → Craft from text → Speak directly.
5. Paste ~150 characters of text and tap Craft.

**Expected**: audio is produced by the configured vendor; no Enjoy worker TTS request is made (network log). Library item appears with Craft badge; playback works.

**How to confirm**: inspect the network inspector — only the OpenAI-compatible endpoint should see traffic for the synthesize call. The Enjoy `EnjoyTtsCapability` is NOT invoked.

---

## Scenario 6 — TTS BYOK Azure end-to-end (P2, Story 4)

**Prerequisites**: signed in; valid Azure Speech subscription key + region.

**Steps**:

1. Open Settings → AI providers.
2. On the TTS card, select BYOK → Azure Speech. Enter subscription key + region.
3. Save.
4. Run Scenario 2 (Speak directly) again.

**Expected**: audio produced via Azure Speech SDK with the user's subscription. No Enjoy worker traffic for synthesis.

**How to confirm**: logs show `azure_speech.synthesize` being called with the user's subscription key + region. Network inspector shows no `Enjoy /azure/tokens` traffic.

---

## Scenario 7 — TTS BYOK misconfiguration (P2, Story 4 acceptance #3)

**Prerequisites**: TTS BYOK selected but with an empty API key.

**Steps**:

1. Configure TTS BYOK for OpenAI-compatible with a base URL but no API key. Save.
2. Run Scenario 2.

**Expected**: Craft surfaces a calm error: "We couldn't turn the text into audio. Check your TTS provider settings or try again." with two actions — **Retry** and **Open AI settings**. The latter routes to `/settings/ai-providers` and scrolls to the TTS card. No orphan transcript is created.

**How to confirm**: no `AudioRow` and no `Transcripts` row in Drift after the failure (check via a debug query). The error message uses the localized `craftFailureTts` key.

---

## Scenario 8 — Calm failure discard (P2, Story 6 acceptance #2)

**Prerequisites**: translation works (Enjoy AI or BYOK), but TTS is forced to fail.

**Steps** (simulating forced failure via a temporary `TtsService` override in a debug build):

1. Add a debug-only switch that throws `ByokNotConfiguredFailure` from the TTS capability after translate succeeds.
2. Run Scenario 3.

**Expected**: Craft surfaces a TTS-stage error. No `Transcripts` rows are written (translate result is discarded). No `AudioRow` is written. Reopening the sheet starts fresh.

**How to confirm**: Drift queries show no rows for this Craft attempt. The controller's `CraftJob.failure` is `CraftFailure.tts`.

---

## Scenario 9 — Save-stage failure discard (P2, Story 6 acceptance #4)

**Prerequisites**: Craft works end-to-end; force `FileStorage.importBytes` to throw by filling the disk to capacity (or by a debug-only override).

**Steps**: run Scenario 2 with the disk full.

**Expected**: Craft surfaces a save-stage error: "The audio was generated but couldn't be saved. Free up space and try again." with Retry. No `AudioRow`, no `Transcripts` row, no orphan audio file in app storage.

**How to confirm**: `flutter: ls` of the app's documents directory shows no orphan file from this attempt. Drift queries show zero rows for this Craft attempt.

---

## Scenario 10 — Dedupe (P2, Story 5 acceptance #1 + SC-009)

**Prerequisites**: signed in; Scenario 2 completed.

**Steps**:

1. Re-open Craft.
2. Paste the exact same ~200 characters of text into Speak directly.
3. Tap Craft.

**Expected**: sheet shows "Already in your library" with an **Open** button (not the new import-blocking dialog). Tapping Open takes the learner to the existing item. No new `AudioRow` is written. No new `Transcripts` row. No second API call.

**How to confirm**: Drift count of `AudioRow`s with that `md5` is still 1. Network inspector shows zero Enjoy worker / vendor calls during the deduped attempt.

---

## Scenario 11 — Library badge + delete parity (P2, Story 5)

**Prerequisites**: at least one Craft item from Scenario 2 / 3.

**Steps**:

1. Open Library.
2. Confirm the Craft badge appears on every `provider = 'craft'` item.
3. Long-press the item → Delete. Confirm.

**Expected**: badge renders identically to the YouTube badge (same position, same style, accessible localized tooltip). Delete removes the audio file + both transcripts (primary + secondary if present). No orphan file remains in app storage. Re-importing the same text now finds no dedupe hit and writes a fresh row.

**How to confirm**: Drift has zero rows for the deleted item id; `MediaStorage` listing shows no orphan file.

---

## Scenario 12 — Sign-in gate (P1, Story 2 acceptance #4)

**Prerequisites**: signed-out user; Craft entry is visible in the import chooser.

**Steps**:

1. Sign out.
2. Tap Import → Craft from text.

**Expected**: Craft sheet opens, but submit is gated by a localized "Sign in to use Craft" callout that routes to the existing sign-in surface. After signing in, the Craft sheet resumes with the entered text + language picks intact (best-effort in-memory restore; if the sheet was closed, the user reopens it normally).

**How to confirm**: no Enjoy / BYOK calls are made while signed out. The sign-in callout uses the localized `craftSignInRequired` key.

---

## Scenario 13 — Offline banner (Edge case)

**Prerequisites**: signed in; airplane mode on.

**Steps**:

1. With airplane mode on, open Craft.
2. Try to tap Craft.

**Expected**: a calm offline banner at the top of the sheet reads "You're offline. Craft needs an internet connection." The Craft action is disabled. No API call is attempted.

**How to confirm**: network inspector shows zero calls. The `craftOnlineProvider` reports `false`.

---

## Scenario 14 — Length cap (Edge case)

**Prerequisites**: signed in; AI providers at defaults.

**Steps**:

1. Open Craft → Speak directly.
2. Paste 6 000 characters of text.
3. Observe the sheet.

**Expected**: an inline notice above the Craft action reads "Crafted the first 5 000 characters; the rest was not synthesized." The Craft action stays enabled. On submit, only the first 5 000 characters are sent to TTS.

**How to confirm**: the synthesized audio duration is roughly consistent with 5 000 characters (~3–5 minutes at typical Azure Speech MP3 bitrates). The primary transcript text reflects the truncated input.

---

## Scenario 15 — Cross-platform smoke (all four targets)

**Prerequisites**: signed in.

**Steps**: run Scenario 2 on Android, iOS, macOS, and Windows in sequence.

**Expected**: identical behavior — Craft produces a playable audio item in under 20 seconds; library badge renders; the player opens. No platform-specific crashes in `flutter logs` or Xcode / Android Studio / Visual Studio output.

**How to confirm**: `flutter logs` shows no uncaught errors; the resulting audio plays in the existing audio media path on every platform.

---

## Scenario 16 — Documentation + ADR check (Constitution V)

**Steps**:

```bash
ls docs/decisions/0030-craft-from-text-import.md
grep -E "Craft from text|craft" docs/features/ai.md | head -10
grep -E "Craft from text|craft" docs/features/library.md | head -10
grep -E "Craft from text|craft" docs/features/transcript.md | head -10
grep -E "Craft from text|craft" docs/features/settings.md | head -10
grep -E "importCraftFromText|craftModeTranslateThenSpeak|craftModeSpeakDirectly|craftAction|craftCraftingProgress|libraryProviderCraftBadge" lib/l10n/app_en.arb lib/l10n/app_zh_CN.arb
```

**Expected**: every check returns at least one match.

**How to confirm**: the grep commands succeed. The ADR file exists and links to the spec + plan.

---

## Scenario 17 — CI gates (Constitution Flutter Quality Gates)

**Steps**:

```bash
bash .github/scripts/validate_ci_gates.sh
```

**Expected**: format check passes; codegen drift check passes (no uncommitted `*.g.dart`); analyze passes; `flutter test` passes.

**How to confirm**: script exits 0.

---

## Rollback plan

If a regression is discovered post-merge:

1. The Craft entry is reachable only from the import chooser. Remove the third `ListTile` in `library_actions.dart` to hide the entry without removing the underlying code paths.
2. The new TTS Enjoy implementation can be reverted to `UnimplementedError` by restoring the prior `enjoy_tts_capability.dart` — TTS BYOK remains the only working path; Craft continues to function for BYOK users.
3. The new `MediaLibraryRepository.importCraftedFromText` is additive; reverting it does not affect existing `importMedia` / `importYoutubeVideo` paths.
4. Drift rows inserted by Craft are tagged `provider = 'craft'`; a one-line Dart script can delete them in a hotfix without affecting other rows.