# ADR-0108: The iOS platform toolchain check has to ask for the device platform

## Status

Accepted (2026-11-24)

## Context

The Apple CI job's iOS toolchain step,
[`.github/scripts/ensure_ios_ci_toolchain.sh`](../../.github/scripts/ensure_ios_ci_toolchain.sh),
is the only thing that can put the iOS platform on a runner before the build.
Two defects made it unable to do that job.

1. **It asked for the wrong variant.** The script requested the platform's
   **arm64** variant and treated "No needed downloadables found for arm64Only"
   as success. The arm64 variant is the *simulator* runtime; the generic iOS
   device destination the build uses needs the **device** platform, which is
   the **universal** variant. So on a runner that had a simulator runtime but
   no device platform, the script reported "iOS platform/runtime already
   present" and the build then failed much later, inside Flutter, with

   ```
   No Xcode build settings have been found. Please check possible errors above.
   Encountered error while building for device.
   ```

   — a message that names neither the platform nor the destination.

2. **Its destination check proved nothing.** It grepped the output of
   `xcodebuild -showdestinations` for
   `platform:iOS, id:dvtdevice-DVTiPhonePlaceholder-iphoneos:placeholder`.
   That id also appears in the **"Ineligible destinations"** list, where it
   carries an `error:` clause — "iOS 26.5 is not installed. Please download and
   install the platform from Xcode > Settings > Components." — so the check
   passed on exactly the runner it was supposed to catch.

The missing platform was not hypothetical: the runner's volume filled up during
the macOS build on 2026-11-24, and the iOS 26.5 platform was gone from the
machine afterwards, while the CI's own iOS job had passed hours earlier with
the same command.

Re-installing it turned out to be awkward on this host.
`xcodebuild -downloadPlatform iOS` hands the fetch to `mobileassetd`, which
opens a QUIC (HTTP/3) connection to Apple's asset server. This host's route
cancels that connection after ~30 s ("read-side closed" in the daemon's log).
The daemon retries and the download does finish, but `xcodebuild` prints
nothing while it works, so a progressing fetch is indistinguishable from a
hung one — and a job that waits on it waits forever.

## Decision

1. **Request the device platform first.** The script now asks for the
   **universal** variant before the arm64 one. The arm64 variant is still
   requested afterwards, but as best effort: the device platform is what the
   build's destination needs, so its failure is fatal and the simulator
   variant's is not.

2. **Bound and retry every request.** Each `xcodebuild -downloadPlatform` call
   runs under a timeout (`IOS_PLATFORM_TIMEOUT_S`, default 900 s) and is
   retried up to three times. macOS has no `timeout(1)`, so the script
   implements the wait itself. A stalled download can no longer hold the
   runner, and a slow-but-progressing one is retried instead of abandoned.

3. **Reject an ineligible destination.** The destination check now requires
   the placeholder destination *without* an `error:` clause, and prints the
   destination errors it found so the failure names the platform version that
   is missing.

4. **Provide a TCP escape hatch.**
   [`install_apple_platform.sh`](../../.github/scripts/install_apple_platform.sh)
   forces the download over TCP by blocking outbound UDP/443 with a temporary
   pf rule, then restores the machine: the rule, the anchor, `/etc/pf.conf`,
   and pf's enabled/disabled state — including the "pf disabled" state macOS
   ships with. A runner whose platform is already installed exits without
   touching anything, and `--dry-run` validates the ruleset with `pfctl -n`
   without enabling pf or editing `/etc/pf.conf`.

## Consequences

- A runner without the iOS device platform fails the toolchain step with a
  message that names it, instead of failing later inside Flutter with an
  unrelated message.
- The platform request cannot hang the job: the worst case is three bounded
  attempts per variant.
- The pf escape hatch is opt-in and self-restoring. It needs sudo, and it
  temporarily changes the machine's firewall state, so it is a deliberate
  operator action rather than something a CI job does on its own — the CI job
  fails with a clear message instead.
- The check is the real gate; the variant requests are best effort around it.
  A runner with a working destination but no arm64 simulator runtime still
  builds.
