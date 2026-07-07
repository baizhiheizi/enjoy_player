# Feature: Community activity (signed-in home dashboard)

## Summary

The community activity card surfaces **active learners** on the signed-in **Home** screen. It only renders for `AuthSignedIn` users (the Home body itself stays unchanged for signed-out users). The card is sourced from the same `GET /api/v1/users/active` endpoint that the web app uses, returning a small avatar roster plus an aggregated **today's practice** stat.

## MVP behavior

- **Endpoint**: `GET /api/v1/users/active`, called with the device timezone. The JSON shape is camelCase and decoded via the shared `convertKeysToCamel` helper (`lib/data/api/case_conversion.dart`).
- **Timeout**: the request uses an **8-second client timeout**; on timeout (or any other error), the card hides / shows no data rather than a retry affordance (matches web parity).
- **Variants**: `CommunityActivityCardVariant.card` (full stats + up to 8 avatars; tablet/desktop) and `CommunityActivityCardVariant.summary` (compact headline + up to 4 avatars; mobile insight strip).
- **Today stats**: when the server returns `recordingsCountToday` / `recordingsDurationToday`, the card shows the aggregated practice volume; otherwise the stat row is hidden.
- **Avatars**: rendered with `CachedNetworkImage` from `avatarUrl` (Dicebear SVG URLs are rewritten to PNG via `rasterAvatarUrl` in `lib/core/utils/avatar_url.dart` because Flutter cannot decode SVG with raster image widgets); missing avatars fall back to **initials** derived from the user's name (`_initials` in `community_activity_card.dart`).
- **Layout**: on wide viewports (≈720px+) Today's Goal and Community Activity cards share a responsive two-column row above the recent media grid; on narrow screens they stack.

## Signed-in gating

The card is only mounted on Home when `authCtrlProvider` reports `AuthSignedIn`. The Home screen otherwise renders the existing recents grid with no community / today's-goal section. No retry affordance for the community API: a transient error → empty card.

## Code map

| Area | Path |
|------|------|
| Domain models | [`lib/features/community/domain/active_user.dart`](../../lib/features/community/domain/active_user.dart) |
| Riverpod provider | [`lib/features/community/application/active_users_provider.dart`](../../lib/features/community/application/active_users_provider.dart) |
| Card UI (card + summary variants) | [`lib/features/community/presentation/community_activity_card.dart`](../../lib/features/community/presentation/community_activity_card.dart) |

## Related

- Home screen: [`docs/features/library.md`](library.md) (Home / Today's Goal block shares the responsive two-column row)
- Auth: [`docs/features/auth.md`](auth.md)
- ADR: [`docs/decisions/0010-cloud-sync-mvp.md`](../decisions/0010-cloud-sync-mvp.md)