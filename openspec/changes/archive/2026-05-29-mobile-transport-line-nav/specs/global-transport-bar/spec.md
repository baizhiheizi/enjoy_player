# global-transport-bar Specification

## Purpose

Priority-based visibility and width budgeting for the global transport bar on narrow viewports, ensuring previous/next line controls remain available for language-learning workflows without row overflow, second rows, or overflow menus.

## ADDED Requirements

### Requirement: Narrow layout is a single control row

When the viewport width is at or below `breakpointTranscriptSideBySide` (720 logical pixels), the transport bar SHALL present playback and tool controls in one horizontal row below the progress strip.

#### Scenario: No second row on narrow player

- **WHEN** the user is on a narrow viewport with an active playback session on `/player/...`
- **THEN** the transport bar SHALL NOT add a second row of icon controls for line navigation or tools
- **AND** SHALL NOT use an overflow “more” menu button to hide primary line navigation

### Requirement: Previous and next line controls are shown on narrow when transcript exists

On narrow layouts, the transport bar SHALL show previous-line and next-line controls whenever the active media has a loaded primary transcript with at least one line.

#### Scenario: Prev and next visible on typical phone width

- **WHEN** the viewport width is at or below 720px
- **AND** the viewport width is at least 320 logical pixels
- **AND** `hasTranscriptLines` is true for the active session
- **AND** the user is on `/player/...` (no expand control in the bar)
- **THEN** the transport bar SHALL display previous-line and next-line icon buttons
- **AND** they SHALL be enabled unless playback is buffering

#### Scenario: Prev and next hidden without transcript

- **WHEN** the viewport width is at or below 720px
- **AND** `hasTranscriptLines` is false
- **AND** echo mode is not active
- **THEN** the transport bar SHALL NOT display previous-line or next-line icon buttons

#### Scenario: Prev and next disabled while buffering

- **WHEN** previous-line and next-line buttons are visible
- **AND** playback is buffering
- **THEN** those buttons SHALL be disabled

### Requirement: Replay control is omitted on narrow layouts

On narrow layouts, the transport bar SHALL NOT show the replay-line icon button.

#### Scenario: No replay button on phone

- **WHEN** the viewport width is at or below 720px
- **AND** `hasTranscriptLines` is true
- **THEN** the transport bar SHALL NOT display the replay-line icon button

#### Scenario: Replay remains on wide layout

- **WHEN** the viewport width is above 720px
- **AND** `hasTranscriptLines` is true
- **THEN** the transport bar SHALL display the replay-line icon button alongside previous-line and next-line controls

### Requirement: Narrow layout uses compact control budgeting

On narrow layouts, the transport bar SHALL compute control visibility from available width using compact slot sizing and a fixed priority order so the row does not overflow.

#### Scenario: No horizontal overflow at 320px on player route

- **WHEN** the viewport width is 320 logical pixels
- **AND** the user is on `/player/...` with an active session and transcript lines
- **THEN** the transport control row SHALL lay out without horizontal overflow exceptions
- **AND** previous-line and next-line buttons SHALL still be present

#### Scenario: Mini transport defers expand before line navigation

- **WHEN** the viewport width is at or below 720px
- **AND** the user is not on `/player/...` (mini transport with expand control)
- **AND** available width is insufficient for expand plus previous-line, next-line, play, and core tools
- **THEN** the transport bar SHALL omit the expand control before omitting previous-line or next-line
- **AND** SHALL omit volume before omitting previous-line or next-line when further deferral is required

#### Scenario: Core tools retain priority over volume on tight mini bar

- **WHEN** the viewport width is at or below 720px
- **AND** the user is not on `/player/...`
- **AND** available width fits previous-line, next-line, play, echo, CC, and speed but not volume and expand
- **THEN** the transport bar SHALL show echo, CC, and speed
- **AND** SHALL defer volume and expand according to the priority order

### Requirement: Wide layout preserves full line and tool set

When the viewport width is above `breakpointTranscriptSideBySide`, the transport bar SHALL continue to show previous-line, next-line, and replay-line controls together with secondary tools, using horizontal scroll for secondary tools when needed.

#### Scenario: Wide layout shows replay

- **WHEN** the viewport width is above 720px
- **AND** `hasTranscriptLines` is true
- **THEN** the transport bar SHALL display previous-line, next-line, and replay-line controls in the primary control group

### Requirement: Line navigation actions are unchanged

Prev/next/replay buttons SHALL continue to invoke the existing `PlayerInteractions` line navigation methods and respect echo-mode enablement rules.

#### Scenario: Prev invokes prevLine

- **WHEN** the user taps the previous-line control while it is enabled
- **THEN** the system SHALL call `PlayerInteractions.prevLine()`

#### Scenario: Next invokes nextLine

- **WHEN** the user taps the next-line control while it is enabled
- **THEN** the system SHALL call `PlayerInteractions.nextLine()`
