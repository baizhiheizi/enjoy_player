---
network:
  allowed:
    - dart

pre-agent-steps:
  - name: Ensure Linux tooling
    run: bash .github/scripts/ensure_linux_tooling.sh

  - name: Setup Flutter
    uses: ./.github/actions/setup-flutter

  - name: Flutter pub get
    run: flutter pub get

  - name: Verify Flutter toolchain
    run: flutter --version && dart --version
---

## Flutter / Dart toolchain

This repository is a **Flutter** app (native desktop/mobile only — **no web**). The SDK version is pinned in [`.github/flutter-version`](../../flutter-version). Pre-agent steps install the same toolchain as [CI](../../workflows/ci.yml).

### Verification commands (match CI)

After making code changes, run the shared gate script (preferred):

```bash
flutter pub get
bash .github/scripts/validate_ci_gates.sh          # format + codegen drift
# bash .github/scripts/validate_ci_gates.sh --fix  # write format + regenerate
# bash .github/scripts/validate_ci_gates.sh --all   # + analyze + test
```

Or the individual CI-equivalent commands:

```bash
bash .github/scripts/check_dart_format.sh
bash .github/scripts/check_codegen_drift.sh   # after Drift / Riverpod / Freezed edits (or always before push)
flutter analyze
flutter test
# Path packages: (cd packages/<name> && flutter pub get && flutter test)
```

Always regenerate and commit codegen after editing `@DriftDatabase`, `@DriftAccessor`, `@Riverpod`, or Freezed annotations — a stale `*.g.dart` hash fails the Codegen drift workflow.

### Agent rules

Read [`AGENTS.md`](../../../AGENTS.md) before editing. In particular:

- Use Riverpod (`ConsumerWidget` / `ConsumerStatefulWidget`); no `print()` — use `logNamed`
- Never construct `media_kit` `Player()` outside `PlayerController`
- Do not add Flutter web targets or `kIsWeb` branches

### Scope on the agentic runner

Agentic workflows run on **Linux** only (AWF sandbox). Use analyze/test/format here — not iOS, macOS, Windows, or Android release builds.
