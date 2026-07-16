# Feature Specification: Profile Update Form

**Feature Branch**: `020-profile-update-form`

**Created**: 2026-07-16

**Status**: Draft

**Input**: User description: "User need to upload their own avatar, we need to make to form for it. currently, we put the username edit in the preferences, but it's not quite right. We should have a profile update form, username, avatar, and display more current profile information, like Enjoy ID, email, mixin ID etc. Some of them are editable, some of them are not. And also, the profile card should display the Enjoy ID instead of the email, like 24000001. Help me to redesign it. Help if the API is not ready, check the local repo `~/dev/enjoy_web`, open an issue in remote `baizhiheizi/enjoy_web` for it. don't edit across projects."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Profile card shows Enjoy ID (Priority: P1)

As a signed-in user, when I open the Profile tab I see my avatar, display name, subscription tier, and my **Enjoy ID** (for example `24000001`) on the identity card — not my email address as the secondary line.

**Why this priority**: This is a small, visible identity fix that does not depend on avatar upload APIs and immediately improves how users recognize their account.

**Independent Test**: Sign in, open Profile, confirm the hero card secondary line is the Enjoy ID numeric string and not the email.

**Acceptance Scenarios**:

1. **Given** the user is signed in with Enjoy ID `24000001`, **When** they open the Profile tab, **Then** the identity card shows that Enjoy ID as the secondary identity line under the name.
2. **Given** the user is signed in, **When** they view the identity card, **Then** the email is not shown as the secondary line on that card.
3. **Given** the Enjoy ID is available from the account profile, **When** the card renders, **Then** the ID is shown in a clear, copy-friendly form (plain digits / identifier text, not a mailto-style address).

---

### User Story 2 - Dedicated profile update form (Priority: P1)

As a signed-in user, I can open a dedicated **Edit profile** experience (separate from learning/display preferences) where I can change my username and avatar, and see read-only account identity fields: Enjoy ID, email, and Mixin ID (when linked).

**Why this priority**: Username currently lives under Preferences, which mixes identity editing with language/goal settings. Separating identity editing is the core redesign.

**Independent Test**: From Profile, open Edit profile, verify editable vs read-only fields, change username, save, and see the updated name on the Profile card.

**Acceptance Scenarios**:

1. **Given** the user is on the Profile tab, **When** they choose to edit their profile (entry from the identity area or a clear Edit profile action), **Then** a dedicated profile update screen/form opens (not the Preferences / languages screen).
2. **Given** the profile update form is open, **When** the user views the fields, **Then** they see at least: avatar, username (editable), Enjoy ID (read-only), email (read-only), and Mixin ID (read-only when linked; a clear “not linked” state when absent).
3. **Given** the user changes their username to a valid non-empty value and saves, **When** the save succeeds, **Then** the new username appears on the Profile identity card and the form shows success feedback.
4. **Given** the user is on Preferences, **When** they view that screen, **Then** username editing is no longer the primary identity-edit surface there (username belongs on the profile update form).
5. **Given** the user opens Preferences after this redesign, **When** they adjust learning/display preferences (daily goal, languages), **Then** those preference controls remain available and functional.

---

### User Story 3 - Upload and update avatar (Priority: P1)

As a signed-in user, I can pick a photo from my device, preview it as my new avatar, and save it so my profile (and other avatar surfaces that use the account avatar) show the new image.

**Why this priority**: Avatar upload is an explicit product request and the main reason the edit form must exist beyond renaming.

**Independent Test**: Open Edit profile, choose an image, save, confirm the Profile card (and sidebar account chip when present) show the new avatar after refresh/save.

**Acceptance Scenarios**:

1. **Given** the user is on the profile update form, **When** they choose a supported image from the device, **Then** they see a local preview of the new avatar before or as part of saving.
2. **Given** a valid image selection and a working avatar-update capability, **When** the user saves, **Then** the new avatar persists and appears on the Profile identity card.
3. **Given** the avatar-update capability is unavailable or the upload fails, **When** the user tries to save an avatar change, **Then** they see a clear error and their previous avatar remains until a successful save.
4. **Given** the user cancels image picking or leaves without saving, **When** they return to Profile, **Then** their avatar is unchanged.

---

### User Story 4 - Clear editable vs read-only identity (Priority: P2)

As a signed-in user, I can tell at a glance which profile fields I can change and which are account facts I can only view (and optionally copy).

**Why this priority**: Prevents confusion and support burden around immutable identifiers.

**Independent Test**: Open the profile update form and verify controls: username and avatar are interactive; Enjoy ID, email, and Mixin ID are not editable inputs.

**Acceptance Scenarios**:

1. **Given** the profile update form is open, **When** the user inspects Enjoy ID, email, and Mixin ID, **Then** those fields are not editable text fields (display-only rows, with copy affordance where useful).
2. **Given** Mixin is not linked, **When** the form shows Mixin ID, **Then** it communicates that Mixin is not linked rather than inventing a fake ID.
3. **Given** the user only wants to view identity details, **When** they open Edit profile without changing anything, **Then** they can dismiss/back out without side effects.

---

### Edge Cases

