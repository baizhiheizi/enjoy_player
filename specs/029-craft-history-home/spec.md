# Feature Specification: Craft History & First-Class Entry

**Feature Branch**: `029-craft-history-home`

**Created**: 2026-07-23

**Status**: Draft

**Input**: User description: "User should be able to view the craft history, even to edit them. And we should make the craft the first-class feature in our app. Make an independent craft button next to the import on home. Also make a hotkey `c` for it. The 自制 is not a good translate for craft, we need a better name for it. It's an important feature."

**Related**: [010-craft-from-text](../010-craft-from-text/spec.md) | [011-craft-studio-redesign](../011-craft-studio-redesign/spec.md) | [028-craft-voice-express](../028-craft-voice-express/spec.md)

## Scope

### In scope

- Promote Craft to a **first-class Home entry** with a dedicated control next to Import that opens Craft without the import chooser.
- Add a global keyboard shortcut **`c`** that opens Craft when shortcuts are allowed (not while the user is typing in a text field).
- Provide a **dedicated Craft history** experience listing the learner’s **saved** Craft items (not the full mixed library).
- Allow **editing** a history item by reopening it in Craft with content prefilled; the learner revises and saves again.
- Retire the Chinese product name **自制** in favor of keeping the English word **Craft** on Chinese UI surfaces (title, badge, home button, import row).

### Out of scope

- Persisting unfinished Craft drafts (mid-capture / mid-rewrite sessions).
- Adding Craft as a new top-level app shell tab alongside Home / Discover / etc.
- Editing or listing non-Craft library media from Craft history.
- Changing English product naming (remains **Craft**).
- Offline Craft creation (existing connectivity rules unchanged).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Open Craft from Home in one step (Priority: P1)

A learner wants to capture a new practice item. On Home they see a **Craft** control next to **Import**. They tap Craft and land directly in Craft Studio ready to create. They do not need to open Import and hunt for a secondary row.

**Why this priority**: Craft is a core product surface; burying it under Import understates its importance and adds friction to the primary create loop.

**Independent Test**: From Home with a populated or empty library, activate the Craft control and confirm Craft Studio opens without showing the import chooser first.

**Acceptance Scenarios**:

1. **Given** the learner is on Home, **When** they look at the header actions, **Then** they see a Craft control adjacent to Import with comparable prominence.
2. **Given** the learner is on Home, **When** they activate the Craft control, **Then** Craft Studio opens immediately.
3. **Given** the learner opens Craft from Home, **When** Craft Studio appears, **Then** they can start a new create flow (Express or Advanced) without extra navigation.

---

### User Story 2 - Open Craft with the `c` shortcut (Priority: P1)

A desktop learner builds Craft items often. With focus not in a text field, they press **`c`** and Craft Studio opens. The shortcut is discoverable in the app’s keyboard shortcuts help/settings like other global shortcuts.

**Why this priority**: Keyboard access matches the “first-class” goal for frequent creators on desktop.

**Independent Test**: From Home (or another screen where global shortcuts apply), press `c` without typing in a field and confirm Craft opens; focus a text field, press `c`, and confirm it types the letter instead of navigating.

**Acceptance Scenarios**:

1. **Given** global shortcuts are active and no text field has focus, **When** the learner presses `c`, **Then** Craft Studio opens.
2. **Given** a text field has focus, **When** the learner presses `c`, **Then** the character is typed (or otherwise handled by the field) and Craft does not open.
3. **Given** the shortcuts help or bindings UI, **When** the learner looks up Craft, **Then** the default binding shows as `c` and can be rebound like other shortcuts.

---

### User Story 3 - Browse Craft history (Priority: P2)

A learner has saved several Craft items over time. From Craft Studio they open **history** and see a Craft-branded list of those saved items (title or text snippet, ordered by recency). The list does not mix in YouTube or file imports. If they have never saved a Craft item, they see a clear empty state that encourages creating one.

**Why this priority**: History makes Craft a durable personal corpus, not a fire-and-forget generator.

