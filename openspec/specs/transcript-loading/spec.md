# transcript-loading Specification

## Purpose
TBD - created by archiving change auto-load-transcript-ui. Update Purpose after archive.
## Requirements
### Requirement: Transcript resolution runs automatically on media open

The system SHALL attempt to resolve available transcripts when the user opens a media item, without requiring manual refresh or import for sources that can be discovered automatically.

#### Scenario: Signed-in user opens media with cloud transcripts

- **WHEN** a signed-in user opens a library item that has not been cloud-fetched before
- **THEN** the system SHALL fetch transcripts from the Enjoy API or YouTube Worker in the background
- **AND** SHALL persist any returned transcript rows locally
- **AND** SHALL assign a primary transcript when none is set

#### Scenario: Local media with sidecar subtitle file

- **WHEN** the user opens local media whose playable file has an adjacent `.srt` or `.vtt` with a matching basename in the same directory
- **THEN** the system SHALL import that sidecar automatically
- **AND** SHALL assign it as primary when no primary transcript is set

#### Scenario: Tracks exist locally without primary assignment

- **WHEN** the user opens media that already has transcript rows in SQLite but no primary transcript on the latest echo session
- **THEN** the system SHALL auto-select a primary transcript using source priority (official, auto, ai, user) then earliest createdAt

### Requirement: Fetch lifecycle is observable in the application layer

The system SHALL expose a per-media transcript fetch status that includes at least: idle, loading, success, empty, and error.

#### Scenario: Background fetch starts

- **WHEN** transcript resolution begins for a media item
- **THEN** fetch status SHALL transition to loading until resolution completes or fails

#### Scenario: Fetch completes with transcripts

- **WHEN** resolution stores one or more transcript rows
- **THEN** fetch status SHALL transition to success

#### Scenario: Fetch completes with no transcripts

- **WHEN** resolution finishes and no transcript rows are available for the media item
- **THEN** fetch status SHALL transition to empty

#### Scenario: Fetch fails

- **WHEN** cloud or Worker resolution fails with an error
- **THEN** fetch status SHALL transition to error
- **AND** the system SHALL retain enough information for the UI to offer retry

### Requirement: CC control reflects transcript availability and loading

The transport CC control SHALL communicate whether subtitles are loading or available.

#### Scenario: Fetch in progress without tracks

- **WHEN** fetch status is loading and no transcript tracks exist yet
- **THEN** the CC control SHALL display a loading indicator

#### Scenario: Tracks available

- **WHEN** at least one transcript track exists for the media item
- **THEN** the CC control SHALL display the existing availability badge

#### Scenario: User opens subtitle picker from CC

- **WHEN** the user activates the CC control
- **THEN** the subtitle track picker SHALL open regardless of fetch status

### Requirement: Transcript panel distinguishes loading, empty, and error states

The transcript panel SHALL NOT present a confirmed empty state while transcript resolution is still in progress.

#### Scenario: Loading without lines

- **WHEN** fetch status is loading and the primary transcript has no cue lines yet
- **THEN** the transcript panel SHALL show a loading presentation (skeleton or fetching copy)

#### Scenario: Confirmed empty after resolution

- **WHEN** fetch status is empty or success with no primary lines and resolution is not loading
- **THEN** the transcript panel SHALL show the empty state with appropriate actions

#### Scenario: Resolution error

- **WHEN** fetch status is error and the primary transcript has no cue lines
- **THEN** the transcript panel SHALL show a friendly error message and a retry action
- **AND** SHALL NOT show raw exception text as the primary message

### Requirement: Subtitle picker shares fetch loading state

The subtitle track picker SHALL reflect background transcript resolution, not only user-initiated refresh.

#### Scenario: Background fetch while picker is open

- **WHEN** the picker is visible and fetch status is loading
- **THEN** the picker SHALL indicate that transcripts are being fetched

#### Scenario: Manual refresh from cloud

- **WHEN** the user chooses refresh from cloud in the picker
- **THEN** fetch status SHALL enter loading
- **AND** the refresh action SHALL show a loading indicator until resolution completes

### Requirement: Long-running manual transcript actions show loading feedback

Extract embedded and import subtitle actions SHALL show loading feedback consistent across the picker and transcript empty state.

#### Scenario: Extract from empty state

- **WHEN** the user starts embedded subtitle extraction from the transcript empty state
- **THEN** the extract control SHALL show a loading indicator until extraction completes

#### Scenario: Import from empty state

- **WHEN** the user starts file import from the transcript empty state
- **THEN** the import control SHALL show a loading indicator until import completes

### Requirement: Embedded subtitle extraction is not automatic on open

The system SHALL NOT automatically run ffmpeg embedded subtitle extraction when media is opened.

#### Scenario: Local video with embedded subtitles only

- **WHEN** the user opens local video that has embedded subtitle streams but no sidecar or cloud transcripts
- **THEN** the system SHALL NOT extract embedded streams automatically
- **AND** SHALL offer extract via the existing manual action

### Requirement: Cloud fetch requires signed-in session

The system SHALL NOT initiate Enjoy API or YouTube Worker transcript fetch on open when the user is not signed in.

#### Scenario: Signed-out user opens media

- **WHEN** a signed-out user opens a media item
- **THEN** the system SHALL skip cloud and Worker transcript fetch
- **AND** MAY still run local sidecar discovery and primary auto-selection

