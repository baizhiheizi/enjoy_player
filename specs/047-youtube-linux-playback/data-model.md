# Data Model: YouTube Playback on Linux

**Feature**: [spec.md](./spec.md) · No database schema changes — this feature adds no Drift tables or columns. All entities below are in-memory or documentation artifacts.

## Entity 1: YouTubeAvailabilityDecision

The single runtime answer to "can this device play YouTube right now?" (spec Key Entity; FR-004). Replaces the build-time constant `youtubeEngineAvailableOnLinux` while remaining the only consultation point for every gate call site.

| Field | Type | Meaning |
|-------|------|---------|
| `state` | enum `available` / `unavailable` | Final decision for the session once resolved |
| `reason` | `null` when available; else `runtimeMissing` / `runtimeInitFailed` / `disabledByBuild` | Drives the localized message variant and diagnostics (FR-005, FR-013). (`unsupportedPlatform` from the first draft is unreachable — non-Linux targets short-circuit to available under A1 — and was dropped.) |
| `resolution` | `lazy` — resolved on first YouTube entry-point consultation, cached for process lifetime | A failed probe must not re-run per keystroke |
| `killSwitch` | build-time constant ANDed into the result | Rollback posture (SC-008): flip to off = one line, ships as a normal release |

**State transitions**:

```text
[unresolved] --first consultation--> probe runs --> available   (cached, terminal for session)
                                                 \-> unavailable{reason} (cached, terminal for session)
[any state]  --kill switch on--> unavailable{DisabledByBuild}   (compile-time override wins)
```

Non-Linux platforms short-circuit to `available` (unchanged behavior — this decision only governs Linux).

## Entity 2: CapabilityProbeResult

Output of the one-time engine health probe behind the decision. Internal to the decision's provider; never surfaced raw to UI.

| Field | Type | Validation rule |
|-------|------|-----------------|
| `environmentCreated` | bool | WebKitWebContext-equivalent bootstrap completed |
| `headlessWebViewCreated` | bool | Offscreen webview instantiated and loaded a trivial page |
| `failureStage` | enum `none` / `environment` / `webView` / `pageLoad` | Must map to exactly one `reason` value above |
| `elapsed` | duration | Diagnostics only (FR-013); must complete ≤ 5 s, else treat as `RuntimeInitFailed` |

## Entity 3: UnavailableSurfacing

What the user sees when the decision is `unavailable`. Not persisted; defined here because the spec freezes it per entry point (FR-005, SC-006).

| Entry point | Required behavior |
|-------------|-------------------|
| URL paste / library open / Discover tile | Localized unavailable message + "open in browser" action; app returns to a working state afterwards |
| Warm-up (`warmYoutubeSurface`) | Silent no-op, logged at diagnostic level only |
| Engine swap / player surface | Engine never installed; stage shows the unavailable state, not a spinner |
| YouTube sign-in screen | Hidden (deferred per spec Assumptions) with localized explanation when reachable |

## Entity 4: ReleaseArtifactManifestAddendum

Documentation artifact recorded in packaging docs per release (FR-008, SC-008). Lives in `docs/packaging.md`, not in a database.

| Field | Meaning |
|-------|---------|
| `bundledRuntime.name / version` | WPE WebKit + GStreamer versions shipped in this artifact |
| `downloadSizeDelta` | Measured against previous release; validated against the ≤ +150 MB budget (SC-005) |
| `coldStartMedian` | Measured on the documented test VM; validated against ≤ previous + 2 s (SC-005) |
| `gstPluginSet` | Exact GStreamer plugin list bundled (research D3) |

## Entity 5: PlatformSmokeChecklistResult

Per-platform regression evidence for the shared dependency upgrade (US5, FR-010, SC-007). One record per platform per release candidate; format defined in [contracts/platform-smoke-checklist.md](./contracts/platform-smoke-checklist.md).

| Field | Validation rule |
|-------|-----------------|
| `platform` | one of `android / ios / macos / windows` |
| `steps` | every checklist step with pass/fail |
| `behaviorDiff` | "none" required to merge; anything else triggers the no-silent-trades decision (US5 scenario 3) |
| `executedAt / executor` | traceability |

## Entity 6: PlaybackEvidenceRecord

The FR-009 clean-VM verification evidence required before rollout. Stored with the release/docs (linked from the ADR).

| Field | Validation rule |
|-------|-----------------|
| `scenario` | one per quickstart scenario ID |
| `outcome` | pass/fail + notes; rollout blocked on any fail (FR-009) |
| `measurements` | cold-start, first-frame latency, artifact size, 24 h memory shape (feeds SC-001…005) |

## Relationships

- `YouTubeAvailabilityDecision` 1—consumes—1 `CapabilityProbeResult` (probe runs at most once per process).
- `YouTubeAvailabilityDecision` gates every row of `UnavailableSurfacing` (6 entry points, one behavior contract each).
- `PlaybackEvidenceRecord` aggregates measurements that validate `ReleaseArtifactManifestAddendum` budgets.
- `PlatformSmokeChecklistResult` (×4 platforms) is a merge gate independent of the Linux-only entities.
