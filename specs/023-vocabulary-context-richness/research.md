# Research: Vocabulary Context Richness

**Feature**: [spec.md](./spec.md) · **Plan**: [plan.md](./plan.md)

Resolves open product/tech choices for **P2**. Foundation (021) and screen/review (022) research remain authoritative for identity/SRS/navigation/session loop.

---

## 1. Session must retain full primary context

**Decision**: Change `ReviewSessionState.primaryContextByItemId` from `Map<String, String>` (text only) to `Map<String, VocabularyContext>` (or a small session DTO with id, text, sourceType, sourceId, locator, explanation). Keep P1 rule: primary = earliest by `createdAt`. After explanation updates, refresh both the item in `queue` and the cached primary context.

**Rationale**: Clip play, open-in-player, shadow, and contextual persist all need `sourceId` + `locator` + context `id`. Text-only cache forces re-queries and cannot target the correct context row for write-through.

**Alternatives considered**:

| Option | Why rejected |
|--------|----------------|
| Re-query contexts on every Context-tab build | Extra Drift work; racey with multi-context |
| Store only context id | Still need locator/source for every action; full snapshot is simpler |

---

## 2. Explanation persistence format

**Decision**:

| Entity | Payload | Storage |
|--------|---------|---------|
| Item `explanation` | `DictionaryResult.toJson()` string | UTF-8 JSON text column (already exists) |
| Context `explanation` | `ContextualTranslationResult.toJson()` (`translatedText`, optional metadata later) | UTF-8 JSON text column |

Reuse `DictionaryResult` / `ContextualTranslationResult` from `lib/features/ai/domain/models/`. Flashcard Dictionary UI already `jsonDecode` → `DictionaryResult.fromJson`.

**Rationale**: Matches parent feature doc shapes and unlocks Anki later without re-keying. Lookup sheet today only writes AI cache — P2 adds **write-through** to vocabulary entities so review offline works without depending on AI-cache TTL.

**Alternatives considered**:

| Option | Why rejected |
|--------|----------------|
| Persist markdown-only strings | Breaks Dictionary tab structured render; weaker Anki backs |
| Rely only on `AiDictionaryCache` | Cache is not the vocabulary book of record; can evict |

---

## 3. Repository / DAO write path

**Decision**:

- Add `VocabularyRepository.updateItemExplanation(itemId, explanationJson)`.
- Add `VocabularyRepository.updateContextExplanation(contextId, explanationJson)`.
- Add `VocabularyContextDao.updateRow` (item DAO already has `updateRow`).
- Touch `updatedAt` on write; leave SRS fields unchanged.
- Do **not** bump Drift schema (already schema **15** / ADR-0052).

**Rationale**: Inserts currently set `explanation: null`. Read path already maps columns. Missing context update is the only hard gap.

**Alternatives considered**: Full-row replace from UI-held entities — OK if careful; dedicated explanation updaters reduce accidental SRS overwrites.

---

## 4. AI fetch + auth gating

**Decision**: Reuse `dictionaryServiceProvider` / `contextualTranslationServiceProvider` and existing AI caches (`AiDictionaryCache`, `AiContextualTranslationCache`). Gate fetch UI with the same signed-in / credits patterns as lookup sections (`LookupSectionAuthGate` / equivalent). On success: update AI cache (optional, for dedupe) **and** vocabulary explanation columns. On failure/offline: localized empty/error; never invent offline AI.

**Rationale**: Spec requires auth/credits parity with dictionary-lookup. Cache-first reduces cost; vocabulary write-through is the durable review cache.

**Alternatives considered**: New vocabulary-only AI clients — duplicate; rejected.

---

## 5. Clip playback while staying in review

**Decision**: On Play segment (media locator only):

1. Ensure media is open via `PlayerController.openMedia(sourceId)` (no second `Player()`).
2. Convert locator `start`/`duration` ms → seconds end = start + duration.
3. Seek to start; `play()`. Prefer activating `EchoMode` with that time window so the echo enforcer clamps/loops like transcript echo; resolve transcript line indices when a transcript is loaded, otherwise activate with best-effort indices (e.g. `-1` or nearest lines) **if** enforcer uses times — verify in implementation; fallback is seek + play without loop and stop when position ≥ end (listener/timer in vocabulary media helper).
4. Remain on `/vocabulary/review` (audio/clip does not require leaving the route).

**Rationale**: Spec SC-003 / FR-006: hear the clip without ending review; constitution forbids a second engine. Player is app-scoped; video surface may not be visible on review route — acceptable for “hear clip”; Open in player covers full UI.

**Alternatives considered**:

| Option | Why rejected |
|--------|----------------|
| Navigate to player for every clip | Ends study focus; contradicts “stay in review” |
| Hidden second `Player` | Forbidden |
| Always require transcript line indices | Locators are time-based; capture already stores ms |

---

## 6. Open in player

**Decision**: Confirm dialog (`openInPlayer` / `openInPlayerDescription`) → on confirm: clear/exit review session (committed ratings kept) → `openPlayerRoute(context, mediaId)` → seek to locator start seconds. Cancel leaves session on the same card.

**Rationale**: Web parity; `openPlayerRoute` is the shared navigation helper (`lib/core/routing/player_navigation.dart`).

**Alternatives considered**: Replace review with player without confirm — too easy to lose session place; spec requires confirm.

---

## 7. Shadow reading hand-off

**Decision**: Do **not** embed `ShadowReadingPanel` inside the flashcard. Offer Shadow reading on Context tab when media + locator exist; confirm that continuing opens the player (and ends review). Then: open player → activate echo for locator span → existing transcript echo UI hosts `ShadowReadingPanel`.

**Rationale**: Shadow panel is built for player + transcript + echo state. Embedding under review would fight single-player ownership and chrome. Spec US5 explicitly allows intentional hand-off with confirm.

**Alternatives considered**:

| Option | Why rejected for P2 |
|--------|---------------------|
| Embed panel in flashcard | Needs open media + echo + transcript providers under review; high complexity |
| Defer shadow entirely | Spec includes it for web parity; hand-off is enough |

---

## 8. Ebook / missing media

**Decision**: If `sourceType` is ebook or locator is not `MediaLocator`, hide/disable play, open-in-player, and shadow with clear unavailable copy. If media id missing from library, show failure on action — do not crash.

**Rationale**: Feature doc defers ebook UI; schema already ready.

---

## 9. ADR necessity

**Decision**: **No new ADR** for P2. ADR-0052 already covers explanation columns; ADR-0053 covers routes; single-player ownership is constitution / existing player ADRs. Document behavior in `docs/features/vocabulary.md` P2 checklist only.

**Rationale**: No costly-to-reverse architecture choice beyond wiring existing seams.

**Alternatives considered**: ADR for “shadow hand-off from review” — optional later if product expands in-session shadow.

---

## 10. Copy from lookup into vocabulary on add (out of scope)

**Decision**: P2 does **not** require copying lookup-sheet AI results into the item at add time. Write-through happens from review tabs (and may later be a small enhancement).

**Rationale**: Spec stories are review-tab focused; keeps P2 bounded. Optional follow-up: on `addWithContext`, if lookup already has dictionary JSON, seed `item.explanation`.
