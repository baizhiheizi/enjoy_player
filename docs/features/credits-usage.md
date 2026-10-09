# Credits usage audit & packages

## Summary

Signed-in users can open **Profile → Credits usage** (route `/credits`) to view **read-only** AI credits consumption records returned by the Enjoy Worker `GET /credits/usages` endpoint.

**Credits packages** (one-time permanent credit top-ups) are offered on **Subscription** (`/subscription`): catalog from Rails `GET /api/v1/credits/packages`, checkout via `POST /api/v1/credits/packages/purchases`, and wallet standing from Worker `GET /credits/summary`. See [subscription.md](subscription.md).

## Behavior

- **Auth**: `/credits` requires the same session as profile; guests are redirected to sign-in (see `app_router` redirect).
- **Base URL**: Usage requests use the configured **AI API base URL** (`aiApiClientProvider`), not the Rails API URL. Package purchase uses the Rails API (`apiClientProvider`).
- **Filters**: Optional UTC `YYYY-MM-DD` start/end dates and optional service type (`tts`, `asr`, `translation`, `llm`, `assessment`), matching the web credits page.
- **Pagination**: Fixed page size (50). Next/previous adjust `offset` until a page returns fewer than `limit` rows.
- **Visual language** (ADR-0093, `docs/decisions/0093-duet-design-language.md`): a Duet hub page (`EnjoyPage` + `EnjoyPageKind.hub`) built from shared primitives — `EnjoyCard`, `EnjoyButton` / `EnjoyIconButton`, `EnjoyPressable`, `EnjoyIconTile`, `EnjoyOverline`, `EmptyState`. The screen's own code introduces no Material `Chip`, `InkWell`, `TextButton`, or `Icons.*`, and every colour comes from `EnjoyThemeTokens` role tokens. Material surfaces remain only where the toolkit owns the interaction: the `RefreshIndicator` pull-to-refresh, the `MenuAnchor` / `MenuItemButton` service menu, and the platform `showDatePicker` behind the date pills.
  - **Filter group**: the "Clear filters" `EnjoyButton.ghost` (only while a filter is active) sits beside the filter pills: two date pills (`_FilterPill`, value in `enjoyMonoStyle`) opening the platform date picker, and the `_ServiceFilterPill` (label + current value + chevron) opening the service-type menu.
  - **Log list**: below the filters, a `RefreshIndicator` re-runs the query on pull.
  - **Narrow layout** (viewport &lt; 720px): each log is an `EnjoyCard` led by an `EnjoyIconTile` tinted per service type, with a locale-aware local timestamp, a `UTC · YYYY-MM-DD` audit line, an allowed/denied `_UsageBadge` pill, two neutral `_UsageMetaPill` rows (service, tier), and a three-column required / used-before / used-after summary in mono. Pagination stacks page info above full-width Previous/Next buttons.
  - **Wide layout** (viewport &ge; 720px): the logs render as a horizontally scrollable `Table` inside an `EnjoyCard` — `EnjoyOverline` headers over seven columns (Date · Time · Service · Tier · Required · Used-after · Status, numerics right-aligned in mono) — with page info and Previous / Next `EnjoyButton.secondary` beside it; the status column reuses `_UsageBadge`.
  - **Empty / error**: both use the shared `EmptyState` — "No records" for an empty page, a "Retry" action for a failed page. Loading renders skeleton cards through the shared `SkeletonTickerHost`.
- **Packages**: $2 / $5 / $50 → 200k / 500k / 5M permanent credits; does not change subscription tier. Purchase on Windows/macOS/Linux only; iOS/Android show coming soon.

## Related

- Worker routes: `GET /credits/usages`, `GET /credits/summary`
- Rails: `/api/v1/credits/packages`, `/api/v1/credits/packages/purchases`
- Spec: `specs/027-auto-renew-credit-packages/`
- Web reference: `apps/web/src/routes/credits.tsx`
