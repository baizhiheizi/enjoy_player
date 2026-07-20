# Feature Specification: Vocabulary Sync & Anki Export

**Feature Branch**: `024-vocabulary-sync-anki`

**Created**: 2026-07-17

**Status**: Draft

**Input**: User description: "Continue to finish up the vocabulary feature in doc docs/features/vocabulary.md."

**Parent feature contract**: [docs/features/vocabulary.md](../../docs/features/vocabulary.md) (**P3** — Sync, **P4** — Anki export). Completes the remaining unfinished phases after local capture / SRS ([021-vocabulary-foundation](../021-vocabulary-foundation/spec.md)), Vocabulary screen / flashcard session ([022-vocabulary-screen-review](../022-vocabulary-screen-review/spec.md)), and review context richness ([023-vocabulary-context-richness](../023-vocabulary-context-richness/spec.md)). Explicitly out of scope for this finish-up: home due nudge, tags/batch import, Notes content, ebook add-from-reader, and marketing-only study modes.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Export vocabulary to Anki as Pro (Priority: P1)

As a Pro learner, I can export my vocabulary from All Words to an Anki-compatible CSV (Front / Back / Tags), optionally narrowing what is included via export filters, then save or share the file on my device so I can import it into Anki.

**Why this priority**: Anki export is the remaining acceptance criterion for declaring the vocabulary feature complete for solo learners; it is the main Pro-gated vocabulary value and matches Enjoy web.

**Independent Test**: Seed several vocabulary items with contexts and cached explanations; as Pro, open Export, apply a filter, produce a CSV, and verify Front/Back/Tags content and Pro gate for Free users — without requiring cloud sync.

**Acceptance Scenarios**:

1. **Given** the learner is Pro and has at least one vocabulary item, **When** they choose Export to Anki from All Words, **Then** they can complete an export that produces a UTF-8 CSV (with BOM) with columns Front, Back, and Tags suitable for Anki Basic notes.
2. **Given** export options / filters (parity with Enjoy web), **When** the learner narrows the set (e.g. by status or language as offered), **Then** only matching items appear in the exported file.
3. **Given** a successful export, **When** they finish the save/share flow for their platform, **Then** they obtain a file they can import into Anki without retyping cards.
4. **Given** an item with multiple contexts and cached dictionary / contextual explanations, **When** it is exported, **Then** Front merges the word and contexts per the documented Anki contract, and Back includes available IPA, definitions, translations, examples, and context translations without inventing missing AI content.
5. **Given** the learner is not Pro, **When** they attempt Export to Anki, **Then** they see a clear Pro-required explanation and a path to upgrade — export does not produce the CSV for Free tier.

---

### User Story 2 - Keep vocabulary on another device via sync (Priority: P1)

As a signed-in learner who uses Enjoy on more than one device, my vocabulary items and contexts upload and download so a word I saved or reviewed on one device appears on another, without losing the newer spaced-repetition state when both sides changed.

**Why this priority**: Multi-device continuity is the remaining phased port goal (P3); schema and IDs were designed for this from day one. Review undo history stays device-local.

**Independent Test**: Two devices (or simulated local/remote stores) with overlapping items; sync after review on one side; verify the device with newer SRS wins and contexts merge without duplicate forks for the same locator.

**Acceptance Scenarios**:

1. **Given** the learner is signed in and vocabulary sync is enabled for their account session, **When** they create or update a vocabulary item or context offline then regain connectivity, **Then** pending changes upload and become available to download on another device.
2. **Given** an item exists on both devices with different SRS fields, **When** sync merges that item, **Then** the newer review state is kept (prefer more recent last-reviewed time; otherwise higher review count), without re-keying the item id.
3. **Given** contexts for the same item, **When** sync runs, **Then** contexts upload/download with last-write-wins on update time, and identical media locators do not create duplicate context rows.
4. **Given** local review-audit / undo rows, **When** sync runs, **Then** those audit rows are never uploaded or downloaded.
5. **Given** the learner is offline, **When** they add, review, delete, or export (if Pro), **Then** local vocabulary continues to work; sync catches up when connectivity and auth allow.

