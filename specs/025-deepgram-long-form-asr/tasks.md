# Tasks: Deepgram Long-Form ASR (Flutter Client)

**Input**: Design documents from `specs/025-deepgram-long-form-asr/`

**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/, quickstart.md

**Tests**: Automated tests are required for changed behavior (constitution + plan QR-002). Staging E2E per [quickstart.md](./quickstart.md) after Worker media upload lands.

**Organization**: Tasks are grouped by user story. MVP = **US1** (long-form Enjoy path). **Worker media upload** (enjoy monorepo) is a foundational blocker for product E2E; Flutter can proceed with mocked HTTP.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **ASR feature**: `lib/features/asr/{application,data,domain,presentation}/`
- **Enjoy AI**: `lib/features/ai/data/enjoy/`, `lib/features/ai/domain/models/`
- **API**: `lib/data/api/services/ai/`
- **DB**: `lib/data/db/`
- **Tests**: `test/features/asr/`, `test/features/ai/`
- **Feature docs**: `docs/features/asr.md`
- **ADRs**: `docs/decisions/0058-enjoy-deepgram-long-form-asr.md` (number if 0058 taken)
- **Worker (cross-repo)**: `~/projects/enjoy/apps/worker/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Confirm touch points and doc/l10n/ADR targets before code changes

- [x] T001 Confirm affected paths from plan against current tree: `lib/features/asr/application/asr_generation_controller.dart`, `asr_generation_job.dart`, `asr_long_media_dialog.dart`, `asr_failure_messages.dart`, `lib/features/asr/domain/asr_timeline_builder.dart`, `lib/features/ai/data/enjoy/enjoy_asr_capability.dart`, `lib/data/api/services/ai/asr_api.dart`, `lib/data/api/services/ai/ai_api_providers.dart`, `docs/features/asr.md`
- [x] T002 [P] Identify doc/ADR/l10n targets: `docs/features/asr.md`, next ADR under `docs/decisions/` (+ `docs/decisions/README.md`), `lib/l10n/app_en.arb` (+ `app_zh.arb` / `app_zh_CN.arb`)
- [x] T003 [P] Confirm Worker upload gap vs [contracts/media-upload.md](./contracts/media-upload.md) and note enjoy-monorepo PR dependency in `specs/025-deepgram-long-form-asr/plan.md` Summary (no code yet)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Shared DTOs, HTTP clients, phases, ARB keys, and attempt persistence that all stories need

**⚠️ CRITICAL**: No user story work can begin until this phase is complete. Product E2E also needs Worker upload (T008) in the enjoy monorepo.

- [x] T004 [P] Add long-form DTO models (`AsrLongFormJob`, failure/usage/transcript) in `lib/features/asr/domain/asr_long_form_models.dart` per [data-model.md](./data-model.md)
- [x] T005 [P] Add `AsrLongFormMapper` (job transcript → `AsrResult`) stub API in `lib/features/asr/domain/asr_long_form_mapper.dart` per [contracts/enjoy-asr-capability.md](./contracts/enjoy-asr-capability.md)
- [x] T006 Extend `AsrGenerationPhase` with `uploading` and `polling` in `lib/features/asr/application/asr_generation_job.dart`
- [x] T007 [P] Add ARB keys for upload/polling status and long-form failures (`asrStatusUploading`, `asrStatusPolling`, retryable/unsupported/billing messages as needed) in `lib/l10n/app_en.arb` and mirror in `app_zh.arb` / `app_zh_CN.arb`; run `flutter gen-l10n`
- [x] T008 **[Cross-repo]** Implement Worker authenticated media upload into `DEEPGRAM_ASR` per [contracts/media-upload.md](./contracts/media-upload.md) in enjoy `apps/worker` (route + tests + doc update to `apps/worker/docs/long-form-transcription.md`); block staging E2E until merged
- [x] T009 [P] Implement Flutter `AsrMediaUploadApi` client in `lib/data/api/services/ai/asr_media_upload_api.dart` (+ provider wire in `lib/data/api/services/ai/ai_api_providers.dart`) matching [contracts/media-upload.md](./contracts/media-upload.md)
- [x] T010 Extend `AsrApi` with `submitLongForm` and `getTranscriptionJob` in `lib/data/api/services/ai/asr_api.dart` per [contracts/worker-long-form-api.md](./contracts/worker-long-form-api.md)
- [x] T011 Implement `AsrLongFormAttemptStore` (persist/resume mediaId, idempotencyKey, jobId, mediaReference) in `lib/features/asr/data/asr_long_form_attempt_store.dart` — use Drift table under `lib/data/db/` if needed and run `dart run build_runner build`
- [x] T012 [P] Add shared long-form constants (`kLongFormMinDurationSeconds = 900`, poll backoff 2s→30s) in `lib/features/asr/domain/asr_long_form_constants.dart`

**Checkpoint**: DTOs, HTTP clients, phases, ARB, attempt store ready — US1 can start with mocked upload/Worker

---

## Phase 3: User Story 1 - Transcribe long local media via Enjoy (Priority: P1) 🎯 MVP

**Goal**: Signed-in Enjoy path for local media ≥ 15 minutes uploads audio, submits a Deepgram long-form job, polls to completion, and saves a primary timed `source: ai` transcript.

**Independent Test**: Mock (or staging) upload + submit + poll for ≥900s media → AI track appears, seek/highlight work ([quickstart.md](./quickstart.md) manual §1–5; SC-001).

### Tests for User Story 1

- [x] T013 [P] [US1] Unit test `AsrLongFormMapper` (segments + words → `AsrResult` usable by timeline) in `test/features/asr/domain/asr_long_form_mapper_test.dart`
- [x] T014 [P] [US1] Unit test Enjoy routing: `durationSeconds >= 900` invokes upload/submit/poll sequence (mocked HTTP) in `test/features/ai/data/enjoy/enjoy_asr_capability_long_form_test.dart`
- [x] T015 [P] [US1] Unit/controller test long-form happy path reaches `success` with upserted track id in `test/features/asr/application/asr_generation_controller_long_form_test.dart`

### Implementation for User Story 1

- [x] T016 [US1] Implement `AsrLongFormMapper` fully in `lib/features/asr/domain/asr_long_form_mapper.dart` (words → segments fallback → plain text)
- [x] T017 [US1] Implement long-form branch inside `EnjoyAsrCapability.transcribe` in `lib/features/ai/data/enjoy/enjoy_asr_capability.dart` (upload → submit → poll → map) per [contracts/enjoy-asr-capability.md](./contracts/enjoy-asr-capability.md); keep short-clip multipart for `< 900`
- [x] T018 [US1] Wire progress callbacks / cancel token through upload+poll into `AsrGenerationController` phases `uploading`/`polling` in `lib/features/asr/application/asr_generation_controller.dart`
- [x] T019 [US1] On completed job, reuse `buildAsrTranscriptLines` + `TranscriptRepository.upsertAsrGeneratedTrack` and set primary (existing paths) from controller
- [x] T020 [US1] Map surface status strings for uploading/polling via ARB in ASR presentation/launcher notices (`lib/features/asr/presentation/asr_generation_launcher.dart` and any status UI binding `AsrGenerationJob.phase`)
- [x] T021 [US1] Add `logNamed` instrumentation for job id, duration bucket, language mode, terminal outcome (no secrets) in Enjoy long-form path / controller
- [x] T022 [US1] Verify UI stays interactive during mocked multi-step poll (document manual check note for SC-006 in PR or quickstart)

**Checkpoint**: US1 independently testable with mocks; staging E2E when T008 is live

---

## Phase 4: User Story 2 - Keep short-clip Enjoy ASR working (Priority: P1)

**Goal**: Media under 15 minutes on Enjoy path stays on sync multipart Whisper without async job UX.

**Independent Test**: Duration 899 (or ~5 min fixture) → multipart path only; no upload/poll calls; AI track still works (SC-002).

### Tests for User Story 2

- [x] T023 [P] [US2] Unit test Enjoy path with `durationSeconds < 900` uses multipart `AsrApi.transcribe` only (no upload/submit) in `test/features/ai/data/enjoy/enjoy_asr_capability_test.dart` (extend existing)
- [x] T024 [P] [US2] Controller regression: short-clip phases remain `extracting`→`recognizing`→`persisting` (no `polling`) in `test/features/asr/application/asr_generation_controller_test.dart`

### Implementation for User Story 2

- [x] T025 [US2] Guard long-form branch so null/missing duration does not accidentally take JSON path; document default in `lib/features/ai/data/enjoy/enjoy_asr_capability.dart`
- [x] T026 [US2] Confirm short-clip error mapping unchanged in `lib/features/asr/application/asr_failure_messages.dart`

**Checkpoint**: Short-clip Enjoy unchanged and covered by regression tests

---

## Phase 5: User Story 3 - Safe retries, cancel, and failure recovery (Priority: P1)

**Goal**: Idempotent retries, cancel without torn writes, credits/failure UX, resume after restart.

**Independent Test**: Same attempt reuses idempotency key; cancel leaves prior transcript; 402 and retryable failures show actionable copy (SC-003, SC-005).

### Tests for User Story 3

- [x] T027 [P] [US3] Unit test idempotency key reuse on transport retry vs new key on fresh Generate in `test/features/asr/application/asr_long_form_idempotency_test.dart`
- [x] T028 [P] [US3] Unit test attempt store save/load/clear in `test/features/asr/data/asr_long_form_attempt_store_test.dart`
- [x] T029 [P] [US3] Controller test cancel during `polling` → `cancelled`, no persist; resume from stored `jobId` in `test/features/asr/application/asr_generation_controller_long_form_test.dart`
- [x] T030 [P] [US3] Failure mapping tests for `credits_exhausted`, `billing_exhausted`, `provider_timeout` (retryable), `unsupported_media` in `test/features/asr/application/asr_failure_messages_test.dart`

### Implementation for User Story 3

- [x] T031 [US3] Implement idempotency key lifecycle (create/store/reuse/rotate) in `AsrGenerationController` + `AsrLongFormAttemptStore`
- [x] T032 [US3] On app start / generate, reattach poll when non-terminal attempt exists for `mediaId` in `lib/features/asr/application/asr_generation_controller.dart`
- [x] T033 [US3] Cancel aborts HTTP upload/poll and marks attempt cancelled without overwriting AI track
- [x] T034 [US3] Extend `asr_failure_messages.dart` (+ ARB if needed) for long-form categories; wire credits-exhausted to existing upgrade path
- [x] T035 [US3] After terminal `failed` with `retryable: true`, next user Generate uses a **new** idempotency key (clear prior attempt)

**Checkpoint**: Retries/cancel/resume/failures independently testable

---

## Phase 6: User Story 4 - Language, credits preview, and BYOK (Priority: P2)

**Goal**: Language choice on long-form submit; 15-minute confirm; BYOK never hits Enjoy Deepgram jobs.

**Independent Test**: Explicit language on submit; confirm at 900s; BYOK long media skips upload/submit (SC-007).

### Tests for User Story 4

- [x] T036 [P] [US4] Unit/widget test long-media confirm threshold is 900s in `test/features/asr/application/asr_long_media_dialog_test.dart`
- [x] T037 [P] [US4] Unit test language omitted vs provided forwarded on JSON submit in `test/features/ai/data/enjoy/enjoy_asr_capability_long_form_test.dart`
- [x] T038 [P] [US4] Confirm BYOK capability still selected for long duration (no Enjoy long-form calls) in existing BYOK ASR tests under `test/features/ai/`

### Implementation for User Story 4

- [x] T039 [US4] Change `_kLongMediaThresholdSeconds` to `900` in `lib/features/asr/application/asr_long_media_dialog.dart` (use shared constant from T012)
- [x] T040 [US4] Pass selected/omitted language into long-form submit body from controller → Enjoy capability (`lib/features/asr/application/asr_generation_controller.dart`)
- [x] T041 [US4] Ensure `resolveAsrCapability` / BYOK path unchanged for long media in `lib/features/ai/application/ai_capability_providers.dart` (verify only; fix if any Enjoy fallback introduced)

**Checkpoint**: Language + 15m confirm + BYOK isolation done

---

## Phase 7: User Story 5 - Format parity with existing AI transcripts (Priority: P2)

**Goal**: Long-form results are first-class `TranscriptLine` tracks; re-generate upserts in place; lookup/echo/blur unaffected.

**Independent Test**: Completed long-form → timeline lines; re-generate same deterministic id; no duplicate AI rows (SC-004).

### Tests for User Story 5

- [x] T042 [P] [US5] Unit test mapper + `buildAsrTranscriptLines` integration produces multi-line timed cues (not one block / not one word per line) in `test/features/asr/domain/asr_long_form_mapper_test.dart`
- [x] T043 [P] [US5] Repository/controller test re-generate upserts same `source: ai` id in `test/features/transcript/transcript_repository_generate_asr_test.dart` or controller long-form test

### Implementation for User Story 5

- [x] T044 [US5] Tune mapper edge cases (root-level `words` only, empty text → no persist / no-speech error) in `lib/features/asr/domain/asr_long_form_mapper.dart`
- [x] T045 [US5] Confirm upsert + primary selection path identical to short-clip success in controller (no parallel persist API)

**Checkpoint**: Format parity covered; existing transcript features reuse AI track without special cases

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Docs, ADR, gates, staging validation

- [x] T046 [P] Update `docs/features/asr.md` — short Whisper vs ≥900s Deepgram job, upload prerequisite, remove stale Enjoy-Azure-continuous wording
- [x] T047 [P] Add ADR `docs/decisions/0058-enjoy-deepgram-long-form-asr.md` (or next free number) + link from `docs/decisions/README.md`
- [x] T048 Surface `usage.credits_charged` on success when cheap (existing credits notice pattern) — only if it fits without new UI surface; otherwise document deferral in ADR
- [x] T049 Run `dart run build_runner build` if Drift/Riverpod annotations changed; commit generated files
- [x] T050 Run `flutter analyze` and `flutter test` for ASR/AI suites; fix failures
- [x] T051 Run `bash .github/scripts/validate_ci_gates.sh --fix` before push
- [ ] T052 Execute [quickstart.md](./quickstart.md) staging E2E when T008 Worker upload is deployed; record results in PR

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies
- **Foundational (Phase 2)**: Depends on Setup — **BLOCKS** all user stories
  - T008 (Worker upload) blocks **staging E2E / release**, not mocked US1 unit work
- **US1 (Phase 3)**: After Foundational — MVP
- **US2 (Phase 4)**: After Foundational; can parallel with US1 once routing exists (prefer after T017)
- **US3 (Phase 5)**: Builds on US1 attempt/job plumbing
- **US4 (Phase 6)**: After US1 submit body exists; dialog can parallel earlier
- **US5 (Phase 7)**: After mapper (T016); mostly hardening
- **Polish (Phase 8)**: After desired stories complete

### User Story Dependencies

| Story | Depends on | Independently testable? |
|---|---|---|
| US1 Long-form Enjoy | Phase 2 | Yes (mocked HTTP) |
| US2 Short-clip | Phase 2 + Enjoy branch | Yes (regression) |
| US3 Retries/cancel | US1 attempt + poll | Yes |
| US4 Language/BYOK/confirm | US1 submit fields | Yes |
| US5 Format parity | US1 mapper + upsert | Yes |

### Parallel Opportunities

- T004, T005, T007, T009, T012 in Phase 2 once T001–T003 done
- T013–T015 tests in parallel before/with T016–T017
- T023–T024 (US2) parallel with US3 tests after T017
- T036 dialog test parallel anytime after T012 constant exists
- T046–T047 docs parallel with code polish

---

## Parallel Example: User Story 1

```bash
# Tests in parallel:
Task: "Unit test AsrLongFormMapper in test/features/asr/domain/asr_long_form_mapper_test.dart"
Task: "Unit test Enjoy long-form routing in test/features/ai/data/enjoy/enjoy_asr_capability_long_form_test.dart"
Task: "Controller happy path in test/features/asr/application/asr_generation_controller_long_form_test.dart"

# Then implementation sequence:
Task: "Implement mapper → EnjoyAsrCapability long-form → controller phases → UI status"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1 + Phase 2 (mock upload if Worker T008 not ready)
2. Complete Phase 3 US1
3. **STOP and VALIDATE** with unit tests + mocked poll
4. Demo; do not release to production until T008 + T052 pass

### Incremental Delivery

1. Setup + Foundational → clients + DTOs ready  
2. US1 → long-form MVP  
3. US2 → short-clip safety  
4. US3 → idempotency / cancel / resume  
5. US4 → language + 15m confirm + BYOK check  
6. US5 → mapper polish  
7. Polish → docs, ADR, CI gates, staging E2E  

### Parallel Team Strategy

- Dev A: Flutter foundational + US1  
- Dev B: Worker T008 upload in enjoy monorepo  
- After T017: Dev C can take US3 while A does US4/US5  

---

## Notes

- [P] = different files, no incomplete-task dependency
- Do not call Worker HTTP from widgets
- Prefer uploading **extracted** audio for video sources
- `media_reference` is an opaque suffix under `media/{userId}/`, never a double-prefixed path
- Commit after each task or logical group
- Avoid shipping Flutter long-form without Worker upload in the target environment
