# Contract: Vocabulary review media actions

**Feature**: [spec.md](../spec.md) · **Plan**: [plan.md](../plan.md)

> Behavioral contracts for play segment, open in player, and shadow hand-off (FR-006–FR-009).

---

## C1. Play segment (stay in review)

| Given | When | Then |
|-------|------|------|
| Media context with valid `MediaLocator` and resolvable `sourceId` | Learner taps Play segment | Shared player opens that media, seeks to locator start, plays the segment window; **review session remains active** |
| Ebook / invalid locator | View actions | Play hidden or disabled |
| Missing / unreadable media | Tap Play | Localized failure; stay in review |

**Invariants**:

- MUST NOT construct a second media player engine.
- MUST NOT call `markReviewed`.
- Prefer echo/time-window clamp when available; fallback seek+play+stop-at-end is acceptable.

---

## C2. Open in player (ends review)

| Step | Behavior |
|------|----------|
| Tap Open in player | Show confirm: opening player ends the review session |
| Cancel | Stay on same card; session unchanged |
| Confirm | Exit/clear review session (committed ratings kept) → navigate to player for `sourceId` → seek near locator start |
| Open failure after confirm | Clear failure messaging; do not leave a stuck half-session without destination recovery (return to Vocabulary if player cannot open) |

---

## C3. Shadow reading (hand-off)

| Step | Behavior |
|------|----------|
| Suitable media context | Show Shadow reading action |
| Unsuitable | Hide/disable |
| Tap | Confirm that continuing opens the player / leaves review (same spirit as open-in-player) |
| Confirm | Exit review → open player → activate echo for locator time span → existing transcript echo hosts shadow UI |
| Cancel | Stay in review |

**Invariants**:

- Reuse existing shadow-reading entry patterns; do not embed a parallel shadow engine in the flashcard.
- Already-saved ratings remain; current unrated card is not auto-rated.

---

## C4. Single-player ownership

| Allowed | Forbidden |
|---------|-----------|
| `PlayerController.openMedia` / seek / play | `Player()` / second `media_kit` instance |
| `EchoMode.activate` / restore patterns | Custom audio engine for vocabulary clips |
| `openPlayerRoute` | Ad-hoc navigator hacks that skip player open pipeline |

---

## Out of scope

- Ebook playback / Readium.
- Global hotkeys for play/shadow (in-session UI actions only).
- Home due widget.
