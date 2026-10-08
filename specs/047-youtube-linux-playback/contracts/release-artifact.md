# Contract: Linux Release Artifact (self-containment)

**Producer**: `linux/packaging/make_appimage.sh` (extended in place — no second
packaging path), exercised by `.github/workflows/release_linux.yml`.
**Consumer**: end users on the supported distro baseline; the landing page
download link.

## Artifact contract

| # | Rule |
|---|------|
| R1 | The AppImage runs on a clean Ubuntu 22.04 LTS / Debian 12 / Fedora 40 / Arch (x86_64) VM with **zero** system package installation, for BOTH local-media playback and YouTube playback (FR-008, US4 scenario 1). |
| R2 | WPE-side shared objects (`libWPEWebKit-*`, `libwpe-1.0`, FDO backend when compiled in) are bundled via the plugin's `*_bundled_libraries` mechanism with `$ORIGIN` RPATH — no `LD_LIBRARY_PATH` export required by users. |
| R3 | GStreamer runtime + plugin set (research D3) is bundled at AppImage level and made discoverable via `GST_PLUGIN_PATH`/`GST_PLUGIN_SYSTEM_PATH` exported from the AppRun wrapper. Link-time dependency walkers do not see GStreamer plugins (runtime `dlopen`), so this is an explicit, reviewed list — not an incidental linuxdeploy side effect. |
| R4 | libsecret (plugin link-time requirement) resolves inside the bundle; absence of a desktop keyring on the host degrades gracefully (existing app behavior for secure storage), never blocking startup. |
| R5 | Download size delta vs. the previous release is measured and recorded per release; budget ≤ +150 MB unless the packaging docs justify the excess (SC-005, US4 scenario 2). |
| R6 | Cold-start-to-window median on the documented test VM regresses ≤ 2 s vs. the previous release's recorded median (SC-005). |
| R7 | Bundled runtime identities and versions (WPE WebKit, GStreamer, plugin list) are recorded in `docs/packaging.md` for every release that ships them (FR-008 scenario 4 / data-model Entity 4). |
| R8 | A missing-or-broken bundled runtime on a user machine surfaces as the graceful unavailable state (runtime-availability contract A3/U1), not a crash — self-diagnosis of the bundle is part of the probe, not of user error. |
| R9 | Everything inside the bundle carries licenses permitting redistribution (WPE WebKit LGPL-2.1+, GStreamer LGPL/GPL plugin split respected: only LGPL-set plugins ship inside the single-file artifact; GPL plugins only via a separately documented decision). The license inventory lands in `docs/packaging.md` with R7. |

## Build-order dependency

The spike (quickstart S1–S4) must pass before this contract is considered
satisfiable; in particular R3's plugin list is an output of spike S2, not an
input. If R3 cannot be met within R5's budget, the feature falls back per spec
Assumptions (Route B decision point) — that fallback decision is recorded in
the ADR, not decided ad hoc in packaging.