- **Missing or synthetic email**: Some accounts may use a synthetic Enjoy email; the form still shows whatever email the account profile returns, read-only.
- **Avatar picker cancelled / permission denied**: Show a recoverable message; do not clear the existing avatar.
- **Oversized or unsupported image**: Reject with a clear message before or after upload attempt; keep prior avatar.
- **Offline / network failure on save**: Show failure feedback; do not claim success; allow retry.
- **Backend avatar API not ready**: Client may ship Enjoy ID display + username-on-edit-form first; avatar control is present but save path clearly indicates upload is unavailable until the API ships (or avatar save is gated until the endpoint exists).
- **Long username**: Truncate gracefully on the Profile card; form validation still requires a non-empty trimmed name.
- **Concurrent profile refresh**: After save or pull-to-refresh, form and card stay consistent with the latest profile snapshot.
- **Cross-platform pickers**: Image picking works on Android, iOS, macOS, Windows, and Linux with platform-appropriate file/photo selection; unsupported cases show a clear message.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The Profile identity card MUST show the user's Enjoy ID (account `id`, e.g. `24000001`) as the secondary identity line instead of email.
- **FR-002**: The product MUST provide a dedicated profile update form/screen for account identity editing, separate from Preferences (languages / daily goal / display language).
- **FR-003**: The profile update form MUST allow editing **username** (display name) and **avatar**.
- **FR-004**: The profile update form MUST display as read-only: **Enjoy ID**, **email**, and **Mixin ID** (or a clear not-linked state).
- **FR-005**: Username MUST remain required (non-empty after trim) and persist through the existing profile update capability when saved.
- **FR-006**: Avatar changes MUST persist through a server-backed avatar update capability once available; until then the client MUST not silently pretend an upload succeeded.
- **FR-007**: After a successful username or avatar save, the Profile identity card (and other signed-in avatar/name chrome that already shows the account profile) MUST reflect the updated values without requiring a full app restart.
- **FR-008**: Preferences MUST stop being the primary place to edit username; learning/display preference controls remain on Preferences.
- **FR-009**: Profile MUST expose a clear entry point into the profile update form (e.g. tap identity card or an Edit profile action).
- **FR-010**: When Mixin ID is unavailable from the account profile payload, the UI MUST show a not-linked / unavailable state rather than inventing an ID.
- **FR-011**: Failed saves (validation, network, unsupported image, missing API) MUST surface user-visible error feedback and leave prior saved profile data intact.
- **FR-012**: Users MUST be able to dismiss the profile update form without saving and return to the Profile tab with no unintended changes.

### Quality, UX, and Performance Requirements

- **QR-001**: Implementation MUST preserve Enjoy Player's feature-first architecture and avoid feature-to-feature shortcuts unless the plan documents an exception.
- **QR-002**: Changed behavior MUST have automated tests or a documented manual verification reason (identity card Enjoy ID, form field editability, username save, avatar happy-path and failure-path when API exists).
- **QR-003**: User-facing strings, controls, haptics, tooltips, and keyboard affordances MUST follow existing localization and shared UI patterns.
- **QR-004**: Opening the profile update form and saving username MUST feel responsive (form interactive within 1 second on a warm session; save feedback within 3 seconds under normal network conditions). Avatar upload feedback MUST show in-progress state for longer uploads.
- **QR-005**: Feature behavior changes MUST update the matching documentation under `docs/features/` (auth/profile).

### Key Entities

- **Account profile**: Signed-in user's identity snapshot — Enjoy ID, username, avatar, email, Mixin linkage/ID, subscription and preference fields already used elsewhere.
- **Profile update form**: Dedicated edit surface for identity (editable username + avatar; read-only Enjoy ID, email, Mixin ID).
- **Preferences**: Separate surface for learning/display preferences (goal, languages) — not the home for username/avatar after this redesign.
- **Profile identity card**: Top-of-Profile summary showing avatar, username, Enjoy ID, and subscription cues.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In usability checks, 9/10 signed-in testers correctly identify their Enjoy ID on the Profile card within 5 seconds without opening email-related UI.
- **SC-002**: Users can open Edit profile and change username successfully in under 60 seconds on a warm signed-in session.
- **SC-003**: When avatar upload is available, users can complete pick → preview → save and see the new avatar on Profile within one save cycle (no app reinstall/restart).
- **SC-004**: 100% of read-only fields on the profile update form (Enjoy ID, email, Mixin ID) are not editable in manual QA.
- **SC-005**: Preferences no longer presents username as its primary editable identity field; testers looking for “change my name/avatar” find the profile update form on the first try in guided QA.
- **SC-006**: Failed avatar or profile saves never leave the UI claiming success while the server still has the old values (verified in failure-injection QA).

## Assumptions

- **Enjoy ID** is the account profile `id` string already returned by the profile API (example format `24000001`).
- **Username** maps to the existing profile display name field (`name`); no separate unique handle system is introduced in this feature.
- **Email** and **Mixin ID** are view-only in the player for this redesign; changing email or linking/unlinking Mixin is out of scope.
- **Preferences** retains daily goal and language controls; only identity editing (username/avatar + identity display) moves to the profile update form.
- **Backend dependency**: As of 2026-07-16, `enjoy_web` profile update does not support avatar upload, and the profile payload exposes Mixin linkage as a boolean without the Mixin ID value. Tracking issue: [baizhiheizi/enjoy_web#227](https://github.com/baizhiheizi/enjoy_web/issues/227). Client work may ship Enjoy ID display and the form shell/username save first; avatar persistence and Mixin ID display depend on that API.
- Default avatar behavior (provider photo or generated default) remains until the user successfully uploads a replacement.
- Sidebar / other chrome that already shows avatar + name continues to use the same account profile snapshot after refresh/save.
