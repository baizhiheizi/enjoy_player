## ADDED Requirements

### Requirement: Update check on startup and on demand

The app SHALL check for a newer release on startup (debounced against a stored last-check timestamp) and whenever the user activates a "Check for updates" action in Settings/About. Checks SHALL only run when the device is online and SHALL NOT block app launch or interrupt active media playback.

#### Scenario: Debounced startup check

- **WHEN** the app starts and the last successful check was within the debounce window
- **THEN** the app SHALL skip the network check and use no cached prompt

#### Scenario: Manual check finds a newer version

- **WHEN** the user taps "Check for updates" and the feed reports a version greater than the running version
- **THEN** the app SHALL present an update prompt for the current platform

#### Scenario: Manual check when already current

- **WHEN** the user taps "Check for updates" and no newer version exists
- **THEN** the app SHALL show an "up to date" confirmation and SHALL NOT show an update prompt

#### Scenario: Offline check

- **WHEN** a check is triggered while the device is offline or the feed is unreachable
- **THEN** the app SHALL fail silently for the startup check, and surface a non-blocking error only for a manual check

### Requirement: Version comparison and minimum-supported-version floor

The app SHALL compare the running version against the feed's latest version using semantic versioning, and SHALL treat the running version as outdated when it is lower than the feed's `minSupportedVersion`.

#### Scenario: Optional update available

- **WHEN** the running version is lower than the latest version but at or above `minSupportedVersion`
- **THEN** the app SHALL present a dismissible (optional) update prompt

#### Scenario: Mandatory update required

- **WHEN** the running version is lower than `minSupportedVersion`
- **THEN** the app SHALL present a blocking update prompt with no dismiss or snooze option

#### Scenario: Equal or newer running version

- **WHEN** the running version is equal to or greater than the latest version
- **THEN** the app SHALL NOT present any update prompt

### Requirement: Optional update prompt with snooze

For optional updates, the app SHALL show release notes and allow the user to update now, dismiss, or snooze. A snoozed version SHALL NOT prompt again until the snooze window expires, persisted in `settings_kv`.

#### Scenario: User snoozes an optional update

- **WHEN** the user snoozes an optional update prompt
- **THEN** the app SHALL persist a snooze-until timestamp and SHALL NOT re-prompt for that version until it expires

#### Scenario: Snooze does not suppress mandatory updates

- **WHEN** a version is snoozed and a later check reports the running version is below `minSupportedVersion`
- **THEN** the app SHALL present the blocking mandatory prompt regardless of snooze

### Requirement: Platform- and channel-specific update action

The app SHALL select the update action by build flavor and platform. The `direct` flavor SHALL use native auto-update on Windows/macOS and an APK download-and-install flow on Android sideload. The `store` flavor SHALL NOT perform any custom update action.

#### Scenario: Desktop direct update

- **WHEN** a `direct`-flavor Windows or macOS build initiates an update
- **THEN** the app SHALL delegate to the native auto-update mechanism using the appcast feed

#### Scenario: Android sideload update

- **WHEN** a `direct`-flavor Android build initiates an update
- **THEN** the app SHALL download the matching APK from the feed and trigger the system install flow

#### Scenario: Store build no-op

- **WHEN** a `store`-flavor build (TestFlight / Play test) runs an update check
- **THEN** the app SHALL NOT present a custom download/install flow and SHALL rely on the platform store

### Requirement: Integrity verification of direct downloads

Before installing any artifact obtained from a direct-download feed, the app SHALL verify the downloaded file against the SHA-256 checksum declared in the feed and SHALL abort installation on mismatch.

#### Scenario: Checksum matches

- **WHEN** a direct download completes and its SHA-256 matches the feed value
- **THEN** the app SHALL proceed with installation

#### Scenario: Checksum mismatch

- **WHEN** a direct download completes and its SHA-256 does not match the feed value
- **THEN** the app SHALL discard the file, abort installation, and surface an error
