# Research: Vocabulary Polish

**Feature**: [spec.md](./spec.md) · **Plan**: [plan.md](./plan.md)

Resolves product/tech/UI choices after Clarifications session 2026-07-19. Prior research in [022](../022-vocabulary-screen-review/research.md) and [023](../023-vocabulary-context-richness/research.md) remains authoritative except where this document **supersedes** review media UX.

---

## 1. UI design system & visual hierarchy

**Decision**: Hierarchy fix, not restyle. Enjoy tokens, `EnjoyCard`, pill tabs, quiet text actions, immersive flashcard stage. Hub **list-first**; Context tab stays quote/actions/AI; **practice lives in a modal sheet**.

**Rationale**: Clarified preference for a clean card; embedding player+recorder fights sticky ratings. Sheet matches existing Enjoy modal language.

**Alternatives considered**:

| Option | Why rejected |
|--------|----------------|
| Inline Context embed (pre-clarify plan) | Crowds card; user chose sheet |
| Full-screen practice route | Feels like leaving review |
| Dashboard-style hub stats | Overbuilt |

---

## 2. Compact Vocabulary hub stats

**Decision**: Collapsed **Total | Due** + expand for new/learning/reviewing/mastered. Wide: thin horizontal metrics without tall bordered 2×3 tiles. Expand preference in-session only.

**Rationale**: Spec SC-001 / FR-001–002.

**Alternatives considered**: Horizontal scroll of 6 chips; stats-only overflow menu — weaker glanceability.

---

## 3. Shared modal practice sheet (clarified)

**Decision**: One sheet host for Play clip and Echo reading. Content swaps by `ReviewPracticeMode` (`clip` | `echo`). **Modal**: barrier blocks card rate/flip/Context controls. Dismiss → `practice = none`, pause lesson media, deactivate echo window. Review session stays active.

**Rationale**: Clarifications Q1–Q2; cleaner than inline; exclusivity is natural.

**Alternatives considered**:

| Option | Why rejected |
|--------|----------------|
| Inline embed | Clarification rejected |
| Non-modal sheet | Accidental ratings; unclear focus |
| Separate sheets per mode | Stacking risk; worse exclusivity |

**Side effects on dismiss / swap / card change**:

- Pause (or stop) lesson playback; `EchoMode.deactivate`.
- Unmount video stage / echo panel.
- Do not call `markReviewed`.

---

## 4. Adaptive sheet presentation (clarified)

**Decision**: Add `showEnjoyAdaptiveSheet` (name flexible) in `lib/core/theme/widgets/enjoy_modal.dart`:

- **Compact** (width &lt; ~600, align with existing layout breakpoints): current `showModalBottomSheet` styling from `showEnjoySheet`.
- **Wide**: `showEnjoyDialog` / centered `Dialog` with `modalMaxWidthLarge` (560), same scrim (`enjoyModalBarrierColor`), shared builder content.

Vocabulary practice uses this helper with `isScrollControlled: true` for tall echo content.

**Rationale**: Clarification Q3; today’s `showEnjoySheet` is **bottom-sheet-only** — must extend core helper to satisfy FR-006b without a vocabulary-only fork.

**Alternatives considered**:

| Option | Why rejected |
|--------|----------------|
| Always bottom sheet | Fails desktop clarification |
| Always centered dialog | Worse thumb reach on phones |
| Constrain max width inside bottom sheet only | Not a true centered modal on desktop |

---

## 5. Clip playback inside the sheet

**Decision**: On Play clip → set `practice = clip` → open/replace adaptive sheet → `playVocabularyClip` (openMedia + EchoMode time window + seek + play) → mount `activeEngine.buildVideoStage` in sheet body. Suppress `GlobalTransportBar` while sheet clip mode mounts the stage (art-only mini-bar must not be the video surface).

**Rationale**: Mini-bar cannot show live YT/local video (ADR-0003). Sheet hosts the single texture.

**Alternatives considered**: Fix mini-bar live video — forbidden dual texture; push full player for every clip — ends study focus.

---

## 6. Echo reading inside the sheet

**Decision**: On Echo → `practice = echo` → same sheet host → activate locator window → embed `ShadowReadingPanel` (record / playback / assess). **No** confirm-exit to full player (supersedes 023 C3 for review).

**Rationale**: Clarified in-session practice; reuse shadow stack.

**Alternatives considered**: Keep 023 hand-off only — fails stay-in-review; new recorder UI — duplicate.

---

## 7. Mutual exclusivity & keyboard

**Decision**: Enum `ReviewPracticeMode { none, clip, echo }`. Opening clip while echo (or reverse) swaps sheet body and tears down the other. Esc: dismiss sheet first if open, then exit review. Rating shortcuts only when `practice == none` / sheet closed.

**Rationale**: FR-006, FR-006a, desktop edge case in spec.

---

## 8. Open in player

**Decision**: Confirm → single `replacePlayerLaunch` with `PlayerLaunchRequest.vocabularyOpenSource` (`/player/:id?start=…&end=…&autoplay=1&clip=1&norestore=1`). Review route `onExit` clears the session. Do **not** pop-then-navigate (that aborted after `mounted` and left only the mini-bar). The normal expanded player/transcript screen opens with the context Echo window active; the launch pipeline owns seek/echo/autoplay (ADR-0057).

**Rationale**: Spec US5; path largely exists.

---

## 9. Multi-context switcher

**Decision**: Load all contexts at session start, sort `createdAt` asc, default index 0. Pager on card (prev/next + n of m) when length &gt; 1. While sheet open, context switch is unavailable until dismiss (modal); if product initiates advance, dismiss sheet first (FR-006a / FR-011).

**Rationale**: Spec US6 + modal clarification.

---

## 10. Feature import boundary

**Decision**: Vocabulary may import `ShadowReadingPanel`. Optional compact layout flag on panel if sheet height needs it. Adaptive sheet helper belongs in `core/theme` (shared).

**Rationale**: Avoid premature further core moves; sheet API is genuinely shared.
