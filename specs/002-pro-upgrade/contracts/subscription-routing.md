# Contract: Subscription Routing

**Feature**: `002-pro-upgrade` | **Consumer**: `app_router.dart`, `auth_redirect.dart` | **Version**: 1.0

## Route

| Path | Screen | Shell | Auth |
|------|--------|-------|------|
| `/subscription` | `SubscriptionScreen` | `ShellRoute` (with sidebar/bottom nav) | Required (`AuthSignedIn`) |

## Auth gate

Unsigned user navigating to `/subscription` → redirect to `/sign-in?from=subscription`.

## Post-sign-in `from` resolution

Extend `resolvePostSignInPath` and `encodeSignInFrom`:

| Shorthand | Path |
|-----------|------|
| `subscription` | `/subscription` |

Encoded full path `%2Fsubscription` also resolves to `/subscription`.

## Navigation entry points

| Source | Action |
|--------|--------|
| Profile account section | Nav tile → `context.push('/subscription')` |
| Sidebar account chip (optional) | Link or badge tap → `/subscription` |
| Credits failure notice | Primary action → `/subscription` |

## Deep links

No custom URL scheme required for v1. In-app navigation only.

## Scenarios

### S1 — Signed-out access

- **WHEN** unsigned user opens `/subscription`
- **THEN** redirect `/sign-in?from=subscription`

### S2 — Post-sign-in return

- **WHEN** user completes sign-in with `from=subscription`
- **THEN** land on `/subscription`

### S3 — Signed-in direct access

- **WHEN** signed-in user opens `/subscription`
- **THEN** render subscription screen without redirect
