# Quickstart: Profile Update Form

**Feature**: [spec.md](./spec.md) · **Plan**: [plan.md](./plan.md)

Validation guide. Contracts: [profile-api.md](./contracts/profile-api.md), [profile-edit-ui.md](./contracts/profile-edit-ui.md).

## Prerequisites

- Signed-in Enjoy Player build against an enjoy_web with #227 (avatar + `mixin_id`).
- Account where Enjoy ID and email differ.

## Automated checks

```bash
flutter analyze
flutter test test/features/auth/
bash .github/scripts/validate_ci_gates.sh --fix
```

## Manual

1. Profile tab → hero secondary line is Enjoy ID, not email.
2. Open Edit profile (hero or row) → change username → Save → hero updates.
3. Preferences → no username field; goal/languages still save.
4. Edit profile → pick JPEG/PNG/WebP ≤2MB → Save → hero + sidebar show new avatar.
5. Oversized/unsupported file → error; prior avatar kept.
6. Mixin linked → Mixin ID shown read-only; otherwise “not linked”.

## Docs

- [docs/features/auth.md](../../docs/features/auth.md)
