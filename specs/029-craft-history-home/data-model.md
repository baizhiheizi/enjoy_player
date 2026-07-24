# Data Model: Craft History & First-Class Entry

**Date**: 2026-07-23 | **Feature**: 029-craft-history-home

## Entities

### Craft media item (existing)

Stored as library audio with Craft provenance. No new table.

| Field (logical) | Storage | Notes |
|-----------------|---------|-------|
| id | `Audios.id` | Stable across edit updates (FR-012) |
| provider | `Audios.provider` | Always `'craft'` for history membership |
| source flag | `Audios.source` | `craft-express` / `craft-translate` / `craft-direct` |
| title | `Audios.title` | Derived from text; refreshed on update |
| learning language | `Audios.language` | Prefill target/synth language |
| source / raw text | `Audios.sourceText` | Prefill Express raw / Advanced source when present |
| voice | `Audios.voice` | Prefill when still valid for language |
| local audio | `Audios.localUri`, size, mtime | Replaced on update save |
| content hash | `Audios.md5` | Recalculated on update; used for *new* import dedupe only |
| updatedAt | `Audios.updatedAt` | History sort key (desc) |
| practice text | Primary `Transcripts.timelineJson` | Joined text = target/learning text for edit |
| style | — | **Not stored**; edit uses Craft defaults |
| source language | — | **Not reliably stored**; edit uses profile/Craft defaults |

### Craft history entry (presentation)

| Attribute | Source |
|-----------|--------|
| mediaId | Craft media item id |
| label | title, else truncated practice text / sourceText |
| updatedAt | for ordering and optional subtitle |
| provider | must be `craft` |

### Craft edit session (in-memory)

Extension of existing `CraftJobState`:

| Field | Role |
|-------|------|
| `editingMediaId` | Non-null while revising a history item; cleared on new-create reset |
| `translatedText` / `synthText` | Prefill from transcript |
| `rawTranscript` / `sourceText` | Prefill from `sourceText` when available |
| `targetLanguage` / `synthLanguage` | Prefill from `language` |
| `selectedVoice` | Prefill or default |
| `style` | Default (not restored) |
| `stage` / `screenMode` | Set for editable revise path (see research R4) |

Unfinished sessions are discarded when leaving Craft (FR-016) — no draft entity.

## Relationships

```text
Library (Audios + Transcripts)
    └── Craft media items (provider=craft)
            ├── shown as Craft history entries (filtered view)
            └── opened as Craft edit session (editingMediaId → same id on save)
```

## Validation rules

- History membership: `provider == 'craft'` only.
- `updateCraftedFromText`: target id must exist and `provider == 'craft'`; otherwise fail with a calm user-visible error / “no longer available”.
- Target text length: same Craft max (5,000 chars) as create.
- Voice: if stored voice not in catalog for language, coerce to default (avoid dropdown assert).
- New create path: unchanged hash dedupe via `importCraftedFromText`.
- Edit save path: **must not** return a different media id via dedupe when `editingMediaId` is set.

## State transitions

### Create (unchanged)

```text
[new session] → capture/rewrite/advanced → generate → importCraftedFromText → library item
```

### Edit from history

```text
[history list] → select item → loadForEdit(mediaId)
    → editingMediaId = mediaId, fields prefilled
    → user edits / regenerates audio
    → updateCraftedFromText(mediaId, ...)
    → same id, updatedAt bumped → history order updates
```

### Clear edit identity

```text
resetForNextCapture / explicit new craft / leaving edit for fresh Express capture
    → editingMediaId = null
```

### Delete race

```text
item deleted while listed → stream removes entry
select missing id → loadForEdit fails → calm message, stay on history or return to Craft
```
