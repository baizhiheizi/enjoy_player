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

After making code changes, run:

```bash
flutter pub get
dart format --output=none --set-exit-if-changed lib test
# Include packages/*/lib and packages/*/test when present
flutter analyze
flutter test
# Path packages: (cd packages/<name> && flutter pub get && flutter test)
```

Run `dart run build_runner build` only after editing `@DriftDatabase`, `@DriftAccessor`, or `@Riverpod` annotations.

### Agent rules

Read [`AGENTS.md`](../../../AGENTS.md) before editing. In particular:

- Use Riverpod (`ConsumerWidget` / `ConsumerStatefulWidget`); no `print()` — use `logNamed`
- Never construct `media_kit` `Player()` outside `PlayerController`
- Do not add Flutter web targets or `kIsWeb` branches

### Scope on the agentic runner

Agentic workflows run on **Linux** only (AWF sandbox). Use analyze/test/format here — not iOS, macOS, Windows, or Android release builds.
