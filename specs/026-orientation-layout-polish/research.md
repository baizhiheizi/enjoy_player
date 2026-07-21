# Research: Phone / Tablet Orientation & Player Layout Polish

**Feature**: 026-orientation-layout-polish | **Date**: 2026-07-20

No `NEEDS CLARIFICATION` markers remained in the spec. This file records technical decisions that turn the assumptions into an implementable design.

---

## R1. Form-factor classification and where it lives

**Decision**: Introduce a small pure API in `lib/core/platform/`:

- `enum DeviceFormFactor { phone, tablet, desktop }`
- `DeviceFormFactor resolveDeviceFormFactor({required TargetPlatform platform, required double shortestSideLogical})`
- Desktop platforms (`windows` / `macOS` / `linux`) → always `desktop`
- Mobile platforms (`iOS` / `android`): `shortestSideLogical >= 600` → `tablet`, else `phone`
- Constant `kTabletShortestSideLogical = 600` (Material large-screen / common Flutter tablet threshold), documented next to the helper

Apply preferred orientations once in `main.dart` after `WidgetsFlutterBinding.ensureInitialized()`, using the first Flutter view’s logical size:

```text
physicalSize / devicePixelRatio → Size → shortestSide
```

**Rationale**: Matches the spec assumption (~600 shortest side), is orientation-independent, and mirrors how Material distinguishes compact vs medium/expanded. Keeps classification out of widgets and unit-testable. Reuses the existing `isMobilePlatform` / `isDesktop` split conceptually without overloading those getters.

**Alternatives considered**:

- *Width-only or `MediaQuery` in the first route.* Rejected: needs a mounted context; shortest side at bootstrap is enough for device class.
- *Platform channels / vendor tablet APIs.* Rejected: overkill; 600 dp is the industry default and matches the spec.
- *User Settings override.* Rejected by spec (v1 assumption).

---

## R2. Preferred orientations mapping

**Decision**:

| Form factor | `SystemChrome.setPreferredOrientations` |
|-------------|-----------------------------------------|
| `phone` | `[portraitUp, portraitDown]` |
| `tablet` | all four: portraitUp/Down + landscapeLeft/Right |
| `desktop` | do **not** call `setPreferredOrientations` (no-op path) |

Respect OS rotation lock implicitly: preferred orientations only constrain what the app *allows*; the OS still decides whether auto-rotate is enabled.

**Rationale**: Spec FR-001–FR-003. Including `portraitDown` keeps “upright” usable when the phone is flipped 180°. Skipping the call on desktop avoids fighting window managers.

**Alternatives considered**:

- *Portrait-up only on phones.* Acceptable alternative; rejected slightly in favor of both portrait orientations for readability upside-down.
- *Lock landscape in the player only on phones.* Rejected: user asked for app-wide no auto-rotate on phones, not player-only.

---

## R3. Native iOS / Android manifests

**Decision**:

- **iOS**: Update `ios/Runner/Info.plist` `UISupportedInterfaceOrientations` (iPhone) to **portrait only** (`UIInterfaceOrientationPortrait`, and optionally upside-down if we keep `portraitDown`). Leave `UISupportedInterfaceOrientations~ipad` with all orientations as today.
- **Android**: Keep current manifest (no `android:screenOrientation` lock). Rely on `SystemChrome` so tablet and phone share one Activity with runtime policy.

**Rationale**: iOS Info.plist currently allows iPhone landscape, which can fight or race the Flutter lock. Aligning plist with product policy makes phone behavior consistent before Dart runs. Android’s single-Activity model is cleaner with runtime `SystemChrome`.

**Alternatives considered**:

- *Dart-only, leave Info.plist unchanged.* Possible but weaker on cold start / system chrome before first frame.
- *Separate Android activities for phone vs tablet.* Rejected: unnecessary complexity.

---

## R4. Player stack vs side-by-side: aspect, not width breakpoint

**Decision**: In `VideoPlayerLayout`’s `LayoutBuilder`, replace:

```dart
constraints.maxWidth > t.breakpointTranscriptSideBySide
```

with a named helper (e.g. `usePlayerSideBySideLayout`):

```dart
constraints.maxWidth > constraints.maxHeight  // landscape → side-by-side
// height >= width (incl. square) → stacked
```

Keep `breakpointTranscriptSideBySide` for `GlobalTransportBar` and any other width-driven chrome. Do **not** remove the token from `EnjoyThemeTokens`.

**Rationale**: Spec FR-004–FR-006 and assumption “replaces width-breakpoint layout rule for player split.” Using **layout constraints** (not `MediaQuery.orientationOf` alone) matches split-screen / multi-window where the app window aspect differs from the physical display. Avoids the Flutter guidance pitfall of orientation widgets at the wrong tree level while still satisfying the product requirement.

**Alternatives considered**:

- *`MediaQuery.orientationOf(context)`.* Rejected as primary: can disagree with the player’s actual constraints in multi-window; constraints are the truth for this widget.
- *Keep 720 breakpoint and add orientation as AND/OR.* Rejected: contradicts “not depend on the screen width.”
- *Different rule for desktop vs mobile.* Rejected: spec explicitly wants desktop wider-than-tall → side-by-side.

---

## R5. Session stability across layout switches

**Decision**: Treat orientation/aspect change as a **layout-only** rebuild of `VideoPlayerLayout`. Do not recreate `PlayerEngine`, do not re-open media, do not clear transcript controllers. Preserve `_transcriptWidthPx` in State across rebuilds so returning to landscape restores the user’s split (still clamped by min/max). Existing `splitPx` persistence continues to apply when committing drag.

**Rationale**: SC-004 / User Story 3. The current widget already keeps engine and split state in State/providers outside the Row/Column branch; the change is only the branch condition.

**Alternatives considered**:

- *Force-reset split width on every orientation change.* Rejected: worse UX; clamp-on-use is enough when landscape width shrinks.

---

## R6. Testing strategy

**Decision**:

1. **Unit** pure helpers (form factor, preferred orientations, side-by-side predicate).
2. **Widget** `VideoPlayerLayout` with fixed surface sizes:
   - 900×600 → side-by-side
   - 800×1000 (wide portrait) → stacked (regression vs old 720 rule)
   - 700×400 (landscape below old 720) → side-by-side
   - 600×600 → stacked
3. **Manual** phone/tablet/desktop per `quickstart.md` (CI cannot fully simulate OS auto-rotate + form factor).

**Rationale**: Constitution II — automate the layout contract; document device checks for SystemChrome.

**Alternatives considered**:

- *Integration driver rotate APIs only.* Insufficient alone; keep unit/widget as primary CI gate.

---

## R7. Documentation / ADR

**Decision**: Add ADR-0059 documenting (1) phone portrait lock vs tablet free rotate, (2) player content layout driven by window aspect, (3) retention of 720 for transport packing. Update `docs/features/player.md` and `docs/features/app-ui.md`.

**Rationale**: Constitution V — product-scope orientation policy is costly to reverse silently.
