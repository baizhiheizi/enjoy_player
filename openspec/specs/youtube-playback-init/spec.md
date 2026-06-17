# youtube-playback-init Specification

## Purpose
TBD - created by archiving change youtube-init-speed. Update Purpose after archive.
## Requirements
### Requirement: Thumbnail poster during YouTube video stage load

While the YouTube WebView is buffering, the expanded player video stage SHALL display the media row's stored or derived YouTube thumbnail artwork overlaying the WebView. The poster MUST be hidden (fade out or remove) when playback is ready (`canplay` or `playing` event, buffering cleared).

#### Scenario: Poster shown on open

- **WHEN** the user opens a YouTube video and the WebView has not yet reached a ready playback state
- **THEN** the video stage shows the row's thumbnail image instead of a blank black surface

#### Scenario: Poster hidden when playing

- **WHEN** the YouTube engine reports buffering cleared or a `playing` transport state
- **THEN** the thumbnail poster is no longer visible over the video

#### Scenario: Poster URL fallback

- **WHEN** the row has a YouTube `vid` but no stored thumbnail URL
- **THEN** the system SHALL derive artwork from `i.ytimg.com/vi/<vid>/` (maxres with mq fallback)

### Requirement: YouTube artwork during expanded player loading

While `openMedia` is in progress for a YouTube row and the playback session is not yet published, the expanded player loading UI SHALL show the row's YouTube thumbnail artwork rather than only a generic skeleton.

#### Scenario: Loading body shows thumbnail

- **WHEN** the user navigates to `/player/:id` for a YouTube row and open is still resolving
- **THEN** the loading screen displays that row's thumbnail artwork

#### Scenario: Non-YouTube unchanged

- **WHEN** the user opens a local or non-YouTube media row
- **THEN** the loading screen behavior is unchanged from before this change

### Requirement: Early WebView mount overlaps open pipeline

The YouTube WebView SHALL begin initialization during the open pipeline (before or in parallel with session publish) so WebView cold-start overlaps with database resolve, engine setup, and seek-restore work. The system MUST NOT create more than one active YouTube player WebView for a single engine instance.

#### Scenario: WebView starts during openMedia

- **WHEN** `openMedia` begins for a YouTube source
- **THEN** the YouTube WebView mount is initiated before the expanded player chrome body is shown

#### Scenario: Single WebView on session publish

- **WHEN** the playback session is published and the video stage is displayed
- **THEN** the same WebView instance is reused (no second WebView created)

### Requirement: Warm YouTube engine across dismiss

When the user dismisses YouTube playback via clear/stop without switching to a non-YouTube source, the app SHALL retain the `YoutubePlayerEngine` and its WebView process for reuse. The engine MUST stop playback and MUST NOT dispose the WebView solely because the session was cleared.

#### Scenario: Re-open after dismiss is faster

- **WHEN** the user dismisses YouTube playback and opens the same or another YouTube video within the same app session
- **THEN** the YouTube engine WebView is reused without a full cold dispose-and-recreate cycle

#### Scenario: Dispose on engine swap

- **WHEN** the user opens a non-YouTube source after YouTube was active
- **THEN** the YouTube engine is disposed and MediaKit engine is used as today

### Requirement: Pre-warm on library tap

When the user taps a YouTube row in library or discover to open the player, the app SHALL attempt to pre-warm the YouTube WebView surface before navigation to the player route completes.

#### Scenario: Pre-warm on tap

- **WHEN** the user taps a YouTube library or discover row to open the player
- **THEN** the app SHALL begin YouTube WebView pre-warm before the player route finishes transitioning

#### Scenario: Pre-warm is best-effort

- **WHEN** pre-warm fails or the user navigates away before open completes
- **THEN** playback open still proceeds normally without error

### Requirement: Playback URL and transport unchanged

YouTube playback SHALL continue to use the mobile watch page (`https://m.youtube.com/watch?v=<vid>`) with existing HTML5 video control and inject scripts. The system MUST NOT switch to embed or `-nocookie` URLs as part of this change.

#### Scenario: Watch page URL retained

- **WHEN** a YouTube video is opened after this change
- **THEN** the WebView loads `m.youtube.com/watch?v=<vid>` (not an embed URL)

#### Scenario: Echo and seek unchanged

- **WHEN** the user seeks or uses echo mode on YouTube content
- **THEN** transport behavior matches pre-change semantics (direct video element control)

