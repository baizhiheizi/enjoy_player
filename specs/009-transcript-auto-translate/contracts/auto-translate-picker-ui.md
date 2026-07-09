# Contract: Subtitle Picker — Auto Translate

**Feature**: [spec.md](../spec.md) · **Plan**: [plan.md](../plan.md) · **Data model**: [data-model.md](../data-model.md)

UI contract for the translation section of the subtitle track picker
(`showSubtitleTrackPicker` / `SubtitleTrackPickerSheet`). Presentation remains
sheet (narrow) or centered dialog (≥ rail breakpoint) — unchanged chrome.

## Translation section option order

When a primary transcript exists (or tracks list is non-empty enough to show
sections), the **Translation** radio group MUST present options in this order:

1. **None** — existing `NoneOptionTile` (`secondaryTranscriptId = null`)
2. **Auto translate** — new dedicated option (not a generic `TrackOptionTile`)
3. **Other translation tracks** — existing tracks **excluding** the
   `source: 'ai'` auto-translate artifact (to avoid duplicate selectors)

If Auto translate is unavailable (no primary yet), the Auto translate row MAY
remain visible but disabled with a short reason, or hidden with empty-state
guidance — prefer **visible + disabled + reason** for discoverability (SC-001).

## Auto translate option appearance

| Element | Contract |
|---------|----------|
| Label | Localized “Auto translate” (ARB) |
| Meta | Target reading language chip (native language display) |
| Badge | Distinct from official/auto/user — reuse **AI** provider badge semantics (`subtitlesProviderAi` / secondary container colors) or an equivalent “Auto” badge that cannot be confused with YouTube `auto` captions |
| Delete | **Not** on the Auto translate option row (deleting the underlying AI track, if offered, is a separate control on the AI artifact or via Re-translate/clear flows) |
| Selected summary | Collapsed `SelectionSummary` MUST read as Auto translate + language, not as a generic unnamed track |

## Selection behavior

| Action | Result |
|--------|--------|
| Select Auto translate (eligible) | `secondaryTranscriptId` → AI track id; scheduler starts/resumes; progressive secondary lines appear in transcript panel |
| Select Auto translate (ineligible) | Do **not** silently no-op: show friendly blocked reason (sign-in, same language, no primary, credits) with next step |
| Select None | Clear secondary; pause/cancel Auto translate job for this media |
| Select another track | Set secondary to that track id; pause Auto translate job |
| Select Auto translate again later | Reuse persisted AI timeline; only schedule empty/failed-eligible lines |

## Re-translate affordance

| Rule | Contract |
|------|----------|
| Visibility | Only when Auto translate is the **active** translation selection |
| Placement | Within ≤2 taps from the open picker (tile action, section action, or actions list) |
| Confirm | Required when the AI track is largely complete **and** line count is large (threshold defined in implementation tasks; e.g. ≥50 ready lines); skip confirm for empty/tiny jobs |
| Effect | Increment job generation; clear AI line texts (or rebuild skeleton); reschedule with playback-priority; playback stays usable |
| Copy | Localized; no raw exceptions |

## Progress / error copy (picker + transcript)

| State | Contract |
|-------|----------|
| Starting / running | Compact non-blocking status (banner or summary chip) — must not replace the whole transcript list |
| Partial | Completed lines visible; pending lines calm |
| Blocked / failed | Friendly title + hint + Retry or Re-translate; **no** raw exception as primary message |
| Auth | Align with existing `AuthRequiredCallout` / sign-in deep link patterns used by lookup translation |

## Non-goals (this contract)

- Changing primary-section radio behavior
- Replacing YouTube bilingual auto-selection of a native caption track
- Per-job target language picker in the translation list (v1)
