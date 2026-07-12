/// Centralized Linux-platform predicates.
///
/// Every call site that branches on [isLinux], [youtubeEngineAvailableOnLinux],
/// etc. should import this module instead of scattering `Platform.isLinux` checks.
/// This makes future ADRs (e.g. flipping YouTube to `true` on Linux) a one-line
/// change in a single file.
library;

import 'dart:io' show Platform;

/// True when running on a Linux host.
bool get isLinux => Platform.isLinux;

/// YouTube engine is **not** available on Linux for v1.
///
/// The engine depends on `flutter_inappwebview`'s Linux backend, which requires
/// `webkit2gtk-4.0` — not present on a default Ubuntu 22.04 LTS install.
/// Re-evaluate in a follow-up ADR (ADR-0044, R1 / R6).
const youtubeEngineAvailableOnLinux = false;

/// Google native sign-in is **available** on Linux.
///
/// `google_sign_in: ^6.3.0` supports Linux via a browser-based OAuth flow.
/// Flip to `false` if first smoke shows a crash or auth loop (ADR-0044, R10).
const googleSignInAvailableOnLinux = true;

/// In-app auto-updater (`auto_updater: 0.2.1`) is **not** available on Linux.
///
/// `auto_updater` is Windows/macOS-only. Linux uses the direct-download update
/// model (ADR-0044, R7).
const autoUpdaterAvailableOnLinux = false;

/// Echo-mode recording (`record: ^7.0.0`) is **enabled** on Linux by default.
///
/// Flip to `false` if first smoke shows a crash; the rest of echo practice
/// works without recording (ADR-0044, R8).
const echoRecordingAvailableOnLinux = true;

/// ASR (Azure speech) audio extraction over FFmpeg is **enabled** on Linux.
///
/// The extraction code falls through to system `ffmpeg` on PATH for non-Windows
/// platforms. Flip to `false` if smoke shows a regression (ADR-0044).
const nativeLinuxAsrAvailable = true;
