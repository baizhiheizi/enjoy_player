# Contract: Vocabulary REST API Client

**Feature**: [spec.md](../spec.md) · Parent table: [docs/features/vocabulary.md](../../../docs/features/vocabulary.md) § REST API  
**Web client**: `enjoy/packages/api/src/services/vocabulary.ts`  
**Flutter pattern**: `lib/data/api/services/audio_api.dart` (`RestApi` + `ApiClient`)

## Base paths

| Resource | Path |
|----------|------|
| Items | `/api/v1/mine/vocabulary_items` |
| Contexts | `/api/v1/mine/vocabulary_contexts` |

No review-audit endpoints.

## Operations

### Items

| Method | Path | Body / query |
|--------|------|----------------|
| List | `GET …/vocabulary_items` | `language?`, `limit?` (default 50), `updatedAfter?` |
| Get | `GET …/vocabulary_items/:id` | |
| Upload | `POST …/vocabulary_items` | `{ "vocabularyItem": { … } }` |
| Delete | `DELETE …/vocabulary_items/:id` | |

### Contexts

| Method | Path | Body / query |
|--------|------|----------------|
| List | `GET …/vocabulary_contexts` | `vocabularyItemId?`, `sourceType?`, `sourceId?`, `limit?`, `updatedAfter?` |
| Get | `GET …/vocabulary_contexts/:id` | |
| Upload | `POST …/vocabulary_contexts` | `{ "vocabularyContext": { … } }` |
| Delete | `DELETE …/vocabulary_contexts/:id` | |

## Client rules

- `requireAuth: true` (signed-in only).
- Request JSON camelCase → snake_case via existing `ApiClient` conversion; responses snake → camel.
- Duplicate create: follow media upload pattern (treat as recoverable via GET by id when API signals duplicate).
- Require server `updatedAt` (or equivalent) before stamping local `synced` — same `SyncMissingUpdatedAtError` policy as audio/video.
- Pagination: advance cursor from max `updatedAt` in page; stop when page empty or short.

## Payload fields

Upload maps MUST include API-compatible ids and SRS/metadata fields present on Drift rows (exclude review audits). Locator and explanation remain JSON-compatible with web.

## Acceptance checks

| ID | Check |
|----|--------|
| C1 | Unit/integration with fake `http.Client`: list/upload/delete paths and envelope keys |
| C2 | Sync upload service stamps `synced` + `serverUpdatedAt` on success |
| C3 | 401 triggers existing refresh path; failed auth does not delete local vocabulary |
