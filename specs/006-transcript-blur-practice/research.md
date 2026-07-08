# Research: Transcript Blur (Practice / Listening-Focus Mode)

**Feature**: [spec.md](spec.md)
**Phase**: 0 (research) — closes all NEEDS CLARIFICATION before design.
**Date**: 2026-07-08

This file consolidates every decision required to implement the feature.
No NEEDS CLARIFICATION markers remain in the spec; the few remaining
opinion-driven choices (default hold duration, blur strength constant,
where the toggle lives in the panel) are recorded below as decisions
with rationale, not as open questions.

---

## R-001 — Where the visual blur is rendered

**Decision**: Apply the blur as a `BackdropFilter`/`ImageFilter.blur` on
the **cue body text widget only**, not on the surrounding row, the row's
background, or any structural chrome (timestamp, recording badge, left
rail, hover tint, echo card shell).

**Rationale**:
- The spec's hard requirement is that the cue stays "visually
  discoverable" (FR-002 / FR-011) — blurring only the text keeps the
  line discoverable (you can still see it exists, what time it covers,
  whether it is in an echo region, whether it has recordings).
- `TranscriptLineTile` already composes primary + optional secondary
  body widgets inside `Padding(...)`; wrapping just those widgets in a
  blur filter keeps the implementation local and avoids re-laying-out
  the row (the blur is a paint effect, not a layout effect).
- Applying a filter to the surrounding `Material` would force a
  `SaveLayer` over the entire row background, including the hover tint
  and the active-line rail, which is wasted GPU work and contradicts
  FR-010 (chrome must not be blurred).

**Alternatives considered**:
- *CSS-style `filter: blur(...)` on the whole row* — blurs the rail and
  hover tint; rejected per FR-010.
- *Render an opaque "blur" placeholder widget behind the text and
  toggle it on/off* — would require a custom `ShaderMask`/layer to
  mask text and adds complexity for no visual gain over `ImageFilter`.
- *Use `BackdropFilter` on the row so the underlying video frame is
  blurred through the transcript panel* — interesting but couples the
  transcript panel to the player's render tree; out of scope.

---

## R-002 — How the toggle is wired into the panel header

**Decision**: Add a panel-level toolbar row at the top of
`TranscriptPanel` (above the existing scrollable list, below any
existing header chrome) that hosts the **"Blur practice"** toggle.
Reuse `EnjoyTappableIcon` from `lib/core/interaction/enjoy_tappable.dart`
for the icon button and the existing tooltip / haptic pipeline.

**Rationale**:
- The spec calls the toggle "panel-level" (Story 1) and explicitly says
  it must not require a separate settings page to be useful.
- A toolbar row is the natural place: today `TranscriptPanel` exposes
  only the lines list — there is no header at all. Adding a single
  toolbar with `mainAxisAlignment: MainAxisAlignment.end` keeps the
  change minimal and does not collide with the future subtitle track
  picker entry point (which already lives in the player transport bar).
- `EnjoyTappableIcon` already wraps tooltip + hover scale + focus ring
  + haptics and is the project-mandated primitive for icon-only actions
  (per [ADR-0018](../decisions/0018-shared-interactive-primitives.md)
  and QR-003 in the spec).

**Alternatives considered**:
- *Toggle inside the subtitle track picker sheet* — wrong place; users
  enabling listening practice are mid-playback, not browsing tracks.
- *Toggle in the player transport bar next to the CC button* — too far
  from the transcript body; CC is a track picker entry, not a mode
  toggle. Future: it could be added as a secondary entry, but the panel
  itself is the primary surface.

---

## R-003 — How preferences are persisted

**Decision**: Add **two new keys** to `lib/data/db/settings_keys.dart`
(`_staticKeys` set + the typed getters):

- `prefs.transcript_blur_practice_enabled` → boolean (`'true'` / `'false'`).
- `prefs.transcript_blur_tap_reveal_seconds` → integer string
  (`'1'` … `'15'`, default `'3'`).

