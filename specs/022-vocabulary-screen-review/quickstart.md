# Quickstart: Vocabulary Screen & Review

**Feature**: [spec.md](./spec.md) · **Plan**: [plan.md](./plan.md)

Validation guide after `/speckit-tasks` / implementation. Contracts and data-model own invariants; this is the runbook.

## Prerequisites

- Foundation (021) green: lookup **Add to Vocabulary** works; Drift schema 15 present.
- Signed-in Enjoy Player build with at least a few saved vocabulary items (mix of statuses/languages if possible). Seed via lookup during playback or repository fixtures in tests.
- Dev tree: `bash .github/scripts/validate_ci_gates.sh` baseline green before starting.

## Automated checks

```bash
dart run build_runner build   # if new @Riverpod providers
flutter analyze
flutter test test/features/vocabulary/
bash .github/scripts/validate_ci_gates.sh --fix
```

Expected:

- Stats aggregation + due count match seeded items.
- Session queue: due / all / status / language / random N; empty queue rejected; Fisher–Yates with seeded `Random` is deterministic.
- Review notifier: flip → rate updates SRS; skip no write; undo restores; in-flight blocks double rate.
- Widget: Vocabulary screen stats/tabs/empty states; All Words filter/search/delete; review options → session chrome.
- Foundation SRS/undo tests still pass.

## Manual — open Vocabulary & stats

1. Save 2+ words from transcript lookup (foundation path).
2. Profile → Vocabulary entry → `/vocabulary`.
3. Confirm stats strip: total / due / status breakdown look right.
4. Switch **Review** ↔ **All Words**.

## Manual — review session

1. Review tab → open options → **Due** (or **All** if none due) → start.
2. Confirm progress `1 / N`, word + context preview on front.
3. Flip → rate Don’t Know / Know / Know Well on different cards; confirm advance.
4. Skip one card; confirm it did not change that item’s SRS (spot-check via list next-review or re-open).
5. Rate one card then **Undo**; confirm card returns and SRS restored.
6. Finish queue → complete state → back to Vocabulary; stats updated.
7. Exit mid-session via back/Esc; prior ratings remain.

## Manual — desktop shortcuts

On macOS / Windows / Linux desktop:

1. Start a session; focus review surface.
2. Space flips; `1`/`2`/`3` rate on back; → skips; ← previous; Esc exits.
3. Mash rate key during a slow device — only one rating applies.

## Manual — All Words manage

1. Apply status and language filters; type search; confirm list narrows.
2. Delete one word → confirm → gone from list; stats total decrements.
3. Cancel delete → item remains.
4. Empty filters with zero matches → “no matches” (not empty-book copy).

## Manual — empty states

1. On a profile with zero vocabulary (or after deleting all): empty-book copy; no crash.
2. With words but none due: no-due copy on Review; custom options still start a session.

## Docs to update in the same PR

- [docs/features/vocabulary.md](../../docs/features/vocabulary.md) — mark P1 checklist items; status line.
- [docs/decisions/0053-vocabulary-secondary-route.md](../../docs/decisions/0053-vocabulary-secondary-route.md) — new.
- [docs/decisions/README.md](../../docs/decisions/README.md) — index ADR-0053.

## Out of scope smoke (do not require)

- Clip playback / open in player / shadow from review.
- AI dictionary fetch on Dictionary tab.
- Anki export / Pro gate.
- Cloud sync / multi-device.
- Home due widget.
