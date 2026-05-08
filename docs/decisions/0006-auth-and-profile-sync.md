# ADR-0006: Auth, profile, and settings sync (browser flow)

## Status

Accepted

## Context

ADR-0005 excluded cloud sync and auth from MVP v1. The product now needs optional Enjoy account sign-in for premium features, a profile surface, and keeping learner settings (locale, languages) aligned with the server profile.

## Decision

1. **Supersedes ADR-0005** only for: optional **authentication**, **user profile** fetch/update, and **settings sync** (locale / learning / native language and API base URL stored locally). Library media sync, recording upload pipelines, and streaming remain out of MVP unless a later ADR says otherwise.

2. **Auth mechanism (v1):** browser-redirect flow only — `POST /api/v1/sessions/start_auth` then poll `GET /api/v1/sessions/poll` after the user completes sign-in in the system browser (`url_launcher`).

3. **Tokens:** `flutter_secure_storage` for the bearer access token; no raw tokens in Drift `settings` KV.

4. **API client:** `package:http` with JSON + camelCase ↔ snake_case transforms to match the existing `@enjoy/api` TypeScript client behavior.

5. **Profile cache:** last known `UserProfile` JSON may be stored in Drift under `auth.last_profile` for fast cold-start UI; server is source of truth on refresh.

## Consequences

- Requires network permission on platforms that enforce it; base URL is user-configurable (Settings → Advanced) with a documented default.
- `GoRouter` uses a small `ChangeNotifier` refresh hook so redirect re-evaluates when auth state changes.
- Audio/video/transcript/recording REST clients may be added alongside auth without wiring sync until a follow-up ADR/feature.
