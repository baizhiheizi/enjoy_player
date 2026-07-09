## Summary

Review of issues #252–#258 (all open, all filed by automated workflows): **all 7 are valid** and will be resolved across **2 PRs** (per your choice — one per category). None will be closed as wontfix.

### Validity findings
- **#252, #253, #254, #258** — accurately describe the current codebase (verified by reading each file). Genuine duplication / large-file issues.
- **#255, #256, #257** — reference real shipped features (commits `6d9176a`, `5fa67c9`/`c59375d`, `209e1b6`), each already documented in an ADR + feature doc but missing from `CHANGELOG.md`. Valid docs-hygiene gap.
- **#253 extra:** the claimed "CreditsFailure drift" is a **real UX bug**, not just cosmetic — `DictionaryService.lookup` routes through `guardAiCall` which maps HTTP 402 → `CreditsFailure`, but `DictionaryLookupSection` only shows a generic retry (no "View plans" button) while `TranslationLookupSection` shows the credits CTA. The gate extraction fixes this.

### Baseline (confirmed green before any change)
`flutter test test/features/lookup/ test/features/auth/presentation/widgets/profile_content_test.dart` → 36 passed.

---

## PR 1 — `refactor(lookup+profile): dedupe lookup helpers, params, auth gate; split profile widgets`

Resolves **#252, #253, #254, #258**. One branch off `main`.

### #252 — Promote `_primarySubtag` to public `primaryLanguageSubtag`
- `lib/core/application/app_language_catalog.dart`: rename `_primarySubtag` → `primaryLanguageSubtag` (make public; body unchanged — already `normalizeLanguageAlias(tag).split(RegExp(r'[-_]')).first.toLowerCase()`). Update its 12 in-file call sites (lines 157, 164, 165, 187, 219, 240, 242, 259, 262, 272×2, 290, 292).
- `lib/features/lookup/application/lookup_target_languages.dart`: delete `_primarySubtagOnly` (line 64-65); switch its 6 call sites (lines 30, 32, 57, 59, 105, 109) to the imported `primaryLanguageSubtag`.
- No new exports needed — `lookup_target_languages.dart` already `import`s `app_language_catalog.dart`.

### #254 — Introduce `LookupTextParams` base class
- `lib/features/lookup/application/lookup_section_params.dart`: add `@immutable base class LookupTextParams` holding `sourceLanguage`, `targetLanguage`, `String text`, + shared `==`/`hashCode`. `LookupTranslationParams` and `LookupDictionaryParams` extend it (dictionary renames `word`→`text`). `LookupContextualParams extends LookupTextParams` adds `String? context` and overrides `==`/`hashCode` via `super` + `context`.
- Rename `LookupDictionaryParams.word`→`text`: the **only** external read is `lookup_section_providers.dart:42` (`word: params.word` → `text: params.text`); the construction site is `dictionary_lookup_section.dart:31` (`word:` → `text:`). Update the 3 test constructions in `lookup_sheet_result_cache_test.dart` (`dictA/dictB/dictC`, lines 40/45/50). The generated `.g.dart` references the class *name* only (not `.word`), so **no codegen regen needed** — but I will run `build_runner` as a safety check and only commit if it changes.
- `LookupSheetResultCache._dictionary` map key type stays `LookupDictionaryParams` (unchanged type identity).

