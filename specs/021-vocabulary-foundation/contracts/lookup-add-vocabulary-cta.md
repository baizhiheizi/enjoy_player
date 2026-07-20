# UI Contract: Lookup Add-to-Vocabulary CTA

**Implements**: FR-001–FR-005, FR-014, FR-016 · [spec.md](../spec.md)

## Surface

Mount an **Add to Vocabulary** control on the existing dictionary lookup sheet (`dictionary_lookup_sheet.dart`), visible without waiting for AI dictionary results (offline capture).

Suggested placement: sheet chrome next to copy/close, or directly under the selected-term hero.

## Inputs

From the open lookup session:

| Input | Source |
|-------|--------|
| Selected text | `LookupRequest.selectedText` |
| Source language | Effective sheet source (picker may override) |
| Target language | Effective sheet target; default = native preference (existing resolution) |
| Persistable media context | Structured builder at open or on tap (media id, type, text, locator) |

Lookup language catalogs and picker behavior remain unchanged (ADR-0042 / multilang lookup contracts).

## Control states

| State | Label (EN intent) | Action |
|-------|-------------------|--------|
| Not in book | Add to Vocabulary | `addWithContext` → create item + context |
| In book, new context | Add Context | `addWithContext` → append context |
| Exact context exists | Already in Vocabulary | Offer remove **whole item** (confirm) |
| Busy | Adding… / Removing… | Disable; ignore duplicate taps |

State derivation:

1. Normalize selection; compute item id from word + effective source + target.
2. If no item → **Not in book**.
3. If item and no duplicate locator for current media context → **Add Context**.
4. If item and duplicate locator → **Already in Vocabulary**.

Recompute when sheet languages change (source/target picker / swap) or after successful mutation.

## Delete

- Confirm dialog before delete (localized).
- Cancel → no change.
- Confirm → cascade delete item (persistence contract); control returns to **Add to Vocabulary**.

## UX / a11y

- Use existing Enjoy tappable primitives; tooltip where icon-only.
- Localized ARB strings for all four states + confirm delete copy.
- Busy state must prevent double-submit creating parallel items.
- Do not block playback engine; keep work on short async DB calls.

## Change surface (expected)

| Area | Change |
|------|--------|
| `LookupRequest` / `transcript_lookup_open` | Pass media linkage / structured context |
| `dictionary_lookup_sheet` | Mount CTA; wire languages + busy |
| `vocabulary` presentation/application | Control + providers |
| `lib/l10n` | New keys |
| Widget tests | State matrix + confirm cancel/confirm |

## Out of scope

- Vocabulary shell route / stats / list
- Review session / keyboard shortcuts
- Persisting dictionary/contextual AI onto entities from review tabs (later phase)
- Ebook selection toolbar
- Home due widget
- Changing lookup catalog membership
