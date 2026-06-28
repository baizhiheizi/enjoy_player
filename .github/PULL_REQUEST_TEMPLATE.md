## Summary

<!-- One paragraph: what does this PR change and why? Reference the issue(s) it closes. -->

Fixes #

## Type of change

- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to change)
- [ ] Refactor / chore (no user-visible change)
- [ ] Documentation / ADR

## Platform tested

- [ ] Android
- [ ] iOS
- [ ] macOS
- [ ] Windows
- [ ] Linux

## Checklist

- [ ] `flutter analyze` is clean
- [ ] `flutter test` passes for affected areas
- [ ] No new `print()` calls (use `logNamed` from `lib/core/logging/log.dart`)
- [ ] No new `kIsWeb` branches (AGENTS.md hard rule)
- [ ] No new SQL outside Drift DAOs (AGENTS.md hard rule)
- [ ] No new `Player()` instances outside `PlayerController` (AGENTS.md hard rule)
- [ ] If behavior changed: `docs/features/<feature>.md` updated
- [ ] If architectural: new ADR in `docs/decisions/`
- [ ] New public API symbols have doc comments (if applicable)

## Test plan

<!-- How was this verified? List specific scenarios, commands, and platforms. -->

- [ ] ...
- [ ] ...

## Out of scope / follow-up

<!-- Anything intentionally deferred; link to follow-up issues. -->

- ...

## Human / owner follow-up

<!-- Any actions that require the repo owner (credential rotation, third-party sign-off,
     schema decisions). Do NOT silently perform these — flag them here. -->

- None / ...
