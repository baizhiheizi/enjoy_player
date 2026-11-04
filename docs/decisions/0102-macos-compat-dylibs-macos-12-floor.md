# ADR-0102: macOS compat dylibs pin the bundle to the deployment target, not the build machine

**Status**: Accepted (2026-11-01)
**Related**: [#1187](https://github.com/baizhiheizi/enjoy_player/issues/1187),
[ADR-0002](0002-persistence-drift.md) (not technical, but shares the "no ambient
build-machine state in artifacts" principle),
[docs/packaging.md § macOS](../packaging.md#macos-apple),
[`macos/scripts/build_compat_dylibs.sh`](../../macos/scripts/build_compat_dylibs.sh),
[`macos/scripts/bundle_ffmpeg_homebrew_deps.sh`](../../macos/scripts/bundle_ffmpeg_homebrew_deps.sh)

## Context

The vendored FFmpegKit frameworks
([`packages/ffmpeg_kit_flutter_new`](../../packages/ffmpeg_kit_flutter_new),
upstream `sk3llo/ffmpeg_kit_flutter` 8.0.0-full-gpl) were linked on a machine
with Homebrew kegs at `/opt/homebrew/opt/*`. Every macOS build therefore has to
supply those dylibs, and [`bundle_ffmpeg_homebrew_deps.sh`](../../macos/scripts/bundle_ffmpeg_homebrew_deps.sh)
copies them from whatever kegs are installed on the build machine.

Two properties of Homebrew bottles make that unsound for a macOS 12+ app:

1. **Bottles carry their bottle tag's OS as `LC_BUILD_VERSION` minos.**
   Homebrew's arm64 bottle tag is the current macOS (26/Tahoe today), so every
   poured keg dylib reports `minos 26.0`. dyld refuses to load such a library
   on older macOS — "built for macOS 26.0 which is newer than running OS" —
   before `main()` runs, so the app crashes at launch on every supported macOS
   below the bottle tag. The tag moves whenever Homebrew's support window
   shifts, and `brew bundle install` (which also upgrades) re-pours kegs mid-
   window, so the app's real floor silently tracked the build machine's
   Homebrew state (#1187: launch crash on macOS 14.0; keg audit showed the
   entire closure — fontconfig, freetype, zlib, fribidi, harfbuzz, glib,
   libintl, pcre2, graphite2, libiconv, libsamplerate, srt, libpng, brotli,
   libssl/libcrypto — at `minos 26.0`).
2. **FreeType ≥ 2.15.0 links Apple's experimental HVF driver** when its build
   machine has the macOS 26 SDK: the driver is auto-detected
   (`hvf/Scaler.h` + `-lhvf`) and produces a strong `LC_LOAD_DYLIB` on
   `/usr/lib/libhvf.dylib`, which exists only on macOS 26+. The Homebrew
   `arm64_tahoe` freetype 2.15.0 bottle has exactly this dependency, so a keg
   copy can crash dyld even on macOS 15.

The existing dylib closure check (added for #1096/#1099) validated that every
load command resolves *on the build machine* — where `/usr/lib/libhvf.dylib`
is satisfied from the dyld shared cache — so both regressions sailed through
a green pipeline.

## Decision

1. **The bundle never inherits the build machine's deployment target.** All
   Homebrew-referenced dylibs are built from pinned sources (URL + sha256)
   with `MACOSX_DEPLOYMENT_TARGET=12.0` — the app's documented minimum — into
   a cached prefix (`~/Library/Caches/ai.enjoy.player/macos-compat`, override
   with `ENJOY_MACOS_COMPAT_PREFIX`) by
   [`build_compat_dylibs.sh`](../../macos/scripts/build_compat_dylibs.sh).
   FreeType is pinned to 2.13.3, which predates the HVF driver entirely; the
   pinned set is the exact `/opt/homebrew` closure of the FFmpegKit arm64
   slices (zlib, libiconv, brotli, libpng, freetype, fribidi, graphite2,
   pcre2, gettext, glib, harfbuzz, fontconfig, libsamplerate, openssl, srt).
   Build tools (cmake/meson/ninja) come from `macos/Brewfile`; they run on the
   build machine only, so their own minos is irrelevant. Installs are
   relocatable (`@rpath/<name>` + `@loader_path`), matching the layout the
   bundler already follows through keg `@rpath` chains.
2. **The bundler resolves the compat prefix before any keg.** Kegs remain a
   dev-machine fallback, but anything they contribute now has to pass the new
   gates — which a Tahoe bottle cannot.
3. **Two gates make the failure mode a build error, not a user launch crash:**
   - **macOS floor gate**: every dylib the bundler copies must have
     `LC_BUILD_VERSION minos ≤ 12.0` (all arch slices). A violation fails the
     Xcode build phase with a pointer to `build_compat_dylibs.sh`.
   - **System-dylib allowlist**: every strong `/usr/lib/*` load command in
     every Mach-O of the bundle must name a dylib that exists on macOS 12
     (`libSystem`, `libz`, `libbz2`, `libiconv`, `libcharset`, `libc++`,
     `libobjc`, `libcompression`, `libexpat`, `libffi`, `libsqlite3`,
     `libxar`, and `/usr/lib/swift/*`). `/usr/lib` contents change with OS
     releases — `libhvf.dylib` is macOS 26-only — and a missing strong
     dependency is a launch crash. Unknown names fail the build.
4. **Coverage stays scoped to what the bundler injects.** The floor gate
   applies to dylibs the bundler copies (the class of #1187). Known separate
   gaps, deliberately out of scope here: the `sqlite3`/`objective_c` native
   asset frameworks are minos 13.0 (lazy `dlopen` at runtime, not a launch
   crash) and media_kit's bundled frameworks are minos 11.0 (fine). The
   allowlist gate applies bundle-wide because it costs nothing and would have
   caught `libhvf.dylib` on its own.

## Alternatives considered

- **Pin Homebrew + older bottle tags** (`arm64_sonoma`/`arm64_sequoia`
  bottles): those tags age out of the API, and the best available tag (sequoia)
  is still minos 15.0 — trades a 26.0 floor for a 15.0 floor. Not a fix.
- **`vtool`-rewrite keg dylibs to minos 12.0**: lies about compatibility
  (object code targets the macOS 26 SDK) and cannot remove the
  `/usr/lib/libhvf.dylib` load command or its imported symbols.
- **Rewire FFmpegKit to media_kit's bundled Freetype/Fribidi/Harfbuzz
  frameworks**: still needs fontconfig/glib/pcre2/openssl/srt from somewhere,
  and couples FFmpegKit's linkage to media_kit's packaging versions.
- **Rebuild FFmpegKit itself with static deps**: the right long-term answer
  but a full ffmpeg-kit build pipeline, out of scope for a regression fix.
- **Commit prebuilt compat dylibs to the repo**: deterministic, but adds
  ~10 MB of binaries per pin bump; the cached source build achieves the same
  determinism (sha256-pinned) without growing the repo. The FFmpegKit
  frameworks themselves are downloaded, not committed, for the same reason.
