# Contract: Profile API (client consumption)

**Feature**: [spec.md](../spec.md) · **Plan**: [plan.md](../plan.md)

> Client-facing HTTP contracts for Enjoy Player. Server: [enjoy_web#227](https://github.com/baizhiheizi/enjoy_web/issues/227) (**resolved**). Wire JSON is camelCase after `ApiClient` decode.

---

## C1. `GET /api/v1/profile`

**Client**: `AuthApi.profile()` → `AuthRepository.fetchProfile()` → `UserProfile.fromJson`

| JSON key | Domain | Notes |
|----------|--------|--------|
| `id` | `UserProfile.id` | Enjoy ID string |
| `name` | `name` | Username |
| `email` | `email` | May be synthetic |
| `avatarUrl` | `avatarUrl` | Absolute HTTPS URL after raster helper |
| `hasMixin` | `hasMixin` | Boolean |
| `mixinId` | `mixinId` | String when linked; null when not |

**Invariants**:

- Client MUST tolerate absent `mixinId` (show not-linked).
- Client MUST NOT fabricate `mixinId` from `hasMixin == true`.

---

## C2. `PATCH /api/v1/profile` — username

```http
PATCH /api/v1/profile
Authorization: Bearer <access_token>
Content-Type: application/json

{ "user": { "name": "New Name" } }
```

**Response**: Same shape as GET profile.

**Invariants**: Empty/blank name fails client validation before request. On success, repository caches profile. Edit profile MUST NOT send email from this screen.

---

## C3. Avatar update (Active Storage direct upload)

**Flow**:

1. `POST /api/v1/direct_uploads` with blob metadata (filename, byte_size, checksum = Base64 MD5, content_type).
2. `PUT` file bytes to `directUpload.url` with `directUpload.headers`.
3. `PATCH /api/v1/profile` with `{ "user": { "avatar": "<signed_id>" } }`.

**Constraints** (server):

- Content types: `image/jpeg`, `image/png`, `image/webp`
- Max size: **2 MiB**
- Blank `avatar` (`""`) clears attachment and resets default `avatarUrl`

**Client**: `DirectUploadsApi` + `AuthRepository.updateAvatar` + `AuthController.updateAvatar`.

**Invariants**:

- Success response MUST include usable `avatarUrl` (or client re-GETs profile).
- Failures surface as `AuthFailure` / `ApiException`; UI MUST NOT claim success.
- Client preflight MUST match 2 MiB + allowed MIME before network.

---

## C4. Cached profile snapshot

**Store**: `SecureTokenStore` cached profile JSON.

**Invariants**: Successful name or avatar update MUST rewrite cache.
