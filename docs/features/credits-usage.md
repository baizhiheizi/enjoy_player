# Credits usage audit & packages

## Summary

Signed-in users can open **Profile → Credits usage** (route `/credits`) to view **read-only** AI credits consumption records returned by the Enjoy Worker `GET /credits/usages` endpoint.

**Credits packages** (one-time permanent credit top-ups) are offered on **Subscription** (`/subscription`): catalog from Rails `GET /api/v1/credits/packages`, checkout via `POST /api/v1/credits/packages/purchases`, and wallet standing from Worker `GET /credits/summary`. See [subscription.md](subscription.md).

## Behavior

- **Auth**: `/credits` requires the same session as profile; guests are redirected to sign-in (see `app_router` redirect).
- **Base URL**: Usage requests use the configured **AI API base URL** (`aiApiClientProvider`), not the Rails API URL. Package purchase uses the Rails API (`apiClientProvider`).
- **Filters**: Optional UTC `YYYY-MM-DD` start/end dates and optional service type (`tts`, `asr`, `translation`, `llm`, `assessment`), matching the web credits page.
- **Pagination**: Fixed page size (50). Next/previous adjust `offset` until a page returns fewer than `limit` rows.
- **Visual language** (ADR-0089, `docs/decisions/0089-aurora-design-language.md`): the screen is an Aurora hub page (`EnjoyPage` + `EnjoyPageKind.hub`) built from shared primitives — `EnjoyCard`, `EnjoyButton` / `EnjoyIconButton`, `EnjoyPressable`, `EnjoySectionHeader`, `EnjoyIconTile`, `EnjoyOverline`, `EmptyState` / `EnjoyIconOrb`, `EnjoyProgressRingPainter`. The screen's own code introduces no Material `Chip`, `InkWell`, `TextButton`, or `Icons.*`, and every colour comes from `EnjoyThemeTokens` role tokens. Three Material surfaces remain by design, each with its own internals: the `DropdownButtonFormField` service filter, the `RefreshIndicator` pull-to-refresh, and the wide-layout `DataTable` (whose eight heading columns each carry an `InkWell` sort target). Widget tests may therefore only assert the absence of Material chrome the screen owns — a screen-wide `findsNothing(InkWell)` cannot hold.
  - **Credits meter**: the first card on a non-empty page. A `EnjoyProgressRingPainter` ring (96px, 8px stroke) shows the share of required credits the Worker allowed, stroked with the aurora sweep gradient; a page with no denied rows swaps to a solid `scoreGood` ring with a check glyph, matching the Today's Goal ring. Beside it, an `EnjoyOverline` naming the metric ("Required" — deliberately not the page title, which `EnjoyPage` already renders directly above it), the locale-grouped total in Geist Mono, and an "N shown" caption.
  - **Filter group**: an `EnjoySectionHeader` labelled "Filters" (reusing the existing `vocabularyFilters` string, as profile and AI do for shared labels); its `trailing` slot carries the "Clear filters" `EnjoyButton.ghost` (only while a filter is active). The card holds side-by-side date fields plus the service-type dropdown.
  - **Date fields**: an `EnjoyPressable` (no ink ripple) wrapping an `InputDecorator`; the displayed value and the clear affordance use `enjoyMonoStyle`, and the clear control is an `EnjoyIconButton` rather than a raw `IconButton`.
  - **Narrow layout** (viewport &lt; 720px): each log is an `EnjoyCard` led by an `EnjoyIconTile` tinted per service type, with a locale-aware local timestamp, a `UTC · YYYY-MM-DD` audit line, an allowed/denied `_UsageBadge` pill, two neutral `_UsageMetaPill` rows (service, tier), and a three-column required / used-before / used-after summary in mono. Pagination stacks page info above full-width Previous/Next buttons.
  - **Wide layout** (viewport &ge; 720px): the same rows render as a horizontally scrollable `DataTable` with mono heading and cell text; the status column reuses `_UsageBadge`.
  - **Empty / error**: both use the shared `EmptyState` (icon orb) — inbox glyph plus "No records" for an empty page, error glyph plus a "Retry" primary action for a failed page.
- **Packages**: $2 / $5 / $50 → 200k / 500k / 5M permanent credits; does not change subscription tier. Purchase on Windows/macOS/Linux only; iOS/Android show coming soon.

## Related

- Worker routes: `GET /credits/usages`, `GET /credits/summary`
- Rails: `/api/v1/credits/packages`, `/api/v1/credits/packages/purchases`
- Spec: `specs/027-auto-renew-credit-packages/`
- Web reference: `apps/web/src/routes/credits.tsx`
