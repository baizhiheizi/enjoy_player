# Feature Specification: Path-Only Local Media

**Feature Branch**: `019-path-only-local-media`

**Created**: 2026-07-16

**Status**: Draft

**Input**: User description: "Import local media by linking to the source file instead of copying it into Enjoy storage, to avoid duplicating disk usage. When the source is moved or removed, guide the user to pick the file again and re-link after validating the content fingerprint. Must work on all supported platforms (Android, iOS, macOS, Windows, Linux)."

## Clarifications

### Session 2026-07-16

- Q: When opening a linked local file that still exists, how should Enjoy decide the content is still trustworthy? → A: Cheap trust check on open (size / mtime when available); full fingerprint only if that check fails, or at import / re-link.
- Q: When the user imports a local file whose content fingerprint already exists for their library, what should happen? → A: Reuse the existing library item (same user + fingerprint); refresh the playable reference if needed and open it.
- Q: When deleting a library item, should Enjoy delete an app-managed media copy? → A: Delete app-managed copies with the library item; never delete externally linked source files.
- Q: On mobile vs desktop, when should Enjoy link vs copy? → A: All platforms: prefer lasting link when available; otherwise durable app-managed copy.
- Q: Should this feature reclaim storage from legacy always-copied library items? → A: Out of scope: leave legacy copies as-is; no reclaim/migration UI in this feature.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Import without doubling disk use (Priority: P1)

A learner imports a large local video or audio file from their device. Enjoy adds it to the library and can play it, without creating a second full-size copy of the file when the platform allows lasting access to the original.

**Why this priority**: Storage duplication is the core pain (especially for multi‑GB videos on desktop). Fixing import behavior delivers the main value even before relocate UX improvements.

**Independent Test**: Import a known large local file on a platform that supports lasting file access; confirm the library item plays and that Enjoy’s app media storage does not grow by approximately the full file size.

**Acceptance Scenarios**:

1. **Given** the user is signed in and chooses Import → local audio or video, **When** they pick a supported file on a platform that can keep lasting read access to that file, **Then** the item appears in the library, plays successfully, and Enjoy does not store a second full copy of the media bytes in app media storage.
2. **Given** the same import flow, **When** the platform cannot grant lasting read access to the picked file, **Then** import still succeeds and the item remains playable after app restart (the app may retain a durable copy in app-managed storage so the feature works on every supported platform).
3. **Given** a file that was already imported (same content fingerprint for the same signed-in user), **When** the user imports it again, **Then** Enjoy reuses the existing library item (no second row), refreshes the playable reference if needed without creating an unnecessary extra full-size media copy, and opens that item.

---

### User Story 2 - Re-link when the source file is missing (Priority: P1)

A learner opens a library item whose linked local file was moved, renamed, or deleted. Enjoy explains that the media file is missing and lets them pick the file again. After the content fingerprint matches, playback works from the new location without forcing an unnecessary full re-copy when lasting access is available.

**Why this priority**: Path-linked media will go missing more often than app-owned copies; without re-link, the feature is incomplete and libraries become unusable.

**Independent Test**: Import (or seed) an item with a fingerprint and a `local` path, delete or move the file, open the player, complete Locate with the correct file, and confirm playback resumes from the new location.

**Acceptance Scenarios**:

1. **Given** a local library item whose source file is no longer readable at the stored location and whose content fingerprint is known, **When** the user opens that item, **Then** they see a clear “locate / re-link media file” experience instead of a generic playback failure.
2. **Given** that locate experience, **When** the user picks a file whose content fingerprint matches the library item, **Then** Enjoy updates the link to the new location and playback starts (without creating a second full-size copy when lasting access is available).
3. **Given** that locate experience, **When** the user picks a file whose content fingerprint does not match, **Then** Enjoy rejects the file with a clear message, leaves the previous link unchanged, and does not replace the library item with the wrong media.

---

### User Story 3 - Reliable behavior on every supported platform (Priority: P2)

The same import and re-link flows work on Android, iOS, macOS, Windows, and Linux. Users are never blocked from importing local media solely because a platform cannot keep an external path forever; Enjoy adapts storage strategy per platform while keeping the same user-facing steps.

**Why this priority**: Cross-platform parity is an explicit product requirement; desktop path-linking alone would strand mobile users or regress import reliability.

**Independent Test**: Run the import + open + (optional) relocate scenarios on each supported platform family (at least one desktop OS and one mobile OS in manual verification), confirming success paths and missing-file relocate.

**Acceptance Scenarios**:

