# Contract: Profile edit UI & navigation

**Feature**: [spec.md](../spec.md) · **Plan**: [plan.md](../plan.md)

> Internal UI/navigation contracts for implementers and widget tests.

---

## C1. Routes

| Path | Screen | Notes |
|------|--------|--------|
| `/profile` | `ProfileScreen` / `ProfileContent` | Tab root; hero shows Enjoy ID |
| `/profile/edit` | `ProfileEditScreen` | **NEW** — identity edit |
| `/profile/preferences` | `ProfilePreferencesScreen` | No username field |

**Invariants**:

- `/profile/edit` is a child of `/profile` (same pattern as preferences) so shell Profile tab stays selected.
- Back from edit returns to Profile tab content.
- Deep link `/profile/edit` opens the edit form when signed in; signed-out users remain gated by existing auth redirects.

---

## C2. Profile hero (`ProfileHeroCard`)

| Element | Behavior |
|---------|----------|
| Avatar | Network image or placeholder (unchanged) |
| Primary line | `profile.name` |
| Secondary line | Enjoy ID = `profile.id` (**not** email) |
| Subscription chip | Unchanged |
| Upgrade CTA | Unchanged when Free |
| Edit affordance | Tap identity area and/or explicit control → `context.push('/profile/edit')` without triggering Upgrade |

**Invariants**:

- Widget tests assert secondary text contains Enjoy ID and does not equal `profile.email` when they differ.

---

## C3. Edit profile form (`ProfileEditScreen`)

| Field | Control | Editable |
|-------|---------|----------|
| Avatar | Tappable circle + change action; local preview when picked | Yes |
| Username | `TextFormField` | Yes |
| Enjoy ID | Display row (+ optional copy) | No |
| Email | Display row (+ optional copy) | No |
| Mixin ID | Display row or “not linked” | No |

**Actions**:

- **Save**: validates username; if name dirty → `authCtrl.updateProfile(UpdateProfileRequest(name:))`; if avatar dirty and API available → `updateAvatar`; success notice; optionally pop.
- **Back / system back**: discards unsaved local preview and text edits (no PATCH).

**Invariants**:

- Read-only rows MUST NOT use enabled text editors.
- Save failure MUST NOT show success notice.
- When avatar API unavailable, attempting avatar save shows explicit error (localized).

---

## C4. Preferences (`ProfilePreferencesScreen`)

**Removed**: username / name `TextFormField` and its inclusion in Save payload.

**Retained**: daily goal, display language, learning language, native language, Save for remaining fields.

**Invariants**:

- Widget/smoke tests confirm no name field key / label for username on this screen.

---

## C5. Profile content entry

`ProfileContent` MUST expose a clear path to edit profile (hero tap and/or `SettingsRow` “Edit profile”) in addition to Preferences and Settings rows.

---

## C6. Localization keys (indicative)

New keys (exact names chosen at implement time) covering:

- Edit profile title / entry label / hint
- Username field label
- Enjoy ID / email / Mixin ID labels
- Mixin not linked
- Avatar change / upload unavailable / oversize / unsupported type
- Copy success (if copy affordance added)
- Save success (reuse or specialize existing `profileSaveSuccess`)

All three ARB locales updated together.
