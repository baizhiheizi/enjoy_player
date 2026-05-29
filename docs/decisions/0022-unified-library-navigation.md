# ADR-0022: Unified Library navigation (local + cloud source)

## Status

Accepted

## Context

Mobile bottom navigation exposed five destinations (Home, Discover, Library, Cloud, Settings), crowding labels and touch targets on narrow phones. Library and Cloud screens already shared the same editorial layout (header, Audio/Video segment, `MediaCard` lists) but differed only in data source (local Drift vs remote Enjoy index). ADR-0013 keeps those data layers separate; users still need an explicit Cloud browse path without auto-import.

## Decision

1. **Merge shell navigation**: One **Library** destination on bottom nav and sidebar. Remove Cloud as a peer nav item.
2. **Source switch inside Library**: Local / Cloud segmented control above the existing Audio / Video segment. URL state via `/library` (local default) and `/library?source=cloud`.
3. **Backward compatibility**: `/cloud` redirects to `/library?source=cloud`.
4. **Context-aware chrome**: Import + search on Local; Refresh + cloud eyebrow subtitle on Cloud. Signed-out Cloud shows inline `AuthRequiredCallout`; source switch remains usable.
5. **Presentation only**: No change to sync, Drift schema, or cloud fetch APIs.

## Consequences

- Mobile bottom nav drops to four items (better ergonomics).
- Desktop sidebar loses a redundant Cloud row; cloud remains one tap away via source switch.
- Docs and deep links must prefer `/library?source=cloud`; `/cloud` remains a redirect alias.
- Future polish (e.g. "already in library" badge on cloud rows) is out of scope for this ADR.

## Related

- [ADR-0013](0013-local-first-sync.md) — local-first data separation unchanged
- [ADR-0009](0009-platform-adaptive-shell.md) — platform-adaptive shell
