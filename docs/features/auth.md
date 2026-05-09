# Auth & profile (Enjoy account)

## Behavior

- Optional sign-in via **browser redirect**: `POST /api/v1/sessions/start_auth`, then the user completes auth in the system browser; the app polls `GET /api/v1/sessions/poll` until `approved` or timeout (~5 minutes).
- **Sign-in screen**: After approval the shell navigates **home** automatically; while polling, the user can **re-open browser** or **cancel**; failed loads show **network error** UI with **retry**.
- **Bearer token** is stored in **flutter_secure_storage** (not in Drift).
- Last **profile snapshot** is cached in Drift (`auth.last_profile`) for fast cold start when a token exists.
- **Profile** screen calls `GET/PATCH /api/v1/profile` with camelCase JSON; the HTTP client maps camelCase ↔ snake_case like the web `@enjoy/api` client.
- **Locale / learning / native language** from the server profile are applied to app preferences (Drift `prefs.*`) on login and profile refresh.
- **API base URL** is configurable under Settings → Advanced (`api.base_url` in Drift); default `https://enjoy.bot`.

## REST clients

Typed list/object helpers live under `lib/data/api/services/` for audios, videos, transcripts, and recordings. **Metadata sync** uses the mine endpoints for audios/videos/recordings when signed in ([features/sync.md](features/sync.md)).

## Related ADR

- [ADR-0006](../decisions/0006-auth-and-profile-sync.md)