---

### User Story 3 - Understand sync and export limits (Priority: P2)

As a learner, I see clear status when export needs Pro, when sync is pending or failed, and when a rich Anki back side is limited because explanations were never cached — so I am not surprised by empty backs or missing words on another device.

**Why this priority**: Trust and support load; secondary to the happy-path export and sync stories.

**Independent Test**: Trigger Free-tier export attempt, a failed sync (auth/network), and export of items without cached explanations; confirm messages and non-destructive outcomes.

**Acceptance Scenarios**:

1. **Given** Free tier, **When** Export is offered, **Then** Pro-required copy and upgrade affordance appear; core vocabulary (add/review/list) remains available.
2. **Given** sync cannot complete (network or auth), **When** the learner returns later with connectivity, **Then** pending vocabulary changes can retry without silent data loss of local rows.
3. **Given** items without cached dictionary or contextual explanations, **When** exported, **Then** the CSV still exports; Back may omit rich sections, and product copy documents that limitation where the export UI surfaces it.

---

### Edge Cases

- Empty vocabulary: Export is unavailable or produces a clear empty-state (no bogus file); sync of empty set is a no-op success.
- Very large word books: Export and sync remain usable (progress or paging as needed); no multi-minute UI freeze for ordinary library sizes on target devices.
- Delete on one device: Item delete cascades locally and queues for sync so the other device removes the item (and its contexts) after sync; server cascade expectations are documented when sync lands.
- Conflicting create of the same deterministic item id on two devices: Merge uses the documented SRS-preserving conflict rule; contexts dedupe by locator identity.
- Partial AI cache: Export never fabricates definitions or translations that were not saved.
- Ebook contexts: May appear in export/sync payloads when present in local data; titles may be unresolved (documented limitation); no ebook reader UI required in this phase.
- Subscription change mid-session: Losing Pro blocks new exports; already-created local CSV files on disk are not revoked by the app.
- Cross-platform save/share: Android, iOS, macOS, Windows, and Linux each get a sensible save or share path; no Flutter web target.
- Sync while a review session is open: Local ratings remain authoritative on that device until sync merges; undo stack stays local and is not reconstructed from the server.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: From All Words, Pro learners MUST be able to export vocabulary to an Anki Basic–compatible CSV with columns Front, Back, and Tags, UTF-8 with BOM, one card per vocabulary item (contexts merged on Front/Back per the parent Anki contract).
- **FR-002**: Export MUST support filter options with Enjoy web parity (at minimum the filters the web export dialog offers for narrowing items) before generating the file.
- **FR-003**: Export MUST be gated to Pro; Free learners MUST see Pro-required messaging and an upgrade path; Free MUST NOT receive a successful Anki CSV from this feature.
- **FR-004**: Tags MUST include vocabulary identity tags consistent with web (`vocabulary`, language pair tag, and status when not `new`) as specified in the parent feature contract.
- **FR-005**: Front/Back HTML content MUST follow the parent Anki data standard (word + contexts on Front; available IPA, translations, definitions, examples, context translations, and source refs on Back) without inventing missing cached explanations.
- **FR-006**: After CSV generation, the product MUST offer a platform-appropriate save or share path so the learner can import the file into Anki.
- **FR-007**: Signed-in learners MUST be able to sync vocabulary **items** and **contexts** (upload and download) using API-compatible ids and payloads so multi-device use does not re-key user data.
- **FR-008**: Vocabulary **review-audit / undo** records MUST remain device-local and MUST NOT be uploaded or downloaded.
- **FR-009**: Item conflict resolution MUST prefer newer SRS state (compare last-reviewed time, else higher review count), aligning with Enjoy web’s vocabulary item conflict behavior; context conflicts MUST use last-write-wins on update time.
- **FR-010**: Offline, full local add / review / list / delete MUST continue; sync enqueue and catch-up MUST run when connectivity and auth allow, without blocking core study.
- **FR-011**: Vocabulary sync scope MUST be recorded in a new architecture decision that extends or supersedes the current sync MVP (do not silently rewrite the existing media-only sync decision).
- **FR-012**: User-visible strings for export, Pro gate, upgrade, sync pending/error (where shown), and export limitations MUST be localized.
- **FR-013**: This finish-up MUST NOT require: home due widget, tags/difficulty UI, batch/manual import, Notes content beyond placeholder, ebook add-from-reader, or separate marketing “New/Review/Test” study modes.