1. **Given** a supported desktop platform (macOS, Windows, or Linux), **When** the user imports a local file from a normal filesystem path, **Then** Enjoy links to that path without duplicating the full media when lasting access is available.
2. **Given** a supported mobile platform (Android or iOS), **When** the user imports a local file through the system picker and lasting access can be obtained, **Then** Enjoy links without a full duplicate; **When** lasting access cannot be obtained, **Then** import still completes via durable app-managed copy and remains playable after force-quit and relaunch.
3. **Given** any supported platform, **When** a previously linked file becomes unreadable, **Then** the same locate + fingerprint-match re-link flow is available.

---

### User Story 4 - Delete and cloud metadata stay coherent (Priority: P3)

A learner deletes a library item or views cloud-synced metadata for local media. Removing an item does not require deleting the user’s original source file outside Enjoy. Cloud sync continues to treat on-device file locations as device-local (not uploaded as the media body).

**Why this priority**: Prevents accidental data loss and keeps sync semantics aligned with local-first design; secondary to import/relocate.

**Independent Test**: Delete a path-linked item and confirm the original source file still exists on disk; confirm cloud “add to library” / sync metadata items still use locate when no local file is present.

**Acceptance Scenarios**:

1. **Given** a path-linked local item (external source), **When** the user deletes it from Enjoy’s library, **Then** the library row is removed and the user’s original source file outside Enjoy is left untouched.
2. **Given** a local item whose playable reference is an app-managed copy, **When** the user deletes it from Enjoy’s library, **Then** the library row is removed and Enjoy also removes that app-managed media copy.
3. **Given** cloud metadata for local-only media on a device with no playable local file, **When** the user opens that item, **Then** they can use the locate + fingerprint match flow (same as today for synced rows without a local file).

---

### Edge Cases

- What happens when the linked file still exists but was replaced in place? On open, Enjoy runs a cheap trust check (stored size and, when available, last-modified). If that check fails, Enjoy treats the file as untrusted and presents locate / re-link; full fingerprint validation runs during import, re-link, and whenever the cheap check fails—not as a full hash on every successful open.
- What happens when the user picks a supported extension that is unreadable (permissions revoked, network drive offline, external volume ejected)? Open uses the locate flow when a fingerprint exists; otherwise a clear failure message.
- What happens with very large files (multi‑GB)? Import MUST remain usable (progress/busy UI; UI stays responsive) and MUST NOT roughly double disk usage when linking succeeds without a copy.
- What happens for media that has no external source file (e.g. crafted/synthesized audio written by Enjoy)? Those items continue to live in app-managed storage; this feature does not force them to an external path.
- What happens for YouTube (and other non-local) items? Unchanged — no local path linking.
- What happens to items already imported under the old “always copy into app media” behavior? They keep working as-is; this feature does not require bulk migration, mass deletion of old copies, or a reclaim/migration UI. Reclaim of legacy duplicates is explicitly out of scope.
- How does the feature behave across Android, iOS, macOS, Windows, and Linux input patterns? Same import chooser and locate UI; every platform prefers lasting link when available and falls back to durable copy only when lasting access cannot be obtained.
- What happens when deleting an item that used an app-managed copy? Enjoy removes the library row and that internal copy. Externally linked originals are never deleted by Enjoy.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: When importing a user-picked local audio or video file, the system MUST record a durable playable reference for that item and a content fingerprint suitable for later re-link validation.
- **FR-002**: On every supported platform, when lasting read access to the picked file can be obtained, import MUST link to that source and MUST NOT create a second full-size copy of the media in Enjoy’s app media storage.
- **FR-003**: On every supported platform, when lasting read access cannot be obtained, import MUST still succeed by retaining a durable playable copy in app-managed storage so the item remains playable after app restart.
- **FR-004**: Opening a local library item MUST verify that the stored playable reference is still readable before starting playback.
- **FR-004a**: When the playable reference is readable, opening MUST also apply a cheap trust check against stored size and, when available, last-modified metadata. Full content fingerprint verification MUST run at import, at re-link, and when the cheap trust check fails—not as a full hash on every successful open.
- **FR-005**: If the playable reference is missing, unreadable, or fails the cheap trust check, and a content fingerprint exists, the system MUST present the locate / re-link media flow instead of failing silently.
- **FR-006**: Re-link MUST accept a newly picked file only when its content fingerprint matches the library item’s stored fingerprint; on mismatch, the previous reference MUST remain unchanged and the user MUST see a clear error.
- **FR-007**: When re-link succeeds and lasting access is available, the system MUST update the playable reference to the new location without creating an unnecessary second full-size copy.
- **FR-008**: When re-link succeeds but lasting access is not available, the system MUST still make the item durably playable (app-managed copy allowed).
- **FR-009**: Deleting a library item MUST remove Enjoy’s library record. If the playable reference is an app-managed media copy, Enjoy MUST also delete that copy. If the playable reference is an externally linked source file, Enjoy MUST NOT delete that external file. Related non-media app artifacts (e.g. generated thumbnails) MAY be removed as appropriate.
- **FR-010**: Cloud sync MUST continue to treat on-device playable locations as device-local; sync MUST NOT require uploading the full local media body as part of this change.
- **FR-011**: Content language selection, supported file-type rejection, import busy UI, and post-import navigation to the player MUST remain available and behaviorally consistent with today’s local import UX.
- **FR-012**: The import and re-link behaviors defined above MUST work on all supported platforms: Android, iOS, macOS, Windows, and Linux.
- **FR-013**: When the user imports a local file whose content fingerprint already matches an existing library item for that signed-in user, the system MUST reuse that item (no second library row), MAY refresh its playable reference and trust metadata, MUST NOT create an unnecessary extra full-size media copy, and MUST open the existing item.

