# Contract: Vocabulary practice sheet (clip + echo)

**Feature**: [spec.md](../spec.md) · **Plan**: [plan.md](../plan.md)

> Behavioral contracts for FR-003–FR-008, FR-006a/b, FR-011–FR-012, SC-002–005, SC-010–011.  
> **Supersedes** [023 vocabulary-media-actions C1/C3](../../023-vocabulary-context-richness/contracts/vocabulary-media-actions.md) for review-session play and shadow/echo.  
> **Replaces** the pre-clarify “inline Context embed” approach.

Open-in-player (023 C2) remains with full-player destination clarified.

---

## C1. Shared host

| Rule | Behavior |
|------|----------|
| One host | Play clip and Echo reading open the **same** practice sheet route/host |
| Modes | Sheet body is either clip mini-player **or** echo recorder — never both |
| Session | Opening/dismissing the sheet does **not** end the review session by itself |

---

## C2. Play clip → sheet clip mode

| Given | When | Then |
|-------|------|------|
| Active media context with valid locator (YouTube or local) | Tap Play clip | `practice = clip`; adaptive practice sheet shows clip body; shared player seeks/plays locator window |
| Clip active | Clip ends or learner dismisses sheet | Stay in review; `practice = none`; sensible idle |
| Missing / invalid media | Tap Play clip | Localized error; stay in review |

**Invariants**:

- MUST NOT require `GlobalTransportBar` as the sole/primary video surface.
- MUST NOT construct a second lesson-media `Player()`.
- MUST use `PlayerController` + `EchoMode` time window (or equivalent clamp).

---

## C3. Echo reading → sheet echo mode

| Given | When | Then |
|-------|------|------|
| Suitable media context | Tap Echo reading | `practice = echo`; same sheet shows recorder (record / playback / assess) |
| Recorder open | Complete a take | Without navigating away from review |
| Unavailable / mic denied | Attempt echo | Clear unavailable/error; stay in review |

**Invariants**:

- Default path does **not** confirm-exit to full player (023 C3 superseded for review).
- Reuse existing shadow recording/assessment stack.

---

## C4. Mutual exclusivity

| Given | When | Then |
|-------|------|------|
| Sheet in clip mode | Start echo | Sheet body becomes recorder; clip playback stops/yields |
| Sheet in echo mode | Start play clip | Sheet body becomes mini-player; recorder dismissed |
| Either | Dismiss / barrier / Esc | Sheet closes; `practice = none` |

No stacked dual sheets showing both modes.

---

## C5. Modal card interaction

| Given | When | Then |
|-------|------|------|
| Sheet open | Attempt rate / flip / Context tab controls on card | Blocked until dismiss |
| Sheet open | Esc (desktop) | Dismisses sheet first; second Esc may exit review |
| Sheet open | Context switch or card advance is requested | Sheet dismissed (or blocked until dismiss) before action applies |

---

## C6. Adaptive presentation

| Viewport | Presentation |
|----------|----------------|
| Compact / phone-width | Modal bottom sheet |
| Wide / desktop | Centered modal sheet (same content, same modal rules) |

Must reuse the app’s adaptive Enjoy sheet pattern (extend core helper if needed — today’s bottom-sheet-only API is insufficient alone).

---

## C7. Open in player (full)

| Step | Behavior |
|------|----------|
| Tap Open in player | Confirm: ends review |
| Cancel | Stay on card; if sheet was open, product may keep or dismiss — prefer keep cancel = no session change |
| Confirm | Dismiss sheet → clear session → `openPlayerRoute` → expanded player at locator start |
| Failure | Clear error; recover to Vocabulary |

---

## C8. Single-player ownership

| Allowed | Forbidden |
|---------|-----------|
| `PlayerController` open/seek/play/pause | Second `media_kit` Player for lesson media |
| `buildVideoStage` in sheet clip body | Video stage on sheet **and** expanded player together |
| `EchoMode` for clip/echo windows | Custom clip engine |
| `ShadowReadingPanel` in sheet echo body | Parallel vocabulary-only recorder stack |

---

## Out of scope

- Ebook play / echo.
- Redesigning Azure assessment UX.
- Non-modal persistent mini-player under the card.