### Quality, UX, and Performance Requirements

- **QR-001**: Implementation MUST preserve Enjoy Player's feature-first architecture and avoid feature-to-feature shortcuts unless the plan documents an exception.
- **QR-002**: Changed behavior MUST have automated tests or a documented manual verification reason — especially Anki CSV shape/Pro gate, sync upload/download, and SRS-preserving merge.
- **QR-003**: User-facing strings, controls, tooltips, and Pro/upgrade affordances MUST follow existing localization and shared UI patterns.
- **QR-004**: Export generation for typical word-book sizes and a routine sync cycle MUST stay responsive (no multi-second UI freezes on ordinary device storage); large exports MAY show progress but MUST remain cancellable or completable without crashing.
- **QR-005**: Feature behavior that lands MUST update [docs/features/vocabulary.md](../../docs/features/vocabulary.md) (P3/P4 checklist / status) and sync-related docs when vocabulary enters the sync surface.

### Key Entities *(include if feature involves data)*

- **Vocabulary item**: Word-level SRS entity; included in sync and Anki export; carries optional cached dictionary explanation used on Back.
- **Vocabulary context**: Appearance in media/ebook; included in sync; contexts for an item merge into a single Anki card; carries optional contextual translation used on Back.
- **Vocabulary review audit**: Device-local undo history; never synced.
- **Anki export set**: Filtered subset of items chosen for one CSV generation; not a persisted domain entity beyond the generated file.
- **Sync queue / syncable state**: Pending create/update/delete for items and contexts; aligns with existing app sync patterns for other entities once vocabulary is admitted.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In a guided Pro test, a learner exports a filtered vocabulary set and imports the resulting CSV into Anki (or an Anki CSV validator) with Front/Back/Tags columns and expected merged contexts on Front.
- **SC-002**: In a guided Free-tier test, Export does not produce an Anki CSV and clearly steers the learner toward Pro upgrade.
- **SC-003**: In a guided two-device (or simulated remote) test, an item added or reviewed on device A appears on device B after sync with the newer SRS fields preserved when both sides changed.
- **SC-004**: Review-audit / undo history never appears on the other device after sync; undo still works locally on the device that recorded the rating.
- **SC-005**: Export of items missing AI cache still succeeds; Back omits only unavailable rich sections (spot-check against the Anki contract).
- **SC-006**: Scope stays bounded: home due widget, ebook add, tags/batch import, and Notes content are not required for this finish-up to be done.
- **SC-007**: After this work, the parent vocabulary feature’s remaining P3/P4 acceptance items for Anki and sync can be marked complete in docs with matching automated or documented manual proof.

## Assumptions

- Phases **021–023** are prerequisites; local vocabulary, review, and cached explanations already exist for export richness and sync payloads.
- Parent phased plan **P3** (sync) and **P4** (Anki) are both in scope for this finish-up; home due widget remains a later optional enhancement.
- Pro entitlement reuses the existing subscription tier source of truth; this phase does not invent a new paywall system.
- Enjoy web Anki CSV builder and vocabulary sync conflict rules remain the behavioral reference for parity testing.
- Vocabulary REST list/upload/delete endpoints already exist on the Enjoy API as documented in the parent feature contract; the player integrates as a client.
- Deterministic item/context ids already match web generators so sync does not require a data migration of ids.
- Save/share UX follows each platform’s usual file export patterns already used elsewhere in the app when available; exact chrome may differ by OS.
- Sync of vocabulary may ship behind the same signed-in sync enablement model as other syncable entities; offline-first local use remains the default when signed out or offline.
- Ebook title resolution limitations in Anki backs are acceptable and documented in UI or feature docs, matching web.
