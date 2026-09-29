# ADR-0090: One language descriptor row

## Status

Accepted

## Context

Issue [#794](https://github.com/baizhiheizi/enjoy_player/issues/794) candidate 1.
The same per-language knowledge was restated in parallel literals across four
modules; adding Norwegian Bokmål (ADR-0087) took 24 files, ~9 of them
hand-edited code:

| Restatement | Home |
|---|---|
| `kSupportedFocusLanguageTags` + `kSupportedMediaLanguageTags` | `lib/core/application/app_language_catalog.dart` |
| `kSupportedLookupLanguageTags` + `kLookupLanguageLabels` | `lib/core/application/app_language_catalog.dart` |
| `kAzurePronunciationAssessmentLocales` + `kAzureDefaultLocaleByPrimary` | `lib/core/application/app_language_catalog.dart` |
| `kPronounceSupportedLocales` + `kPronounceDefaultLocaleByPrimary` | `lib/features/pronounce/domain/pronounce_locale.dart` |
| 10-branch localized label ladder | `lib/core/presentation/language_labels.dart` |

The cross-module invariants nothing enforced: the pronounce allowlist is
set-identical to the lookup catalog (worker parity), focus ⊆ lookup, native ⊆
lookup, lookup ⊆ the Azure assessment table, and both broad-tag default maps
map every catalogued primary to that primary's first regional variant.

## Decision

1. **ONE descriptor table** — `kLanguageDescriptorRows` in
   [`lib/core/application/language_descriptor.dart`](../../lib/core/application/language_descriptor.dart):
   one const row per language carrying tag, static lookup label, and focus /
   native / pronounce membership. `azureAssessment` defaults to `true` (every
   row today is assessable; the flag is only written to *exclude* a row), so
   assessment-only rows carry nothing but a tag and stay distinguishable by
   `lookupLabel == null`.
2. **A non-null `lookupLabel` *is* lookup membership** — the row's endonym
   label derives both `kSupportedLookupLanguageTags` and
   `kLookupLanguageLabels`, so "every lookup tag has a label" holds by
   construction.
3. **Every existing structure derives from the table.** All public names,
   shapes, contents, and orders are unchanged (collections go `const` →
   `final`; no consumer used them in const contexts). The pronounce allowlist
   and its primary→default map derive in `pronounce_locale.dart`; the
   localized label map in `language_labels.dart` derives its **keys** from the
   rows (focus ∪ native, table order) — only the tag → getter dispatch is
   hand-written, and a covered row without a case throws instead of silently
   missing.
4. **Broad-tag defaults derive from row order**: within a primary subtag the
   default regional variant is listed first, and `firstTagPerPrimary` makes
   that convention the rule for both `kAzureDefaultLocaleByPrimary` (first
   focus-or-native row per primary) and `kPronounceDefaultLocaleByPrimary`
   (first pronounce row per primary). Row order is load-bearing, not cosmetic.
   `firstTagPerPrimary` resolves primaries through the one shared
   `primaryLanguageSubtag` helper rather than restating the split.
5. **Shared tag parsing lives with the rows.** `splitLanguageTag`,
   `primaryLanguageSubtag`, and the `kLanguageTagAliases` policy map live in
   `language_descriptor.dart` (the descriptor cannot import the catalog, so
   the helpers moved the other way); `app_language_catalog.dart` re-exports
   them so existing consumers keep their imports, and the separator regex
   exists exactly once.
6. **The enumerating pin tests became derivation checks**: counts,
   focus/native ⊆ lookup, lookup ⊆ Azure, pronounce == lookup (worker parity
   policy), default maps stay inside their primary, localized getters cover
   exactly focus ∪ native, assessment-only (argless) rows stay in the Azure
   set, plus ADR-0087 spot-asserts (nb-NO everywhere, nn-NO nowhere).
7. **Unchanged seams**: `kLanguageTagAliases` stays a standalone policy map
   (ADR-0087 — standalone in *shape*, now homed in `language_descriptor.dart`
   next to the helper that consumes it); `packages/forced_alignment` stays
   app-import-free with its `==` pin test as the package boundary
   (ADR-0071/0072); `.arb` files and gen-l10n are untouched (the localized
   getters keep pointing at the same gen-l10n members).

## Consequences

- **Positive**: adding a language is one row (plus `.arb` entries and the
  worker / alignment rollouts those deployments gate); forgetting a surface is
  a missing row flag, visible in one place.
- **Positive**: the previously unenforced pronounce↔lookup equality is now a
  visible, deliberate pin rather than an accident.
- **Trade-off**: reordering a catalog (e.g. putting `en-GB` first) now also
  moves that primary's broad-tag default, because decision 4 derives defaults
  from row order. The convention is documented on the table and the derivation
  tests keep defaults pinned to catalogued primaries.
- **Trade-off**: derived collections are `final`, not `const` — any future
  const-context use (default parameter values, const spreads) would need the
  underlying literal back. None existed at refactor time.

## Alternatives considered

- *Keep parallel literals and add more pin tests* — rejected; pins detect
  drift after the fact instead of removing the ability to drift, and every
  addition still edits four modules.
- *Derive the table from one of the existing lists* — rejected; the lists
  carry only tags, so label / membership / default knowledge would still need
  a second home. The row is the smallest structure that carries all of it.
- *Move the localized (.arb) getters into the descriptor row* — rejected;
  `core/application` stays l10n-free; the seam stays in
  `language_labels.dart`, but its map keys derive from the rows and only the
  tag → getter dispatch (which throws on a missing case) is hand-written.

## Artifacts

- [#794](https://github.com/baizhiheizi/enjoy_player/issues/794) —
  architecture review; this is candidate 1
- [ADR-0042](0042-multi-language-lookup-catalog.md) — catalog *separation*
  this preserves (pickers still draw from their own derived lists)
- [ADR-0087](0087-norwegian-bokmal-language-catalog.md) — the nb-NO rollout
  that motivated this; alias policy and spot-asserts carried forward
