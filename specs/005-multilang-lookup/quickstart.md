# Quickstart: Validating the Multi-language Transcript Lookup

Prerequisites:
- A debug build on at least one desktop-class target (Windows or macOS) and one mobile-class target (Android or iOS) — Flutter web is out of scope per AGENTS.md.
- A signed-in Enjoy account (the lookup sheet requires it for translation / dictionary / contextual-translation fetches; signed-out paths are also covered by `AuthRequiredCallout`).
- At least one media item with a Korean transcript track (the bug-report reproduction case), plus one with a `und` / missing-language track (the source-override case) and one with an English or Japanese track (default-target case).
- A second non-Korean target language in the expanded list (e.g., Japanese, Spanish, French) to exercise the new pair path.

## Setup

```bash
flutter pub get
dart run build_runner build   # sanity re-run after touching the catalog (no new @riverpod providers, but avoids generated-code drift)
flutter gen-l10n              # regenerate AppLocalizations after adding the new lookupLanguage* ARB keys
```

## Automated checks

```bash
flutter analyze
flutter test test/features/lookup/
flutter test test/core/application/lookup_catalog_test.dart
flutter test                  # full suite — confirm no regressions elsewhere (en-US / zh-CN existing users, profile / settings pickers, transcript rendering)
```

Expected: zero analyzer warnings, all new and extended lookup tests green, no regressions in the rest of the suite.

## Manual validation scenarios

Each scenario maps to a Success Criterion in [spec.md](./spec.md).

### 1. Korean → any-target picker expansion (SC-001, FR-001 / FR-003)

Open a media item with a Korean transcript track (`ko-KR`). Select a Korean word on the active cue. The lookup sheet opens.

- **Source pill** shows the Korean label (e.g., "한국어" / "韩语").
- **Target pill** shows the user's stored native preference when it is in the expanded list, otherwise the closest supported target.
- Tap the **target pill** — the bottom-sheet option list contains **all** ≥ 13 entries from `kSupportedLookupLanguageTags`, pre-sorted with the user's learning language first (then alphabetical).
- The user's stored native preference is highlighted; tapping any other entry updates the target pill immediately.

Expected: every entry in the expanded lookup list is selectable; no entry is silently hidden because the user's stored native preference is not English or Chinese.

### 2. Korean → non-English / non-Chinese target returns result in target language (SC-002, SC-003, FR-001 / FR-007)

From scenario 1, with the sheet open against a Korean transcript, pick **Japanese** as the target. Observe:

- The target pill now reads "日本語" / "日语".
- The swap control becomes enabled (source ≠ target).
- The **Translation** section refreshes; the rendered result is in **Japanese** (not English, not Chinese).
- Expand the **Definition (dictionary)** section — it returns definitions in Japanese.
- Expand the **Contextual translation** section — it returns contextual explanation in Japanese.

Expected: all three sections return their content in the chosen target language within 2.5 s p95 on a 50 Mbps connection. No English / Chinese fallback text appears.

### 3. Source override for `und` / missing track language (FR-005, FR-006)

Open a media item whose active transcript track has no language metadata (`und`, `null`, `''`, or `zxx`). Select a word on the active cue. The lookup sheet opens.

- The source pill defaults to the user's **learning language** (existing `resolveLookupSource` behaviour preserved per SC-005).
- Tap the **source pill** — pick "Français" (or any non-learning tag). The source pill updates, the swap control reflects the new pair, and the next section refresh sends a `source` of `fr` to the worker.
- Tap the **swap control** — source and target pills swap atomically; the prior pair's cached results are discarded (the existing sections show shimmer skeletons for the new pair, not the old pair's content).

Expected: source override works for `und` tracks; swap is atomic and does not leak prior results.

### 4. Default behaviour preserved for en-US / zh-CN users (SC-005)

Sign out (or use a profile with stored native = `zh-CN` and learning = `en-US`). Import a Korean video.

- Open a fresh lookup sheet (no prior per-sheet override). Source pill = "한국어", target pill = "中文".
- Worker request payloads use `source = ko`, `target = zh`.
- Repeat with stored native = `en-US` and learning = `zh-CN`. Source pill = "한국어", target pill = "English".

Expected: 100% parity with the previous behaviour for the existing en-US / zh-CN pair combinations. The `lookup_target_languages_test.dart` extension covers this with explicit expected-value cases.

### 5. Cache invalidation on swap (FR-006, FR-010, SC-004)

From a Korean transcript lookup with target = Japanese:

- Expand **Dictionary** (wait for result).
- Expand **Contextual translation** (wait for result).
- Tap the swap control. Source = Japanese, target = Korean.
- Observe within 50 ms: the existing Dictionary + Contextual sections transition to their shimmer skeletons (no Korean→Japanese content visible above the skeletons), and refresh against the new pair.

Expected: zero leak of prior pair's content; first refresh of the new pair starts within 50 ms of the swap.

### 6. Worker rejection surfaces a localized error row (FR-008)

Force a worker rejection: pick a regional variant the worker cannot fulfil (e.g., `pt-PT` → Korean on a free-tier account with limited language coverage). Observe:

- The section renders `LookupErrorRow` with a localized message and the existing **Retry** (`lookupErrorRetry`) affordance.
- The picker does **not** silently fall back to `en-US` or `zh-CN`.

Expected: the error row is shown, retry works, and the user's chosen pair is preserved across the retry.

### 7. Auth-required callout covers the full expanded list (FR-012)

Sign out. Open a fresh lookup sheet. For each of the four newly added target languages (Japanese, German, Italian, Portuguese), tap the target pill and select it:

- The signed-out **Auth-required callout** is shown in every section, not just for the existing two natives.

Expected: the callout message is identical to today's (`lookupCloudRequiresSignIn`) for every target — no language-specific "sign-in required" copy is added.

### 8. Cross-platform visual consistency (QR-003)

- On a desktop build: tab through the source / target pills and the swap control; confirm a visible focus ring on each. Confirm the segmented control row layout is unchanged.
- On a mobile build: confirm every interactive control still meets the 44 px minimum touch target.
- Compare side-by-side with Home / Library on the same build — the picker row should feel identical to today's segmented control.

Expected: zero visual regression vs. the existing picker; no new dialogs / tabs / search field appear.

### 9. Performance budgets (SC-001, SC-004, SC-006)

On Windows desktop with a cold cache (close + reopen the app, do not pre-warm the worker):

- Time the picker open (selection → sheet shown → first frame of option list when the pill is tapped) — target < 100 ms p95.
- Time the swap-to-shimmer transition — target < 50 ms.
- During all of the above, confirm playback continues without dropped frames, the transcript scrolls smoothly, and the transport bar remains responsive (no jank in the Flutter DevTools CPU profiler on the UI thread).

Expected: budgets met; no jank or dropped frames during the picker interactions.

## Sign-off

All 9 scenarios pass → plan is ready to move to `/speckit-tasks`. Ensure `docs/decisions/0021-multi-language-lookup-catalog.md`, `docs/features/dictionary-lookup.md`, and `AGENTS.md` are updated before closing the feature.