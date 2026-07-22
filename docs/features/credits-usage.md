# Credits usage audit & packages

## Summary

Signed-in users can open **Profile → Credits usage** (route `/credits`) to view **read-only** AI credits consumption records returned by the Enjoy Worker `GET /credits/usages` endpoint.

**Credits packages** (one-time permanent credit top-ups) are offered on **Subscription** (`/subscription`): catalog from Rails `GET /api/v1/credits/packages`, checkout via `POST /api/v1/credits/packages/purchases`, and wallet standing from Worker `GET /credits/summary`. See [subscription.md](subscription.md).

## Behavior

- **Auth**: `/credits` requires the same session as profile; guests are redirected to sign-in (see `app_router` redirect).
- **Base URL**: Usage requests use the configured **AI API base URL** (`aiApiClientProvider`), not the Rails API URL. Package purchase uses the Rails API (`apiClientProvider`).
- **Filters**: Optional UTC `YYYY-MM-DD` start/end dates and optional service type (`tts`, `asr`, `translation`, `llm`, `assessment`), matching the web credits page.
- **Pagination**: Fixed page size (50). Next/previous adjust `offset` until a page returns fewer than `limit` rows.
- **Mobile layout** (viewport &lt; 720px): Filter card uses side-by-side date fields with theme `InputDecoration`; each log card shows one locale-aware local timestamp, a `UTC · YYYY-MM-DD` audit line, a colored allowed/denied pill, service/tier chips, and a two-column required/used-after summary. Pagination stacks page info above full-width Previous/Next buttons.
- **Packages**: $2 / $5 / $50 → 200k / 500k / 5M permanent credits; does not change subscription tier. Purchase on Windows/macOS/Linux only; iOS/Android show coming soon.

## Related

- Worker routes: `GET /credits/usages`, `GET /credits/summary`
- Rails: `/api/v1/credits/packages`, `/api/v1/credits/packages/purchases`
- Spec: `specs/027-auto-renew-credit-packages/`
- Web reference: `apps/web/src/routes/credits.tsx`