Read/write through the existing `SettingsDao` (`getValue` / `setValue`).
Introduce a new `@Riverpod(keepAlive: true)` notifier
`transcriptBlurPreferencesProvider` in
`lib/features/transcript/application/transcript_blur_preferences_provider.dart`
that mirrors the `PlayerPreferencesCtrl` pattern (lazy hydrate from
`settingsDao`, setters that update state then persist).

**Rationale**:
- The constitution forbids bypassing the preferences repository (QR-006).
- These are **device-local UI preferences**, not user-profile fields, so
  they must NOT be added to `AppPreferencesCtrl` (which is tied to the
  sign-in profile-sync flow and would require a server schema change
  for a UI preference).
- The `PlayerPreferencesCtrl` pattern (hydrates in microtask, persists
  on setter, `keepAlive: true`) is the closest in-tree precedent and is
  used without modification.
- Boolean / integer string values match every other key in
  `SettingsKeys`; no schema change to the Drift `settings` table is
  required.

**Alternatives considered**:
- *JSON blob keyed under `transcript_blur_preferences_v1`* — overkill
  for two values; matches `playerPreferencesV1` only because that
  blob already had four values to migrate together.
- *Store on `UserProfile` via `AppPreferencesCtrl`* — requires a server
  change and would couple a UI preference to sign-in state (the user
  might practice while signed out).
- *Store in `shared_preferences` / `hive`* — bypasses Drift and
  contradicts QR-006.

---

## R-004 — How the per-cue blur state is computed (the `cueRevealed` model)

**Decision**: Add a new derived provider family
`transcriptCueRevealProvider(mediaId, cueId)` that exposes a single
`bool` per cue (true = currently revealed). The provider watches:

1. `transcriptBlurPreferencesProvider` for the global toggle.
2. A new ephemeral `tapRevealHoldProvider(mediaId)` for the
   currently-tapped cue + expiry timestamp (kept as a single keyed
   record so only one cue is ever on hold at a time).
3. The tile's own `MouseRegion` hover state (still local to the tile;
  the provider is queried only by tiles that already track their own
  `_hover`).

A cue is **revealed** when:

- `blurEnabled` is **false** (reveal everything — toggle off), OR
- the tile's local `_hover` is **true** (desktop pointer hover), OR
- `tapRevealHold.cueId == thisCue.id` AND
  `DateTime.now().isBefore(tapRevealHold.expiresAt)` (mobile tap-reveal
  hold).

**Rationale**:
- Keeps the active-cue state explicitly OUT of the model per the
  2026-07-08 clarification (no auto-reveal of the active line).
- `transcriptPlaybackHighlightProvider` is **not** read by the reveal
  provider, so the active cue has no privileged reveal path.
- Per-cue derived providers let each `TranscriptLineTile` only rebuild
  when its own reveal state changes (Riverpod deduplicates identical
  bool emissions), which is the cheapest path to the
  "one-frame blur/unblur" target in SC-001 / SC-002.
- The tap-reveal hold is a single record (not a `Map<cueId, expiry>`)
  so the spec rule "tapping cue B blurs cue A and resets the timer"
  is just a state replacement — no cleanup of stale entries.

**Alternatives considered**:
- *Per-cue state inside the tile widget only (StatefulWidget +
  setState)* — works for hover and tap, but the global toggle needs
  Riverpod to broadcast to every tile at once, and tests get harder.
- *Single `transcriptRevealStateProvider` exposing a map of revealed
  cues* — every tile rebuilds on every tap, which would be wasteful
  for long transcripts. Per-cue providers are scoped.
- *Active cue is an input to the reveal model* — rejected per R-006 and
  the 2026-07-08 clarification.

---

## R-005 — Mobile tap-reveal interaction

**Decision**: Tapping a blurred cue runs:

