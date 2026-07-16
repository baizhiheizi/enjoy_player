# Research: Profile Update Form

**Feature**: [spec.md](./spec.md) · **Plan**: [plan.md](./plan.md)  
**Date**: 2026-07-16

## Decision 1: Enjoy ID is `UserProfile.id`

**Decision**: Display `profile.id` as Enjoy ID on the hero and edit form (example `24000001`). Do not derive it from email or invent a separate field.

**Rationale**: The profile API already returns `id` as a string. Spec examples match this. No backend change required for FR-001.

**Alternatives considered**:
- Parse digits from synthetic `{id}@enjoy.bot` email — fragile and unnecessary.
- Wait for a dedicated `enjoyId` field — over-scoped; `id` is already the Enjoy ID.

---

## Decision 2: Dedicated `/profile/edit` route (not Preferences)

**Decision**: Add `GoRoute(path: 'edit')` under `/profile` → `ProfileEditScreen`. Preferences (`/profile/preferences`) loses the username field and keeps goal/languages/display locale.

**Rationale**: Spec explicitly separates identity editing from learning preferences. Mirrors the existing preferences child-route pattern (Scaffold + AppBar over shell).

**Alternatives considered**:
- Expand Preferences into tabs — mixes two jobs; harder to explain.
- Modal sheet for edit — weaker for multi-field + avatar pick on desktop; harder keyboard/back stack.

---

## Decision 3: Username maps to existing `name` / `UpdateProfileRequest.name`

**Decision**: No new “username” API field. Form label can say “Username” (or localized equivalent) while persisting via `PATCH /api/v1/profile` `{ user: { name } }` as today.

**Rationale**: Backend only validates presence of `name`. Client already saves name this way from Preferences.

**Alternatives considered**:
- Unique handle system — out of scope per Assumptions; would need enjoy_web schema work.

---

## Decision 4: Avatar via Active Storage direct upload (#227 resolved)

**Decision**: Implement `DirectUploadsApi` (`POST /api/v1/direct_uploads` → PUT bytes → `PATCH` `user.avatar` signed_id) behind `AuthRepository.updateAvatar`. Client preflight: **2 MiB**, JPEG/PNG/WebP. Never claim success without server confirmation (FR-006).

**Rationale**: [baizhiheizi/enjoy_web#227](https://github.com/baizhiheizi/enjoy_web/issues/227) closed with this contract; profile JSON also returns `mixin_id`.

**Alternatives considered**:
- Multipart on profile only — not what the server shipped.
- Client-only avatar — breaks cross-device sync.

---

## Decision 5: Image picking via existing `file_picker`

**Decision**: Use `file_picker` with image type filters for all supported platforms (same dependency as library import). No new `image_picker` dependency unless mobile camera capture is later required (out of scope — gallery/file is enough).

**Rationale**: Already pinned (`12.0.0-beta.4`, ADR-0029). Cross-platform file selection matches desktop needs better than mobile-only image_picker.

**Alternatives considered**:
- `image_picker` — mobile-centric; extra dep; camera not requested.
- Platform channels — unnecessary.

---

## Decision 6: Mixin ID display vs `hasMixin`

**Decision**: Add optional `UserProfile.mixinId`. UI shows the ID when non-null/non-empty; otherwise a localized “not linked” state. Keep parsing `hasMixin` for backward compatibility but do not invent IDs from it.

**Rationale**: Spec FR-010. Current jbuilder only emits `has_mixin`. #227 requests `mixin_id` exposure.

**Alternatives considered**:
- Show “Linked” boolean only — fails the “display Mixin ID” requirement.
- Hardcode placeholder IDs in demos — forbidden by FR-010.

---

## Decision 7: Hero entry affordance

**Decision**: Make the hero identity area (or an explicit Edit control on/near the card) navigate to `/profile/edit`. Keep Upgrade CTA behavior for Free tier unchanged.

**Rationale**: FR-009. Tapping the identity card is the natural “edit me” pattern; an additional Settings-style row is acceptable as backup if tap targets conflict with Upgrade.

**Alternatives considered**:
- Only a list row below the card — slightly less discoverable for avatar/name.
- Deep-link only — fails discoverability.

---

## Decision 8: Email remains read-only in the player

**Decision**: Display email on the edit form; do not offer in-app email change in this feature (even though PATCH currently accepts `email` in strong params).

**Rationale**: Spec Assumptions; email change usually needs verification (web `ProfilesController#update_email` flow). Avoid half-broken email edits.

**Alternatives considered**:
- Wire PATCH email from the form — security/UX risk without verification UX.

---

## Decision 9: No ADR at plan time

**Decision**: Document behavior in `docs/features/auth.md` only. Revisit a thin ADR only if the final #227 upload mechanism introduces a reusable client pattern worth locking (e.g. mandatory direct_uploads + attach).

**Rationale**: Constitution ADR threshold is costly-to-reverse architecture/product-scope. This is primarily IA + API consumption within auth.

---

## Resolved Technical Context unknowns

| Topic | Resolution |
|-------|------------|
| Enjoy ID source | `UserProfile.id` |
| Edit surface | New `/profile/edit` |
| Avatar transport | Abstracted; blocked on #227 |
| Image picker | `file_picker` |
| Mixin ID | Optional `mixinId`; not-linked fallback |
| Agent context script | Not present in `.specify/scripts` — skipped |
