# Quickstart: Craft History & First-Class Entry

**Feature**: 029-craft-history-home  
**Contracts**: [contracts/README.md](./contracts/README.md) · **Model**: [data-model.md](./data-model.md)

## Prerequisites

- Flutter SDK per repo README
- Signed-in app session with AI/TTS available for Craft generate/save (existing Craft requirements)
- Desktop recommended for hotkey checks (Windows/macOS/Linux)

## Setup

```bash
flutter pub get
# After @Riverpod / Drift annotation changes:
dart run build_runner build
flutter gen-l10n
```

## Automated checks (implementation phase)

```bash
flutter analyze
flutter test test/features/craft test/features/library test/features/hotkeys
bash .github/scripts/validate_ci_gates.sh --fix
```

Expected: analyze clean; new/updated tests for Home Craft CTA, `global.craft` definition, history filter, `loadForEdit`, `updateCraftedFromText` same-id save.

## Manual scenarios

### M1 — Home Craft (US1 / FR-001)

1. Open Home.
2. Confirm header shows **Craft** beside **Import**.
3. Tap Craft → Craft Studio opens (no import sheet).
4. Back → Import still opens the chooser; Craft row still present.

### M2 — Hotkey `c` (US2 / FR-003–005)

1. Focus Home (no text field).
2. Press `c` → Craft opens in &lt;1s.
3. Press `c` again on Craft → stay on Craft (no duplicate stack).
4. Focus a text field on any screen, press `c` → types `c`, does not navigate.
5. Open keyboard shortcuts help → Craft listed with default `c`.

### M3 — History list (US3 / FR-006–008, FR-013)

1. With ≥2 Craft library items and ≥1 non-Craft item, open Craft → History.
2. List shows only Craft items, newest first, recognizable labels.
3. Delete all Craft items (or use empty profile) → empty state + path back to create.

### M4 — Edit & update same item (US4 / FR-009–012)

1. Note title/text of one Craft item; open it from history.
2. Confirm target text prefilled; change a word; regenerate audio; save.
3. History / library still shows **one** item for that content lineage (same id); practice plays updated audio.
4. `updatedAt` / ordering moves the item toward the top.

### M5 — ZH branding (US5 / FR-014)

1. Set UI language to Chinese.
2. Home Craft, Craft title, library Craft badge, Import Craft row all show **Craft** (Latin).
3. Confirm **自制** does not appear on those surfaces.

## Acceptance mapping

| Spec | Quickstart |
|------|------------|
| SC-001 | M1 |
| SC-002 | M2 |
| SC-003 | M3 + M4 step 1 |
| SC-004 | M4 |
| SC-005 | M5 |
| SC-006 | Informal Home findability check |
