# Contract: Vocabulary explanation write-through

**Feature**: [spec.md](../spec.md) · **Plan**: [plan.md](../plan.md)

> Behavioral contracts for Dictionary / contextual AI persist on review (FR-002, FR-004, FR-005, FR-010).

---

## C1. Dictionary tab

| State | Behavior |
|-------|----------|
| Cached JSON present & valid | Render `DictionaryResult` (IPA/lemma/senses) without network |
| Cached missing / invalid | Show localized unavailable / empty; offer fetch when allowed |
| Fetch allowed | Call existing dictionary service (cache-first); on success persist JSON on **item** and refresh session item |
| Fetch denied / offline / error | Clear error or unavailable copy; do not write partial junk |

**Invariants**:

- Persist target is `VocabularyItem.explanation` for that card’s item id.
- SRS fields unchanged by dictionary persist.
- `ratingInFlight` and dictionary fetch in-flight are independent; rating still blocked only while rating writes.

---

## C2. Contextual translation on Context tab

| State | Behavior |
|-------|----------|
| Cached JSON present & valid | Show `translatedText` without network |
| Cached missing | Offer fetch when allowed |
| Fetch success | Persist JSON on **that context id** only; refresh primary context cache |
| Fetch failure | Error/unavailable; no write |

**Invariants**:

- Sibling contexts on the same item keep their prior explanations.
- Payload shape stays compatible with `ContextualTranslationResult` / parent feature doc.

---

## C3. Offline re-open

| Given | Then |
|-------|------|
| Item/context explanation previously persisted | Visible after app restart without network |
| Never persisted | Unavailable offline; no fabricated AI content |

---

## Out of scope

- Seeding explanations at lookup “Add to Vocabulary” time (optional follow-up).
- Sync upload of explanations (P3).
- Anki export consuming explanations (P4).