**Independent Test**: With at least two saved Craft items and one non-Craft library item, open Craft history and confirm only Craft items appear, newest first; with zero Craft items, confirm the empty state.

**Acceptance Scenarios**:

1. **Given** the learner is in Craft Studio, **When** they open history, **Then** they see a list limited to their saved Craft items.
2. **Given** multiple Craft items exist, **When** history opens, **Then** items appear ordered by recency (most recent first) with enough label (title or snippet) to recognize each item.
3. **Given** the library contains Craft and non-Craft media, **When** the learner views Craft history, **Then** non-Craft media do not appear.
4. **Given** the learner has no saved Craft items, **When** they open history, **Then** an empty state explains there is no history yet and offers a path back to create.

---

### User Story 4 - Edit a Craft item from history (Priority: P2)

From history, the learner selects an item. Craft opens with the item’s learning text (and available source/raw text, language, and voice/style choices when known) prefilled. They edit the text or options, regenerate audio, and save. The result remains a Craft library item they can practice. Saving updates the same item they opened rather than leaving a confusing duplicate when identity is clear.

**Why this priority**: “View history” without edit still leaves learners stuck rewriting from scratch when a phrase needs a fix.

**Independent Test**: Open a known Craft item from history, change a word in the target text, regenerate and save, then confirm practice plays the updated audio and history still shows that item with the updated content.

**Acceptance Scenarios**:

1. **Given** a saved Craft item in history, **When** the learner selects it, **Then** Craft opens in an edit session with target text prefilled from that item.
2. **Given** an edit session, **When** source/raw text, languages, voice, or style were stored with the item, **Then** those fields are prefilled when available; missing optional fields use sensible Craft defaults.
3. **Given** an edit session, **When** the learner changes text or options and completes save, **Then** they get playable Craft audio suitable for practice.
4. **Given** the learner saved from an edit session opened from a specific history item, **When** they return to history, **Then** that item reflects the update (same item updated/replaced) rather than an unexplained extra copy of the prior version.

---

### User Story 5 - Craft branding without 自制 (Priority: P3)

A Chinese-locale learner sees **Craft** (Latin script) as the product name on the Craft screen title, library Craft badge, Home Craft button, and the Import chooser Craft row. The word **自制** no longer appears on those product surfaces. English UI continues to say Craft.

**Why this priority**: Naming is product-facing and was called out as important, but entry and history deliver more functional value first.

**Independent Test**: Switch the app to Chinese, visit Home, Craft, Import chooser, and a Craft library card; confirm product-facing labels use Craft and do not use 自制.

**Acceptance Scenarios**:

1. **Given** the app UI language is Chinese, **When** the learner views the Craft screen title, Home Craft control, library Craft badge, and Import Craft row, **Then** each uses **Craft** (not 自制).
2. **Given** the app UI language is English, **When** the learner views the same surfaces, **Then** labels remain Craft / Craft-from-text style phrasing as today (wording may be tightened for the Home button).
3. **Given** Chinese UI, **When** the learner opens the Import chooser, **Then** the Craft row remains available (discoverability from Library Import) with wording that uses Craft rather than 自制.

---

### Edge Cases

