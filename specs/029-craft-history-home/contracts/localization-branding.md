# C3. Localization & Craft branding

**Date**: 2026-07-23 | **Feature**: 029-craft-history-home

## Product-name surfaces (MUST use Latin Craft in ZH)

| Key | EN | ZH (target) | Notes |
|-----|----|-------------|-------|
| `craftScreenTitle` | Craft | Craft | Retire 自制 |
| `libraryProviderCraftBadge` | Craft | Craft | Retire 自制 |
| `importCraftFromText` | Craft… | Craft… | Short Import row; retire 从文本自制… |
| `homeCraftAction` **(NEW)** | Craft | Craft | Home trailing button — do not reuse `craftAction` |

## New UX strings (suggested keys)

| Key | EN (suggested) | ZH (suggested) |
|-----|----------------|----------------|
| `homeCraftAction` | Craft | Craft |
| `craftHistoryTooltip` | History | 历史 |
| `craftHistoryTitle` | Craft history | Craft 历史 |
| `craftHistoryEmptyTitle` | No Craft items yet | 还没有 Craft |
| `craftHistoryEmptyHint` | Create audio in Craft and it will show up here. | 在 Craft 里创建音频后会显示在这里。 |
| `craftHistoryEmptyAction` | Start crafting | 开始创建 |
| `craftEditUnavailable` | This Craft item is no longer available. | 该 Craft 已不存在。 |
| `hotkeysDescCraft` | Open Craft | 打开 Craft |

Exact wording may be tightened during implementation; ZH product noun remains Latin **Craft**.

## Do not blindly overwrite

| Key | Current ZH | Keep? |
|-----|------------|-------|
| `craftAction` | 合成 | **Keep** as synthesize *verb* unless UI copy is clearly the product name |

## Audit

After ARB updates, grep ARBs and generated l10n for `自制` on Craft product surfaces; zero hits for title/badge/import/home Craft labels (SC-005).
