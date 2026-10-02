# ADR-0091 — Duet design language (supersedes the ADR-0089 Aurora look)

**Status**: Accepted
**Date**: 2026-10-02

**Supersedes**:
- [ADR-0089](0089-aurora-design-language.md): §1 palette, §2 aurora glow, §3 type, §5 depth treatment, §8 shell, and §9 component treatments.
- [ADR-0007](0007-dynamic-color-from-artwork.md): artwork no longer tints any chrome.
- [ADR-0085](0085-audio-floating-collapse-chrome.md): the player gets a solid top bar instead of the floating frosted collapse control.

**Keeps**:
- ADR-0089 §4 (Phosphor icons through `EnjoyIcons`), §6 (no ink ripples, `EnjoyPressable`, keyboard focus ring), and §7 (one glide transition, Cupertino on iOS).
- ADR-0083 §3 (System / Light / Dark).
- ADR-0055 page kinds, with widths amended below.
- ADR-0018, ADR-0059 (phones portrait-only), ADR-0066 (surface parking), ADR-0068 (share rule), ADR-0075 / ADR-0076 (IPA), and ADR-0082 (no mini player).

**Design reference**: [`docs/design/duet/`](../design/duet/README.md) (renders, board sources, tokens). **Plan**: [`PLAN.md`](../design/duet/PLAN.md), tracked in [`STATUS.md`](../design/duet/STATUS.md).

## Context

Aurora (ADR-0089) was never released. It gave the app one coherent chrome, but the player still read as a media player with a practice panel bolted on:

- The loop, takes, and scores lived in a separate panel and two dialogs.
- Four accents competed: iris, echo coral, blur teal, and traffic-light scores.
- The chrome changed hue with every item's artwork.

The Enjoy web app's proposed redesign ("Quiet Studio") was audited for reuse. Its in-place modes were right. Its auto-repeating loop and typing dictation conflict with the player's behavior, which this redesign must not change. The Player goes first; the web app follows the same language later.

## Decision

Adopt **Duet**: *first the original voice, then yours*. Only the UI and UX change. Features, behavior, hotkeys, and data are frozen. The Echo loop keeps pause-and-rewind at the loop end.

1. **Two voices.** The logo's two gradient ends become the product's two roles.
   - `original` (blue #4797F5) is the speaker: playback, the spoken word, reference pitch, Listen.
   - `you` (violet #8B2FE0) is the learner: the Echo loop, Record, takes, your pitch, and notes on a take.
   - The brand gradient (#2563EB → #7C3AED) is Enjoy itself: Play, primary buttons, Pro, the goal ring.
   - Everything else is ink on cool neutrals (`ground` / `paper` / `raised` / `sunk` / `line`, `ink` / `ink2` / `ink3`).
   - The voices are never told apart by hue alone. The original is always the translucent layer and you the solid one, with a ~1.9:1 lightness gap in both themes.
2. **Type.**
   - Literata: content, meaning transcripts, page titles, and big numbers.
   - Geist: interface.
   - Geist Mono: time, scores, keys, and IDs.
   - Noto Sans: IPA.
   - Every weight in use is bundled under `assets/fonts/google_fonts/`. Instrument Serif and Source Serif 4 leave once unused.
3. **Modes are lenses.** Listen and Echo share one transcript and one screen.
   - Echo grows the loop line in place and fades the rest through the logo's opacity steps (1 / 0.65 / 0.35 / 0.2).
   - Expand and shrink stay on `[` `]` `{` `}`.
4. **Controls below, context beside.**
   - Every player control lives in the dock. The dock has three variants: Listen, Echo, and Recording.
   - Word lookup and take assessment open in a 380 px side margin *on the player*. At ≥ 1100 px it is docked in the layout; between 600 and 1100 px it is a drawer route; on phones it is a bottom sheet.
   - This replaces the lookup dialog and the assessment dialog on the player only. Other callers keep their presentation.
5. **Feedback on the words.**
   - Mispronounced words get a wavy `you` underline, and a missing break gets a pause mark.
   - While recording, the countdown fills along the words.
   - Scores are never colored: an ink number plus a four-step meter, on today's thresholds (≥ 91 / 81 / 61).
6. **Hide text renders as word shapes** instead of a Gaussian blur, with the same reveal rules.
7. **Sentence ruler.** One tick per line, the loop bracket, and practiced dots replace the progress strip.
8. **Shell.**
   - Pages sit on `ground` beside the sidebar: no floating content panel and no glow.
   - The 244 px sidebar adds Vocabulary (with its due count) and Craft rows.
   - The phone tab bar keeps its four destinations as a solid bar.
9. **Flat surfaces.** No glass, backdrop blur, ambient backdrop, or artwork tint.
10. **Generated covers.** Media without artwork gets a cover cut from the logo's three triangles (`tokens.json → generatedCover`).
11. **Page widths.** ADR-0055 page kinds are unchanged. Desktop gutter is 40 and phone 16. Max widths: browse 1180, hub 840, form 680; Craft 1080.

## Consequences

- **Rollout.** Every screen changes. The work happens on the `design-duet` branch in the phases of `PLAN.md` and merges to `main` as one release.
- **Tokens: alias, then migrate, then delete.** `EnjoyThemeTokens` gains the Duet names, and the Aurora names forward to them, so every commit stays green. A rename pass at the end deletes the aliases and Aurora-only tokens. A test pins the Dart values to `docs/design/duet/tokens.json`.
- **Video surfaces.** The native video and YouTube surfaces are positioned under Flutter, and WebView2 paints above Flutter overlays on Windows.
  - The docked margin must be a layout sibling, so the video target reflows.
  - The drawer and the sheet must be routes, so `PlayerSurfaceOverlayCoordinator` parks the surface.
  - Never use a non-route overlay above the stage.
- **Performance.**
  - Word shapes replace a blur filter, which is cheaper.
  - The player loses every `BackdropFilter`.
  - The lens animation and the ruler must not rebuild the whole transcript per frame. Painting uses `CustomPainter` behind `RepaintBoundary`.
- **Tests.** Behavior tests (application / domain / data) must not change. Widget tests that find glass, aurora, or score colors are rewritten. `aurora_design_language_test.dart` becomes `duet_design_language_test.dart` and keeps its scans.
- **Docs.** `docs/features/app-ui.md` is rewritten for Duet. Feature docs change only where presentation is described.
- **Risk.** A long-lived branch drifts from `main`. Merge `main` into `design-duet` at least weekly. Behavior fixes land on `main` first.