- Learner presses `c` while already on Craft Studio → stay on Craft (or no-op navigation); do not stack duplicate confusing screens.
- Learner deletes a Craft item from the library while history is open → history refreshes or removes the missing item without crashing; selecting a deleted item shows a calm “no longer available” outcome.
- Edit session where stored voice/style is no longer valid for the language → fall back to defaults and keep the text editable.
- Very long Craft text → same length limits and notices as existing Craft create flows.
- Empty library but Craft CTA still visible on Home → Craft opens for first create; history empty state applies until first save.
- Hotkey rebound by the user → custom binding opens Craft; default documentation reflects `c` until rebound.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Home MUST show an independent Craft control next to Import that opens Craft Studio without requiring the import chooser.
- **FR-002**: Activating the Home Craft control MUST open the same Craft experience used for creating new Craft items.
- **FR-003**: The product MUST provide a default global shortcut of bare **`c`** that opens Craft Studio when global shortcuts are allowed.
- **FR-004**: The Craft shortcut MUST NOT fire while the user is typing in a text field (same policy as other global letter shortcuts).
- **FR-005**: The Craft shortcut MUST appear in the app’s shortcut help/bindings surfaces and MUST be rebindable like other global shortcuts.
- **FR-006**: Craft Studio MUST offer a way to open a Craft history view.
- **FR-007**: Craft history MUST list only saved Craft library items belonging to the learner (Craft provenance), not the full mixed library.
- **FR-008**: Craft history MUST present each entry with a recognizable label (title or text snippet) and recency-oriented ordering (most recent first).
- **FR-009**: Selecting a history entry MUST open an edit session in Craft with the item’s target/learning text prefilled.
- **FR-010**: Edit sessions MUST prefill source/raw text, languages, voice, and style when that information is available for the item; otherwise use Craft defaults.
- **FR-011**: From an edit session, the learner MUST be able to change content/options, regenerate audio, and save a playable Craft library item.
- **FR-012**: Saving from an edit session opened from a history item MUST update or replace that same library item when identity is clear, rather than leaving an unexplained duplicate of the prior version.
- **FR-013**: When the learner has no saved Craft items, history MUST show an empty state that leads back into creating a new Craft item.
- **FR-014**: Chinese-locale product surfaces for Craft (screen title, Home control, library badge, Import Craft row) MUST use the English word **Craft** and MUST NOT use **自制**.
- **FR-015**: The Import chooser MUST continue to expose a Craft entry (reworded for Craft branding) so Library Import remains a discovery path.
- **FR-016**: This feature MUST NOT require unfinished mid-flow Craft drafts to persist across leaving Craft.

### Key Entities

- **Craft media item**: A saved library practice item created through Craft (audio plus associated text/transcript metadata the learner can practice).
- **Craft history entry**: A presentation of a Craft media item in the Craft history list (label, recency).
- **Craft edit session**: Craft Studio opened against an existing Craft media item with fields prefilled for revision and re-save.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Learners reach Craft from Home in one activation (one click/tap) without opening Import.
- **SC-002**: On desktop, learners with global shortcuts enabled open Craft with a single `c` keypress when not typing in a field, in under 1 second of perceived navigation.
- **SC-003**: Learners who have at least one saved Craft item can open history and reopen a chosen item for edit in under 30 seconds.
- **SC-004**: After edit → save, learners can practice the updated audio as a normal Craft library item on the next open.
- **SC-005**: In Chinese UI, 100% of Craft product-facing labels listed in FR-014 show **Craft** and 0% show **自制** on those surfaces.
- **SC-006**: In usability checks, at least 9 of 10 testers correctly identify Craft as reachable from Home without using Import.

## Assumptions

- The library remains the system of record for saved Craft items; history is a Craft-filtered view of those items, not a separate content store.
- “Edit” means reopen-and-revise saved items only; unfinished Express/Advanced drafts are not retained when the learner leaves Craft (unchanged from prior Craft specs).
- Import chooser keeps a Craft row for discoverability from Library Import; Home is the primary entry.
- Chinese short labels use the Latin word **Craft** (e.g. Home button “Craft”, badge “Craft”, title “Craft”; Import row may read “Craft…” or “从文本 Craft…” — prefer the shortest clear form that still signals create-from-text where needed).
- Hotkey scope is global, consistent with other app-wide navigation shortcuts, and respects existing “don’t steal keystrokes from text fields” behavior.
- Re-save from history prefers updating/replacing the opened item; planning may refine the exact persistence mechanics as long as FR-012’s user-visible outcome holds.
- Home is the required first-class surface; Library header may later gain a matching Craft control for parity but is not required for this specification’s acceptance.
- Existing Craft create flows (Express and Advanced), practice playback, and library delete behavior remain available and are not redesigned except as needed for history edit entry and branding.
