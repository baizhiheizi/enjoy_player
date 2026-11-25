# ADR-0109: iOS uploads are gated on the iOS 27 SDK (App Store Connect warning 90725)

## Status

Accepted (2026-11-25)

## Context

Uploading the v0.11.0 (20) IPA returned App Store Connect **warning 90725**:

> SDK version issue. This app was built with the iOS 26.5 SDK. Starting April
> 2027, iOS and iPadOS apps must be built with the iOS 27 SDK or later,
> included in Xcode 27 or later, in order to be uploaded to App Store Connect
> or submitted for distribution.

Today it is only a warning, and nothing in the repo pins or even *reports*
which SDK built the app. The Apple builds run on the self-hosted macOS runner
with whatever Xcode `xcode-select` points at — Xcode 26.6, whose iOS SDK is
26.5 — so every release silently tracked the runner's toolchain and the
requirement surfaced only after upload, as an Apple-side warning email. Once
the April 2027 deadline passes, the same build stops being accepted outright.

The SDK comes from the build machine's Xcode, not from the repo — no
`pubspec` bump or project setting can fix it. What the repo *can* do is make
the requirement explicit and refuse to produce or upload an IPA that violates
it, so the fix lands as "install Xcode 27 on the runner" driven by a gate,
not as another post-upload surprise.

## Decision

One gate script,
[`.github/scripts/check_ios_sdk_requirement.sh`](../../.github/scripts/check_ios_sdk_requirement.sh),
owns the requirement (`IOS_SDK_MINIMUM`, default **27**) and can evaluate it
at two points:

1. **The host, before building.** Host mode reads the active Xcode's iOS SDK
   (`xcrun --sdk iphoneos --show-sdk-version`). `release_apple.sh` runs it in
   enforcing mode right before the iOS build, so a runner still selected
   against an older Xcode fails the release in seconds with upgrade
   instructions instead of after a ~15-minute compile.

2. **The artifact, after building.** `--macho` mode reads the build version
   load commands of a binary (`xcrun vtool -show-build`) — the SDK that
   *actually* produced the executable, recorded at link time.
   `check_ios_ipa.sh` runs it against `Payload/Runner.app/Runner` on every
   release path, including the `--skip-build --testflight` re-upload of an
   existing IPA, whose age a host-only check could never prove anything
   about. The mode also rejects non-device slices (`IOSSIMULATOR` in a device
   IPA is a packaging bug, the same class as ADR-0108's ineligible
   destinations).

Enforcement is layered by surface, on purpose:

- **Release** (`release_apple.sh`, `check_ios_ipa.sh`): `::error::` and a
  non-zero exit.
- **PR smoke** (`ensure_ios_ci_toolchain.sh`, `--warn`): a `::warning::`
  annotation that does not turn PRs red — the runner upgrade is an operator
  task with its own schedule, and blocking every PR on it would not install
  Xcode any faster. The annotation disappears the moment the runner is
  upgraded, which is exactly the visibility a pending requirement needs.

`ALLOW_IOS_SDK_BELOW_MINIMUM=1` is the documented conscious bypass for an
emergency release before the runner is upgraded; it downgrades the gate to a
loud warning and cannot help after the deadline, because from April 2027 the
rejection happens on Apple's side, not in the repo.

## Consequences

- The next Apple release fails fast until Xcode 27+ is installed and selected
  on the runner Mac, with instructions in the failure message itself
  (`xcode-select`, `xcodebuild -runFirstLaunch`,
  `xcodebuild -downloadPlatform iOS`).
- Warning 90725 disappears for the next upload once the runner is upgraded;
  the artifact-level check guarantees the IPA on disk was really produced by
  the new SDK, not merely built on a machine that has it.
- The minimum is one variable (`IOS_SDK_MINIMUM`); when Apple raises the bar
  again — it does roughly every year — the fix is a one-line default bump
  plus the same runner upgrade.
- The gate is testable without any Apple tooling: the Dart suite runs it
  against PATH stubs for `xcrun`, so version parsing, slice checks and mode
  behaviour are pinned on every CI run (see
  `test/ci_workflow_resilience_test.dart`).
