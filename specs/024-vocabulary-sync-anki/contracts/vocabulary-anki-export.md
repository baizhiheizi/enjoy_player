# Contract: Vocabulary Anki CSV Export

**Feature**: [spec.md](../spec.md) · Parent: [docs/features/vocabulary.md](../../../docs/features/vocabulary.md) § Anki export  
**Web reference**: `enjoy/apps/web/src/lib/anki/export-csv.ts`, `enjoy/apps/web/docs/anki-export-data-standard.md`

## Surface

| Element | Behavior |
|---------|----------|
| Entry | All Words → **Export to Anki** |
| Free tier | Show Pro-required description + **Upgrade to Pro** → `/subscription`; do **not** produce CSV |
| Pro tier | Open export dialog → filters → generate → save/share |
| Empty filter result | Toast/dialog: no items to export; no file |

## Filters (web parity)

| Filter | Values |
|--------|--------|
| Search | Case-insensitive contains on `word` or `language` |
| Status | `all` \| `new` \| `learning` \| `reviewing` \| `mastered` |
| Language | `all` \| one of distinct `item.language` values in the book |

## File contract

| Property | Requirement |
|----------|-------------|
| Encoding | UTF-8 with leading BOM `\uFEFF` |
| Delimiter | Comma |
| Columns | `Front`, `Back`, `Tags` |
| HTML | Allowed in Front/Back (Anki “Allow HTML in fields”) |
| Rows | One per vocabulary **item** |

### Tags

```
vocabulary {language}-{targetLanguage} [status if status != new]
```

Space-separated. Example: `vocabulary en-zh learning`.

### Front (HTML)

1. Word: large, bold, centered.
2. If any contexts: “Context” block with context texts joined by `<hr>`.

### Back (HTML), omit empty sections

Order:

1. Context translations (from each context `explanation.translatedText`; markdown→simple HTML; join with `<hr>`).
2. IPA / pronunciation if present on item explanation.
3. Primary translation if present.
4. Part of speech if present.
5. Numbered definitions from senses.
6. Examples (source + optional target).
7. Source references when titles/types resolvable (ebook titles may be missing).

**Must not** invent definitions/translations when cache is empty.

### CSV escaping

- Fields with comma, quote, or newline wrapped in `"…"`.
- Internal `"` doubled as `""`.

## Save / share

| Platform | Behavior |
|----------|----------|
| iOS / Android | Share sheet with `text/csv` (or equivalent) bytes + suggested filename |
| Desktop (macOS / Windows / Linux) | Save-file dialog with suggested filename |

Suggested name pattern: `enjoy-vocabulary-anki-YYYYMMDD.csv` (exact stamp flexible).

## Acceptance checks

| ID | Check |
|----|--------|
| C1 | Pro export of N items → CSV has N data rows + correct columns + BOM |
| C2 | Free path never yields a downloadable CSV |
| C3 | Filters reduce row count as expected |
| C4 | Multi-context item merges on Front; Back uses cached explanations only |
| C5 | Cancelled save/share is non-destructive (no crash; vocabulary unchanged) |