### #253 — Extract `LookupSectionAuthGate` + fix CreditsFailure drift
- New `lib/features/lookup/presentation/widgets/lookup_section_auth_gate.dart`: a `ConsumerWidget` that watches `authCtrlProvider`, returns `AuthRequiredCallout(surface, compact: true)` for non-signed-in / loading / outer-error, else returns its `child`. Signature: `LookupSectionAuthGate({required AuthRequiredSurface surface, required Widget child})`.
- Each section: replace the outer `auth.when(...)` (~10 lines) with `LookupSectionAuthGate(surface: ..., child: <inner async.when / _ContextualFetchBody>)`. The inner `AuthFailure`→`AuthRequiredCallout` mappings stay inline (they're 1-liners and contextual to each error handler).
- **Bug fix (the real value of this PR):** add `CreditsFailure` handling to `DictionaryLookupSection`'s inner error branch, mirroring translation's "retry + View plans" `Column`. This fixes the drift the issue flagged.
- Keep `_ContextualFetchBody` mounted exactly as today (the gate wraps the signed-in path; contextual's inner `AuthFailure` handling at line 307 stays).
- New test `test/features/lookup/lookup_section_auth_gate_test.dart`: covers loading / error / unauthenticated / signed-in-pass-through.
- Existing `auth_required_lookup_test.dart` (translation only) continues to pass unchanged.

### #258 — Split `profile_content.dart` (1064 → ~6 files)
Move-don't-rewrite. Drop `_` prefix on extracted widgets (they become sibling-file-private within `lib/features/auth/presentation/widgets/`). Target files:
1. `profile_section_header.dart` — `ProfileSectionHeader`
2. `profile_hero_card.dart` — `ProfileHeroCard` + `SubscriptionChip`
3. `profile_stats.dart` — `ProfilePracticeSection`, `ProfileStatSkeleton`, `ProfileStatsRow`, `ProfileStatTile`
4. `profile_account_card.dart` — `ProfileAccountCard` + `ProfileNavTile`
5. `profile_sign_out_button.dart` — `ProfileSignOutButton`
6. `profile_content.dart` (trimmed) — only `ProfileContent` + `_ProfileContentState`, importing the 5 new files.
- **Scope reduction from the issue:** I will NOT extract a separate `profile_preferences_form.dart` (the 300-line inline form). It's the riskiest split (owns `_formKey`/controllers/`_saving`, deeply entangled with `_ProfileContentState`'s save flow and Riverpod reads) and the issue itself flagged it as "the only one that changes widget state ownership." Leaving it in `profile_content.dart` still gets the file well under 500 lines and avoids a behavior-changing refactor. I'll note this deviation in the PR description.
- `ProfileContent({super.key, bool showRefreshIndicator})` signature unchanged.
- Existing `profile_content_test.dart` + `settings_two_pane_account_test.dart` pass unchanged (they test the public `ProfileContent` surface).

### PR 1 verification
```bash
export PATH="/c/Users/me/flutter/bin:$PATH"
bash .github/scripts/validate_ci_gates.sh --fix   # format + analyze + test + codegen drift
flutter test test/features/lookup/ test/features/auth/
```
Acceptance: all gates green; `profile_content.dart` < 500 lines; no new analyzer warnings; `_primarySubtagOnly`/`_primarySubtag` gone; `LookupDictionaryParams.word` gone.

---

## PR 2 — `docs(changelog): record bilingual transcripts, lookup precedence, auto-translate sourceKey`

Resolves **#255, #256, #257** (CHANGELOG-only, under `[Unreleased]` per your choice). One branch off `main`, independent of PR 1.

Add three bullets to `CHANGELOG.md` under `## [Unreleased]`, creating `### Added` and `### Fixed` subsections as needed (the section is currently empty — just the `## [Unreleased]` header):

- **#255** (Added): YouTube bilingual captions — multi-language `pollTranscripts`, primary/secondary assignment, `partial` handling. Refs ADR-0036, commit `6d9176a`, `docs/features/transcript.md`.
- **#256** (Fixed): chrome-first lookup source precedence — `resolveLookupSourceLanguage({chromeLanguage, activeTrackLanguage})` replaces sibling-track fallback. Refs ADR-0019/0021, commit `5fa67c9`/PR #249.
- **#257** (Fixed): auto-translate keyed by primary text (`sourceKey` overlay) instead of time match. Refs ADR-0039, commit `209e1b6`.

Format follows the existing convention (e.g. `**Title**: description. See [link](...).`). Each entry ~2-4 lines.

### PR 2 verification
`CHANGELOG.md` is Markdown — no `dart format`/analyze/test impact. Verify with `git diff --stat` (only `CHANGELOG.md` changed) and visual check against existing bullet style.

---

## Order of operations
1. Create branch `refactor/lookup-profile-dedupe-split`, do PR 1, push, open PR referencing #252 #253 #254 #258.
2. Create branch `docs/changelog-unreleased-batch` (off `main`), do PR 2, push, open PR referencing #255 #256 #257.
3. Each PR description lists the resolved issues with `Resolves #NNN`.

Neither PR will close any issue directly via commit (issues close when PRs merge to `main`). I will push branches and open PRs but **not** merge — merging is your call.

### Out of scope / deviations (will document in PRs)
- #258: skipping the `profile_preferences_form.dart` extraction (explained above) — files still split, target line count met, but the form stays inline to avoid a state-ownership behavior change.
- #252: issue text said `_primarySubtagOnly` used `normalizeBcp47Tag`; actual code uses `normalizeLanguageAlias` (same as `_primarySubtag`). Dedupe is still valid; the public helper keeps the `normalizeLanguageAlias` body.