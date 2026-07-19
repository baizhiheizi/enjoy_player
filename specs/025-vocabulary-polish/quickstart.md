# Quickstart: Vocabulary Polish

**Feature**: [spec.md](./spec.md) · **Plan**: [plan.md](./plan.md)

Validation guide for hub stats polish, **modal adaptive practice sheet** (clip XOR echo), exclusivity, open-in-player, and multi-context switching.

---

## Prerequisites

- Phone-sized emulator/device **and** a wide desktop window.
- Seed data:
  - ≥ 3 vocabulary items.
  - **Item A**: YouTube context with valid locator.
  - **Item B**: Local video/audio context with valid locator.
  - **Item C**: **3 contexts** for pager testing.
- Mic permission for echo tests.
- Contracts:
  - [vocabulary-hub-stats.md](./contracts/vocabulary-hub-stats.md)
  - [vocabulary-practice-sheet.md](./contracts/vocabulary-practice-sheet.md)
  - [vocabulary-context-switcher.md](./contracts/vocabulary-context-switcher.md)
  - [vocabulary-flashcard-layout.md](./contracts/vocabulary-flashcard-layout.md)

---

## Automated checks (after implementation)

```bash
bash .github/scripts/validate_ci_gates.sh --fix
flutter test test/features/vocabulary/
```

Expect coverage for: compact stats, context pager, practice sheet open/swap/dismiss, modal block of rate while open, session context selection.

---

## Manual scenarios

### 1. Hub is list-first (phone)

1. Open Profile → Vocabulary on a narrow viewport.
2. **Expect**: Compact Total + Due (not tall 2×3 grid); tabs + list visible quickly.
3. Expand stats → status breakdown; collapse → summary.

### 2. Practice sheet — YouTube clip

1. Review including Item A; flip to Context; tap **Play clip**.
2. **Expect**: Adaptive practice sheet opens (bottom sheet on phone) with mini-player; clip window plays; review session still active underneath (modal).
3. Try to rate without dismissing → blocked.
4. Dismiss → back on card; can rate.

### 3. Practice sheet — local clip

1. Same as §2 with Item B.
2. **Expect**: Same sheet behavior for local media.

### 4. Practice sheet — echo reading

1. Tap **Echo reading**.
2. **Expect**: Same sheet host, echo body (recorder); record / playback / assess; stay in review; no confirm→full-player exit.

### 5. Exclusivity + modal

1. Play clip → then Echo → sheet shows recorder only.
2. Echo → then Play clip → sheet shows player only.
3. With sheet open, rate/flip unavailable until dismiss.

### 6. Desktop adaptive presentation

1. Wide window; open Play clip.
2. **Expect**: Centered modal sheet (not a phone bottom sheet stuck oddly); same modal rules (SC-011).

### 7. Open in player

1. Open in player → cancel → still in review.
2. Confirm → review ends → **full** player at locator start (YouTube and local).

### 8. Multi-context pager

1. Review Item C; Context shows “1 of 3”.
2. Dismiss any sheet; step through contexts; actions follow each.
3. Rate → one item-level SRS update.

### 9. Esc order (desktop)

1. Open practice sheet; press Esc → sheet dismisses.
2. Press Esc again → exit review (existing behavior).

---

## Done when

- [ ] Vocabulary tests green + CI gates.
- [ ] Manual §1–§9 pass on phone and desktop width.
- [ ] `docs/features/vocabulary.md` updated for hub stats + practice sheet + context pager.