### Quality, UX, and Performance Requirements

- **QR-001**: Implementation MUST preserve Enjoy Player's feature-first architecture and avoid feature-to-feature shortcuts unless the plan documents an exception.
- **QR-002**: Changed behavior MUST have automated tests or a documented manual verification reason.
- **QR-003**: User-facing strings, controls, haptics, tooltips, and keyboard affordances MUST follow existing localization and shared UI patterns.
- **QR-004**: Import of a multi‑GB local file on desktop MUST keep the UI responsive (no multi-second freeze of the main window) while hashing / linking; locate + fingerprint validation for a multi‑GB file MUST likewise keep the UI responsive.
- **QR-005**: Feature behavior changes MUST update the matching documentation under `docs/features/` (library and player locate flows at minimum).
- **QR-006**: An ADR MUST record the platform-adaptive link-vs-copy decision (costly to reverse; affects storage and mobile reliability).

### Key Entities

- **Local library media item**: Audio or video entry with title, content language, size, optional last-modified trust metadata, content fingerprint, and a device-local playable reference.
- **Playable reference**: The on-device location Enjoy uses to open the media (external linked source when lasting access exists; otherwise an app-managed durable copy).
- **Content fingerprint**: Stable hash of media bytes used to identify the same file across re-link and duplicate-import avoidance.
- **Locate / re-link request**: User action to pick a file again when the playable reference is missing, unreadable, or fails fingerprint trust checks.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: On any supported platform where lasting access succeeds, importing a local media file of size S does not increase Enjoy’s app media storage by approximately S (growth attributable to full media duplication is under 5% of S, excluding small sidecar artifacts such as thumbnails).
- **SC-002**: After import, users can start playback of the new item within the existing import UX (busy dialog dismisses and player opens) without a separate “copy finished” wait that scales with full file size when linking without copy.
- **SC-003**: When the linked file is removed or fails the cheap trust check, 100% of such items that still have a content fingerprint present the locate flow on open; after a successful fingerprint-matched re-link, playback succeeds on the first open following re-link.
- **SC-004**: Fingerprint mismatch on re-link never replaces the library item’s media with the wrong file (0 incorrect replacements in acceptance testing).
- **SC-005**: Import and re-link succeed on each supported platform family (Android, iOS, macOS, Windows, Linux) in the verification plan; when lasting access is unavailable, mobile/desktop items that used the copy fallback remain playable after app restart.
- **SC-006**: Deleting a path-linked item never deletes the user’s original external source file in acceptance testing; deleting an app-managed-copy item also removes that internal copy so Enjoy’s media storage does not retain orphaned full-size files for that item.
- **SC-007**: Existing already-copied library items continue to open and play without requiring the user to re-import them.
- **SC-008**: Re-importing the same local file for the same user results in a single library item (no duplicate row) in acceptance testing.

## Assumptions

- Supported platforms remain Android, iOS, macOS, Windows, and Linux (no Flutter web).
- “Lasting read access” means the OS still allows Enjoy to read the same picked file after process restart without asking the user again; when that cannot be guaranteed, retaining an app-managed copy is an acceptable and required fallback so import never becomes platform-broken. This prefer-link-then-copy rule applies uniformly on Android, iOS, macOS, Windows, and Linux (not “always copy on mobile”).
- The existing chunked content fingerprint already used for local media identity and relocate validation remains the fingerprint for re-link (no new identity scheme).
- Crafted / synthesized media and other app-generated bytes stay in app-managed storage; they are out of scope for external path linking.
- YouTube and remote URL playback are out of scope.
- Previously imported full copies under app media storage are left as-is (no mandatory cleanup, migration, or reclaim UI in this feature). A future feature may offer reclaim; it is not part of this change.
- Sync continues to exchange metadata only for local files; ActiveStorage / full media upload is not introduced here.
- The existing Locate media file UI pattern is reused and extended as needed rather than inventing a separate product flow.
