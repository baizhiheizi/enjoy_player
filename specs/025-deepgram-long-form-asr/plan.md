# Implementation Plan: Deepgram Long-Form ASR (Flutter Client)

**Branch**: `025-deepgram-long-form-asr` | **Date**: 2026-07-19 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/025-deepgram-long-form-asr/spec.md`

**Note**: Plan template filled by `/speckit-plan`. Design details: [research.md](research.md), [data-model.md](data-model.md), [contracts/](contracts/), [quickstart.md](quickstart.md).

## Summary

Adopt the Enjoy Worker’s Deepgram **long-form** transcription API on the Flutter Enjoy ASR path for local media **≥ 15 minutes**: upload recognition audio to Worker storage, submit a JSON job with an idempotency key, poll until terminal, map the timestamped transcript into the existing `source: ai` pipeline. Keep **short-clip** Enjoy ASR on sync multipart Whisper. BYOK is unchanged.

**Blocker**: Worker media-upload HTTP API is not implemented yet; Flutter implements against [contracts/media-upload.md](contracts/media-upload.md) and cannot ship product E2E until that route lands in the enjoy Worker.

## Technical Context

**Language/Version**: Dart / Flutter stable as pinned by this repo (analyze + test gates).

**Primary Dependencies** (existing):
- `flutter_riverpod` / `riverpod_annotation` — `AsrGenerationController`
- `http` via project `ApiClient` / `RestApi` — Worker calls
- `drift` — transcript upsert; optional small table for in-flight long-form attempts
- FFmpeg extraction stack already used by `AsrAudioExtractor`
- `uuid` — idempotency keys / media_reference suffixes
- Localization ARB files

**Storage**: Drift `AppDatabase` for AI transcript rows (+ optional `asr_long_form_attempts`); temp files for extraction (existing); no Deepgram secrets on device.

**Testing**: `flutter test` (unit/widget), `flutter analyze`, `bash .github/scripts/validate_ci_gates.sh` before push; `dart run build_runner build` if Riverpod/Drift annotations change.

**Target Platform**: Android, iOS, macOS, Windows, Linux. **No Flutter web.**

**Project Type**: Flutter native mobile/desktop app.

**Performance Goals**:
- Upload + poll must not freeze UI; playback remains usable during multi-minute jobs (SC-006).
- Prefer uploading extracted audio (existing size guard) over full video containers.
- Poll backoff 2s → max 30s per Worker client guidance.

**Constraints**:
- No Worker HTTP from widgets; route through `AsrService` / `EnjoyAsrCapability` / `AsrApi`.
- No Deepgram API key in the app.
- No `print()`; use `logNamed`.
- No new `media_kit` `Player()`.
- Cross-repo: upload API must exist on Worker for real E2E.

**Scale/Scope**:
- Extend `lib/features/asr` + `lib/features/ai/data/enjoy` + `lib/data/api/services/ai`.
- Docs: `docs/features/asr.md` + new ADR.
- Worker upload implementation tracked as dependency (enjoy monorepo), not duplicated here.

## Constitution Check

*GATE: Pre-Phase 0 — PASS. Post-Phase 1 design — PASS (re-checked).*

### I. Architecture and Code Quality

- Changes stay in `lib/features/asr/{application,data,domain,presentation}`, `lib/features/ai/…`, and `lib/data/api/services/ai/`. **Pass.**
- Domain DTOs / mappers remain UI-free; Drift only via DAOs/repositories. **Pass.**
- Riverpod controller owns job state; no new global mutable singleton. **Pass.**
- Logging via `logNamed`; no `media_kit` Player construction. **Pass.**

### II. Testing Defines the Contract

- Unit tests: routing, idempotency lifecycle, job→`AsrResult` mapper, failure mapping, controller cancel/resume (mocked HTTP).
- Regression: existing Enjoy short-clip + BYOK ASR tests.
- Widget/dialog: confirm threshold at 900s if UI covered.
- `build_runner` when annotations/schema change.
- Manual staging E2E when Worker upload is available ([quickstart.md](quickstart.md)).

### III. User Experience Consistency

- New strings in ARB (`app_en.arb` / `app_zh_CN.arb`).
- Reuse existing ASR progress / notice / credits-exhausted patterns.
- Update `docs/features/asr.md`.

### IV. Performance Is a Requirement

- Budgets in Technical Context + research § 9; heavy I/O off UI isolate where already practiced for extraction; cancel-aware upload/poll.

### V. Documentation and Traceability

- Feature doc update required.
- ADR for Enjoy long-form Deepgram job adoption + upload dependency.
- No constitution exceptions.

## Project Structure

### Documentation (this feature)

```text
specs/025-deepgram-long-form-asr/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── worker-long-form-api.md
│   ├── media-upload.md
│   └── enjoy-asr-capability.md
├── checklists/requirements.md
└── tasks.md             # /speckit-tasks — not created here
```

### Source Code (repository root)

```text
lib/
├── data/api/services/ai/
│   ├── asr_api.dart                    # + submitLongForm, getTranscriptionJob
│   └── asr_media_upload_api.dart       # NEW — PUT/POST media (contract)
├── features/ai/
│   ├── data/enjoy/enjoy_asr_capability.dart  # short vs long branch
│   └── domain/models/                  # optional long-form DTOs / exceptions
├── features/asr/
│   ├── application/
│   │   ├── asr_generation_controller.dart    # phases uploading/polling, resume
│   │   ├── asr_generation_job.dart           # new phases
│   │   ├── asr_long_media_dialog.dart        # 900s threshold
│   │   └── asr_failure_messages.dart         # long-form categories
│   ├── data/
│   │   └── asr_long_form_attempt_store.dart  # NEW — persist in-flight attempt
│   └── domain/
│       └── asr_long_form_mapper.dart         # NEW — job transcript → AsrResult
└── data/db/…                           # optional Drift table for attempts

test/features/asr/…
test/features/ai/data/enjoy/…

docs/
├── features/asr.md
└── decisions/00XX-enjoy-deepgram-long-form-asr.md
```

**Structure Decision**: Extend the existing ASR feature and Enjoy capability rather than a parallel feature folder. HTTP stays under `lib/data/api/services/ai`. Mapper/store live under `lib/features/asr` so transcript orchestration remains cohesive.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Cross-repo Worker upload dependency | Long-form submit requires R2 object under user namespace; no Flutter-only workaround | Multipart Whisper for long files breaks Worker contract and scale |

## Phase 0 / Phase 1 outputs

| Artifact | Path |
|---|---|
| Research | [research.md](research.md) |
| Data model | [data-model.md](data-model.md) |
| Contracts | [contracts/](contracts/) |
| Quickstart | [quickstart.md](quickstart.md) |

**Agent context update**: No `update-agent-context` script is present under `.specify/scripts` in this repo; skipped.

## Next

Run `/speckit-tasks` to break implementation into ordered tasks (Worker upload coordination first, then Flutter client).