1. The existing `onTap` → seek playback (today's `PlayerInteractions`
   seek path — preserved per Story 4 / FR-012).
2. `_tapRevealCtrl.setHold(cueId, now + Duration(seconds: holdSeconds))`
   which both stores the new hold AND cancels any previous hold (so the
   prior cue re-blurs immediately).

The hold expiry is enforced by a single per-provider `Timer`; when the
timer fires the provider sets state back to `null` (no cue on hold).
This is the only timer in the system — it survives across cue changes
because there is at most one cue on hold at any moment.

**Rationale**:
- One cue on hold + one timer is the simplest possible state machine
  and matches the spec's "tapping cue B re-blurs cue A immediately"
  rule for free.
- The hold provider is keyed by `mediaId` so two open media items do
  not share timer state (one panel's expiry must not affect another's).
- No new `Timer` per cue widget — that would cause memory churn on
  long transcripts and makes test setup awkward.

**Alternatives considered**:
- *Per-cue timer via `StatefulWidget`* — leaks timers when tiles are
  recycled by `ListView.builder`.
- *Ticker via `Ticker` from `SingleTickerProviderStateMixin`* — overkill
  for a fixed-duration countdown.
- *`stopwatch`/`Stream.periodic`* — same problem; one timer is enough.

---

## R-006 — Reduced-motion handling

**Decision**: Read `MediaQuery.disableAnimationsOf(context)` (the same
signal the project already uses for `enableHoverScale` in
`EnjoyTappableSurface`). When `disableAnimationsOf` is **true**, the
blur/unblur transition is **instant** — the cue either has the filter
or it doesn't. When **false**, the filter transition uses a 120 ms
opacity fade between blurred-text and revealed-text widgets (the
`ImageFilter.blur` value itself is constant — only the *alpha* of the
revealed overlay animates). The reduced-motion path also disables
the per-cue scale on the toolbar toggle.

**Rationale**:
- Reuses the project's existing reduced-motion convention (see
  `EnjoyTappableSurface`'s `instant` flag — already shipped).
- Animating the `ImageFilter.blur` sigma value per frame is
  dramatically more expensive than fading alpha; the cheaper fade
  covers the user's perception of "reveal" without GPU cost.
- 120 ms is short enough that reduced-motion users do not feel a delay
  when toggling blur off or hovering, but long enough that
  non-reduced-motion users see a smooth transition between blurred and
  revealed text.

**Alternatives considered**:
- *No transition at all* — would feel jarring on desktop when
  hovering across many adjacent cues quickly.
- *Animated `sigma` from e.g. 6 → 0 over 200 ms* — visually nicer but
  forces a filter recompute every frame; too expensive for the
  worst-case 10k-line transcript scrolling test.

---

## R-007 — Performance budget and evidence path

**Decision**:

- The blur filter is only attached when `blurEnabled == true`. When
  the toggle is off, the cue renders exactly as today — zero overhead.
- `ImageFilter.blur(sigmaX: 6, sigmaY: 6)` is hard-coded (no user
  strength slider in v1, per the spec's assumptions).
- When blur is on, only the **currently-built** cue widgets in the
  `ListView.builder` viewport have the filter attached — virtualized
  off-screen cues do not pay any blur cost.
- Hover state stays local to each tile (`setState`); only the global
  toggle and the tap-reveal hold cross widget boundaries via Riverpod.

**Performance evidence path** (one or more of):

- A widget test that pumps a 10 000-line transcript with blur on,
  scrolls to mid-list, and asserts the per-frame build time stays
  under the project's existing baseline (no dropped frames beyond the
  baseline measured without blur).
- A manual smoke on the slowest supported target (a low-end Android
  device or a Windows VM) with a long transcript + playback running.
- A trace export from `dart:developer`'s `Timeline` for the
  `Rasterizer::Draw` events during a 5-second hover-flicker.

