# Data Model: Vocabulary Polish

**Feature**: [spec.md](./spec.md) · **Plan**: [plan.md](./plan.md)

No Drift schema changes. Extends **ephemeral review-session state** and clarifies UI binding. Clarifications: practice chrome is a **modal adaptive sheet**, not an inline Context embed.

---

## Existing persisted entities (unchanged)

### VocabularyItem

Unchanged. SRS updated only by flashcard ratings.

### VocabularyContext

| Field | Role |
|-------|------|
| `id` | Stable identity when switching |
| `vocabularyItemId` | Groups contexts for pager |
| `sourceType` / `sourceId` | Media open + ShadowReadingPanel `mediaId` |
| `text` | Quote + echo `referenceText` |
| `locator` | Clip window + open-in-player seek |
| `createdAt` | Default pager order |
| `explanation` | Contextual AI (023) — per-context |

### MediaLocator

Unchanged: `start` + `duration` ms → `startSec` / `endSec`.

---

## Ephemeral session state

Owned by `VocabularyReviewSession`. Not persisted.

### Contexts by item

| Field | Type | Rules |
|-------|------|-------|
| `contextsByItemId` | `Map<String, List<VocabularyContext>>` | Loaded at `start`; sorted by `createdAt` ascending |
| `activeContextIndexByItemId` | `Map<String, int>` | Default `0`; clamped |

**Derived**: `activeContext` for current card.

### Review practice mode

```text
enum ReviewPracticeMode { none, clip, echo }
enum ReviewPracticePhase { none, clipOpening, clipReady, echo }
```

| Field | Type | Rules |
|-------|------|-------|
| `practicePhase` | `ReviewPracticePhase` | Default `none`; drives sheet + portal claim |
| `practiceMode` | derived | `clip` while `clipOpening`/`clipReady`; else matches phase |
| `mediaError` | `String?` | Last play failure |

**Presentation coupling**: Clip claims the permanent `PlayerSurfaceHost` portal only in `clipReady`. Echo is recorder-only (no portal / no player session). Sheet is **modal** — card actions disabled while open.

### Transitions

```text
[Session start]
  load contexts → index 0 → phase = none

[Play clip] → phase = clipOpening → openMedia(explicit) → seek → echo window → play → clipReady
[Echo]      → phase = echo → ShadowReadingPanel (context metadata only)
[Dismiss sheet / barrier / Esc]
            → pause + clear playback session (if clip) → phase = none (review queue kept)
[selectContext / rate / skip / next card]
            → must dismiss sheet first (modal) → phase = none → then action
[Open in player confirm]
            → replace with PlayerLaunchRequest.vocabularyOpenSource
            → expanded player + context echo window → onExit clears review session
```

### Mini-bar suppression

| Signal | Rules |
|--------|-------|
| Suppress `GlobalTransportBar` | While practice phase is clip (`clipOpening` or `clipReady`) |

---

## Validation rules

1. Play / echo / open require `vocabularyContextSupportsMediaActions(activeContext)`.
2. Pager visible iff `contexts.length > 1`.
3. Rating targets item only.
4. Context switch does not write SRS.
5. Locator `duration <= 0` or null → media actions unavailable.
6. While `practiceMode != none`, rate/flip/Context controls are not actionable (modal).

---

## Out of scope

- Per-context SRS
- Persisting last context index or sheet expand prefs
- New DB columns
- Ebook locator playback
