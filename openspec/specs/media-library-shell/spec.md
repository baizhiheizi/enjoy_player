# media-library-shell Specification

## Purpose

Unified Library shell navigation that combines local media and remote cloud index browsing under one destination, with explicit Local/Cloud source switching and consolidated mobile/desktop nav.

## Requirements

### Requirement: Library is a single shell destination for local and cloud media

The system SHALL expose one Library destination in the main navigation shell that covers both local Drift media and remote Enjoy cloud index browsing.

#### Scenario: Mobile bottom navigation shows four items

- **WHEN** the viewport width is below the rail breakpoint and the user is not on the player route
- **THEN** the bottom navigation SHALL display exactly four destinations: Home, Discover, Library, and Settings
- **AND** SHALL NOT display Cloud as a separate bottom navigation item

#### Scenario: Desktop sidebar shows Library without separate Cloud row

- **WHEN** the viewport width is at or above the rail breakpoint and the user is not on the player route
- **THEN** the sidebar SHALL include a Library navigation item
- **AND** SHALL NOT include a separate Cloud navigation item

#### Scenario: Library nav item is selected for cloud deep links

- **WHEN** the current route is `/cloud` or `/library` with any valid `source` query
- **THEN** the Library navigation item SHALL appear selected

### Requirement: Library screen provides Local and Cloud source switching

The system SHALL provide a source control on the Library screen with exactly two modes: Local and Cloud.

#### Scenario: Default source is Local

- **WHEN** the user navigates to `/library` without a `source` query parameter
- **THEN** the Library screen SHALL display Local source content
- **AND** the Local source option SHALL appear selected

#### Scenario: User switches to Cloud source

- **WHEN** the user selects Cloud on the source control
- **THEN** the system SHALL navigate to `/library?source=cloud`
- **AND** SHALL display Cloud source content
- **AND** SHALL preserve the current Audio or Video kind selection

#### Scenario: User switches back to Local source

- **WHEN** the user selects Local on the source control while Cloud is active
- **THEN** the system SHALL navigate to `/library` or `/library?source=local`
- **AND** SHALL display Local source content

#### Scenario: Legacy cloud route redirects

- **WHEN** the user navigates to `/cloud`
- **THEN** the system SHALL redirect to `/library?source=cloud`

### Requirement: Library screen header and toolbar adapt to source mode

The system SHALL adjust the Library screen header and primary toolbar action based on the active source.

#### Scenario: Local source shows Import action

- **WHEN** Local source is active
- **THEN** the Library header trailing action SHALL offer Import media
- **AND** SHALL NOT show the Cloud refresh action as the primary trailing control

#### Scenario: Cloud source shows Refresh action

- **WHEN** Cloud source is active and the user is signed in
- **THEN** the Library header trailing action SHALL offer Refresh for the active cloud tab
- **AND** SHALL NOT show Import as the primary trailing control

#### Scenario: Cloud source shows editorial subtitle

- **WHEN** Cloud source is active
- **THEN** the Library header SHALL display a cloud eyebrow subtitle above the title
- **AND** the main title SHALL remain the Library title string

### Requirement: Audio and Video kind filtering applies within each source

The system SHALL provide Audio and Video kind filtering below the source control for both Local and Cloud modes.

#### Scenario: Local audio and video lists

- **WHEN** Local source is active
- **THEN** the system SHALL display local audio items in Audio kind
- **AND** SHALL display local video items in Video kind
- **AND** SHALL use the same list and grid presentation as the prior standalone Library screen

#### Scenario: Cloud audio and video lists

- **WHEN** Cloud source is active and the user is signed in
- **THEN** the system SHALL display remote audio items in Audio kind
- **AND** SHALL display remote video items in Video kind
- **AND** SHALL support pagination and Add to library actions as on the prior standalone Cloud screen

### Requirement: Local search is scoped to Local source

The system SHALL provide library search only when Local source is active.

#### Scenario: Compact search on mobile Local mode

- **WHEN** Local source is active and viewport width is below the rail breakpoint
- **THEN** the Library screen SHALL show the compact search field
- **AND** search SHALL filter local library items only

#### Scenario: Search hidden in Cloud mode

- **WHEN** Cloud source is active
- **THEN** the Library screen SHALL NOT show the library search field

#### Scenario: Search hotkey forces Local source

- **WHEN** the user invokes the library search hotkey from an eligible shell route
- **THEN** the system SHALL navigate to Local Library (`/library` or `/library?source=local`)
- **AND** SHALL request focus on the library search field according to existing search focus rules

#### Scenario: Sidebar search opens Local Library

- **WHEN** the user focuses the sidebar search field
- **THEN** the system SHALL navigate to Local Library if not already there
- **AND** SHALL NOT switch to Cloud source

### Requirement: Cloud source respects authentication

The system SHALL require Enjoy account sign-in to browse cloud index content.

#### Scenario: Signed-out user selects Cloud source

- **WHEN** Cloud source is active and the user is signed out
- **THEN** the system SHALL display the auth-required callout for Cloud
- **AND** SHALL keep the source control usable so the user can return to Local without signing in

#### Scenario: Signed-in user browses Cloud source

- **WHEN** Cloud source is active and the user is signed in
- **THEN** the system SHALL load and display paginated remote audio and video metadata
- **AND** SHALL allow Add to library on eligible items

### Requirement: Source transitions use editorial motion

The system SHALL animate transitions between Local and Cloud content in a way consistent with the app motion system.

#### Scenario: Animated source switch

- **WHEN** the user changes source and reduced motion is not requested
- **THEN** the system SHALL cross-fade between Local and Cloud bodies with a short ease-out transition (approximately 220ms)

#### Scenario: Reduced motion

- **WHEN** the user has requested reduced motion
- **THEN** the system SHALL switch Local and Cloud bodies without animation

### Requirement: Local-first data behavior is unchanged

The system SHALL NOT automatically copy remote cloud catalog rows into the local library as a result of this navigation change.

#### Scenario: Cloud browse does not auto-import

- **WHEN** the user browses Cloud source
- **THEN** the system SHALL NOT insert remote rows into local Drift tables unless the user explicitly chooses Add to library
