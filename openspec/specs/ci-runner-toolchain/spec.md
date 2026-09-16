# ci-runner-toolchain Specification

## Purpose
Define how the Linux self-hosted runner pool used by this repo's CI is provisioned: toolchains baked into the gh-sr runner image at attended build time (keyed to the repo's version pins), mirror-resilient Android SDK provisioning, and the network/sudo-free fast path for job setup.

## Requirements

### Requirement: Baked Linux build packages

The runner image for the pool serving this repo's Linux workflows SHALL include the Flutter Linux desktop build dependency stack (Clang/LLVM, CMake, Ninja, zip, and the gtk3, lzma, sqlite3, gstreamer, gstreamer-plugins-base, libsecret, and mpv development packages) so that jobs start with all build packages present.

#### Scenario: First CI job in a freshly rebuilt container

- **WHEN** a CI or build workflow runs in a newly recreated runner container that has never executed a job
- **THEN** `ensure_linux_tooling.sh` MUST find every listed package installed and exit without network access or package-manager writes

### Requirement: Baked Flutter SDK keyed to the version pin

The runner image SHALL contain the Flutter stable SDK for the exact version pinned in `.github/flutter-version`, extracted to the runner tool cache at the `flutter-<version>-stable/flutter` path that `.github/actions/setup-flutter` probes, including the `.git` directory the probe requires.

#### Scenario: Cold container skips the Flutter download

- **WHEN** `setup-flutter` runs in a freshly rebuilt container with an intact baked SDK
- **THEN** it MUST skip the storage.googleapis.com download entirely and export the baked SDK path

#### Scenario: Flutter version pin bump

- **WHEN** `.github/flutter-version` is bumped without a matching bake entry
- **THEN** `setup-flutter` MUST still succeed by falling back to the existing runtime download-and-install path

### Requirement: Baked Temurin JDK

The runner image SHALL contain a pinned Temurin JDK 17 for linux x64 extracted at the `jdk-temurin-17/bin/java` path that `.github/actions/setup-java` probes, so JDK provisioning does not depend on the adoptium.net / GitHub release-asset download path at job time.

#### Scenario: Cold container skips the JDK download

- **WHEN** `setup-java` runs in a freshly rebuilt container with the baked JDK present
- **THEN** it MUST skip the api.adoptium.net download and export `JAVA_HOME` pointing at the baked JDK

### Requirement: Mirror-resilient Android SDK provisioning

`.github/actions/setup-android` SHALL direct Android SDK package downloads (repository manifests, component installs, and license acceptance) to an Android SDK mirror by default, overridable by environment, and SHALL NOT depend on `dl.google.com` reachability for any step required to obtain `sdkmanager` or the requested packages.

#### Scenario: sdkmanager install on a dl.google.com-blocked network

- **WHEN** `setup-android` installs the requested platforms/build-tools packages in a cold container where `dl.google.com` is unreachable
- **THEN** the package install MUST complete via the mirror without relying on the retry loop against `dl.google.com`

#### Scenario: Already-installed packages

- **WHEN** the requested SDK packages are already present in the container's Android SDK directory
- **THEN** `setup-android` MUST skip all network access, matching its current idempotent behavior