**Rationale**: QR-004 / SC-007 require evidence for any feature that
touches transcript rendering. Filter effects are well-known
GPU/CPU hotspots on long lists; bounding the cost to the visible
viewport is the standard mitigation.

---

## R-008 — Echo mode interaction

**Decision**: When the cue is rendered inside the **echo region** (via
`TranscriptEchoRegionMergedCard`), the blur applies to the cue's body
text exactly as in the non-echo path. Hover and tap-reveal work the
same way. The merged echo card **shell** and the shadow-reading panel
are NOT blurred — only the cue body text inside the card.

**Rationale**: Today the echo region renders the same `TranscriptLineTile`
(`groupedInEcho: true`) — so no new code path is required. We only
need to make sure the blur widget is composed *inside* the existing
tile body, not around it.

**Alternatives considered**: a separate "echo blur mode" — rejected;
keeps the model uniform and avoids per-region conditional logic in the
tile widget.

---

## R-009 — Documentation & ADR

**Decision**: Update `docs/features/transcript.md` with a new section
"Blur practice mode" describing the toggle, hover, tap-reveal, default
hold duration, persistence keys, and the no-active-line-auto-reveal
rule (with a link back to the spec's Clarifications).

Do **not** create a new ADR for v1 — the design choices that would
warrant one (active-line rule, default hold duration, blur strength)
are already captured in the spec's Clarifications section and
Assumptions. If the team later wants to expose a blur-strength slider
or change the hold default, those are reversible product choices and
can be revisited; no architectural decision is being locked in by this
feature.

**Rationale**: ADR-0004 already records "feature-first architecture";
ADR-0018 already records the shared interactive primitives. The new
feature reuses both, so no new ADR is needed unless a *new* architectural
choice is made (e.g. moving the toggle out of the panel header into a
separate floating action button).

---

## R-010 — Open architectural decisions / risks

- **No `kIsWeb` branch.** Constitution explicitly forbids Flutter web.
  All rendering and platform-specific code uses `defaultTargetPlatform`
  via existing utilities.
- **No `print()`.** The notifier and any other Dart code in this
  feature MUST use `logNamed('transcript_blur')` (matches existing
  convention; see `lib/core/logging/log.dart`).
- **No new `Player()` outside the player engine/controller.** This
  feature does not touch playback engines at all — it only reads
  existing providers. The tap-to-seek path goes through
  `PlayerInteractions.seekTo(...)`, exactly as today's cue tap does.
- **`dart run build_runner build`** required once for the new
  `@Riverpod` annotated notifier and per-cue derived providers (the
  generator emits `.g.dart` files used by the notifier base class).

---

## Summary of resolved unknowns

| Spec item | Decision |
|---|---|
| Where to render the blur | Inside `TranscriptLineTile` body, around the primary/secondary text widgets only |
| Where the toggle lives | Toolbar row at the top of `TranscriptPanel` (above the list) |
| Persistence mechanism | Two new `SettingsKeys` entries + a Riverpod notifier mirroring `PlayerPreferencesCtrl` |
| Per-cue reveal model | Per-cue derived provider `transcriptCueRevealProvider(mediaId, cueId)`; reads toggle, tap-reveal hold, and the tile's local hover state |
| Active line behavior | No auto-reveal. Active cue has no privileged state in the reveal model. (Confirmed in 2026-07-08 clarification.) |
| Mobile tap-reveal | One cue on hold at a time; one `Timer` per media id; tapping replaces the hold |
| Reduced motion | Instant on/off when `MediaQuery.disableAnimationsOf` is true; 120 ms opacity fade otherwise |
| Performance budget | Filter only attached when toggle on; only on viewport-visible cues; verified by widget test + manual smoke |
| Echo mode | Blur applies inside the merged echo card; hover/tap-reveal work the same way |
| Documentation | Update `docs/features/transcript.md`; no new ADR for v1 |
