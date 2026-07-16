# Data Model: Profile Update Form

**Feature**: [spec.md](./spec.md) · **Plan**: [plan.md](./plan.md)

No new Drift tables. Identity remains the server-backed `UserProfile` cached in secure storage.

## Entities

### Account profile (`UserProfile`)

Existing domain model (`lib/features/auth/domain/user_profile.dart`). Fields relevant to this feature:

| Field | Type | Editable in player | Notes |
|-------|------|--------------------|--------|
| `id` | `String` | No | Enjoy ID (display as-is, e.g. `24000001`) |
| `name` | `String` | Yes | Username / display name |
| `avatarUrl` | `String?` | Yes (via upload) | Rasterized via `rasterAvatarUrl` |
| `email` | `String` | No | May be synthetic Enjoy email |
| `mixinId` | `String?` | No | **NEW** — from API when #227 ships; null → not linked |
| `hasMixin` | `bool?` | No | Existing; do not invent `mixinId` from this alone |
| `goal`, languages, locale, subscription, balance, … | … | Preferences / other surfaces | Unchanged ownership |

### Profile update request (`UpdateProfileRequest`)

Existing PATCH body builder. This feature uses:

| Field | Used by Edit profile |
|-------|----------------------|
| `name` | Yes — username save |
| `goal` / languages / `locale` | No — remain on Preferences / other flows |
| `email` | No — read-only UI |

### Avatar update request (new logical entity)

Not a Drift row. Ephemeral until server accepts:

| Attribute | Type | Notes |
|-----------|------|--------|
| Local file path / bytes | path or `Uint8List` | From `file_picker` |
| Filename / content type | string | For multipart |
| Preview URL | local file URI | Cleared on cancel / successful remote replace |

Persisted result is the updated `UserProfile.avatarUrl` from the API response, then written to the existing cached profile JSON.

### Avatar pick constraints (domain helper)

| Rule | Default (plan) |
|------|----------------|
| Max file size | **2 MiB** (matches enjoy_web `AVATAR_MAX_SIZE`) |
| Extensions | `.jpg`, `.jpeg`, `.png`, `.webp` |
| Empty / missing file | Reject before network |

## Validation rules

1. Username: trim; must be non-empty; required for save when name is the only dirty field.
2. Avatar: enforce size/extension client-side before calling repository; map server validation errors to user-visible notices.
3. Read-only fields never appear as `TextFormField` editors.
4. Saving with no dirty fields: no-op or soft “nothing to save” — must not clear avatar.
5. Cache: after successful `updateProfile` / `updateAvatar`, `AuthRepository` MUST update secure-storage profile snapshot (existing `_cacheProfile` path).

## State transitions

```text
[Profile tab]
    │ open /profile/edit
    ▼
[Edit form pristine]
    │ change name and/or pick avatar
    ▼
[Edit form dirty]
    │ save name → PATCH profile
    │ save avatar → upload API (#227)
    │ success
    ▼
[AuthSignedIn(profile') + cache']
    │ pop / back
    ▼
[Profile tab shows profile']

[Edit form dirty]
    │ back / dismiss without save
    ▼
[Profile tab unchanged]
```

Avatar preview-only (API unavailable):

```text
[pick image] → [local preview] → [Save avatar]
    → error notice (API unavailable / failure)
    → server avatarUrl unchanged
```

## Relationships

- `AuthSignedIn.profile` is the single live source for hero, sidebar chip, edit form hydration.
- Preferences reads the same profile for goal/languages but no longer owns `name`.
- Sidebar account chip continues to watch `authCtrlProvider` — no separate avatar store.
