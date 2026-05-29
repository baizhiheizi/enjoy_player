## ADDED Requirements

### Requirement: Escape dismisses transient UI before any route navigation

The system SHALL handle the `modal.close` action (default binding: Escape) as a scoped dismissal key that closes overlays and aborts in-progress capture before considering route navigation.

#### Scenario: Hotkeys cheatsheet is open

- **WHEN** the user presses Escape while the hotkeys cheatsheet dialog is open
- **THEN** the system SHALL close the cheatsheet
- **AND** SHALL NOT pop the player route

#### Scenario: Desktop window is fullscreen

- **WHEN** the user presses Escape on desktop while the application window is fullscreen
- **THEN** the system SHALL exit fullscreen
- **AND** SHALL NOT pop the player route unless a subsequent Escape dismisses an overlay

#### Scenario: Navigator overlay is open

- **WHEN** the user presses Escape while a modal bottom sheet or dialog is presented on the Navigator stack
- **THEN** the system SHALL pop the top overlay route
- **AND** SHALL NOT pop the underlying GoRouter page (including `/player/...`)

### Requirement: Escape cancels active shadow-reading capture

The system SHALL treat Escape as cancel for an in-progress shadow-reading recording before any route navigation.

#### Scenario: Recording is active on expanded player

- **WHEN** the user presses Escape while shadow-reading capture is active
- **THEN** the system SHALL discard the in-progress recording
- **AND** SHALL NOT collapse or pop the player route

#### Scenario: Recording becomes active

- **WHEN** the user starts shadow-reading capture
- **THEN** the system SHALL mark recording as active for Escape handling before asynchronous microphone initialization completes

### Requirement: Escape does not collapse the expanded player as a fallback

The system SHALL NOT pop the player GoRouter route when Escape is pressed on `/player/...` and no dismissible layer from the transient-UI rules applies.

#### Scenario: Expanded player with no overlay

- **WHEN** the user presses Escape on `/player/:mediaId` with no open cheatsheet, fullscreen, recording, or Navigator overlay
- **THEN** the system SHALL perform no navigation
- **AND** SHALL NOT call `GoRouter.pop()` for the player route

#### Scenario: Expanded player after overlay dismissed

- **WHEN** the user presses Escape to close the last open overlay on the player route
- **THEN** the system SHALL leave the expanded player open
- **AND** SHALL NOT collapse the player on that same key press unless the overlay dismissal itself was the only action

### Requirement: Escape may pop non-player routes when no overlay remains

The system SHALL allow Escape to pop the GoRouter stack when the current route is not under `/player/` and no transient UI layer applies.

#### Scenario: Pushed non-player route

- **WHEN** the user presses Escape on a non-player route (for example a pushed sign-in screen) with no open overlay
- **THEN** the system SHALL pop the GoRouter route when `canPop` is true

### Requirement: Player collapse uses explicit navigation actions

The system SHALL collapse the expanded player only through explicit user actions, not through the Escape fallback.

#### Scenario: Collapse button

- **WHEN** the user activates the collapse control in expanded player chrome
- **THEN** the system SHALL exit desktop fullscreen if active
- **AND** SHALL set player UI mode to mini
- **AND** SHALL pop the player GoRouter route

#### Scenario: Toggle expand hotkey on player route

- **WHEN** the user triggers `player.toggleExpand` while on `/player/:mediaId`
- **THEN** the system SHALL perform the same collapse sequence as the collapse button

#### Scenario: Toggle expand hotkey off player route

- **WHEN** the user triggers `player.toggleExpand` while not on `/player/:mediaId` and a playback session exists
- **THEN** the system SHALL navigate to the expanded player route for the active session

### Requirement: Escape handling is documented for users

The system SHALL document that Escape closes overlays and cancels recording but does not collapse the expanded player when no overlay is open.

#### Scenario: Hotkeys cheatsheet lists Escape behavior

- **WHEN** the user opens the keyboard shortcuts cheatsheet
- **THEN** the Escape entry SHALL describe overlay dismissal and recording cancel
- **AND** SHALL NOT describe Escape as collapsing the expanded player
