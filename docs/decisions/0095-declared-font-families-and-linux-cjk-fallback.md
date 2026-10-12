# ADR-0095: Declared font families and a sans-first Linux CJK fallback

**Status**: Accepted (2026-10-12)

## Context

Desktop player screenshots on Linux showed three typography defects:

1. **Weights did not change.** The theme built its styles with `google_fonts` (`GoogleFonts.geistTextTheme`, `GoogleFonts.literataTextTheme`, …). `google_fonts` resolves a weight *once*, at style creation, into a per-variant family name such as `Geist_500`, and registers only that face. Every later `style.copyWith(fontWeight: …)`, the idiom used at ~135 call sites, kept the original face. So `w600` labels rendered Geist Medium, and the active transcript line (`w500` over a Literata Regular style) rendered Regular.
2. **Chinese UI text rendered in a serif face** wherever the weight was 600: segmented-control labels, Echo loop pills and the loop caption. A probe app on the same machine showed that the Linux engine never applies `fontFamilyFallback` system-family names such as `Noto Sans CJK SC`. CJK glyphs instead come from fontconfig's per-character fallback, which ranks candidates by weight. Noto Sans CJK has no 600 face, so `Noto Serif CJK SemiBold` won. With a bundled primary font, even weight 400 could land on serif.
3. Transcript layout drift from the `Main` board (gutter timestamp above the text baseline, IPA centred under words). These were fixed in the widgets and are not part of this decision.

## Decision

1. **Declare the bundled text faces as real multi-weight families** in `pubspec.yaml`: `Geist` (400/500/600), `GeistMono` (500/600), `Literata` (400/500/600) and `NotoSans` (400), using the files already in `assets/fonts/google_fonts/`. `lib/core/theme/typography.dart` addresses them by name (`kGeistFamily`, `kGeistMonoFamily`, `kLiterataFamily`, `kNotoSansFamily`) instead of through `google_fonts`. As a result, `fontWeight` selects the matching face everywhere. The fonts (~1.4 MB) load from the font manifest at startup, so there is still no runtime fetch and no first-frame FOUT.
2. **Linux runner sets `FONTCONFIG_FILE`** to the bundled `data/fontconfig/fonts.conf` (source: `linux/runner/fontconfig/fonts.conf`). This file includes `/etc/fonts/fonts.conf` and appends `Noto Sans CJK SC`, `Source Han Sans SC` and `WenQuanYi Micro Hei` as strong family matches, so fontconfig's per-character fallback picks a CJK sans face at every weight. `main.cc` skips this when `FONTCONFIG_FILE` is already set, when the system config is missing, or when the bundled file is absent. The engine builds its own fontconfig instance with `FcInitLoadConfigAndFonts`, so the environment variable is the supported hook. Rules added to the process's current config at runtime would be ignored.

## Consequences

- `w500` / `w600` render as designed across the app. Latin glyph widths shift slightly, and some tight fixed-height layouts surfaced. The Craft capture idle stage now scrolls instead of overflowing on short windows.
- `flutter test` loads the declared families from the font manifest, so widget tests lay out with real Geist / Literata metrics.
- `google_fonts` remains for `allowRuntimeFetching = false` and the share poster's explicit-weight Literata styles. The CJK name-only fallback rules in [app-ui.md § Font delivery](../features/app-ui.md) still hold for macOS / Windows / mobile.
- On Linux, CJK in the transcript body is now sans as well. The serif CJK fallback names were never honoured there, so serif CJK only ever appeared by accident of weight.
- Child processes the app launches inherit `FONTCONFIG_FILE`. Because the file includes the system configuration, they only see the extra CJK sans preference.

## Alternatives considered

- **Re-create each weighted style through `GoogleFonts.*(fontWeight: …)`**: this would touch every `copyWith(fontWeight:)` call site and needs a lint to keep new sites honest. Rejected.
- **Bundle a CJK sans with a 600 face** (Noto Sans SC variable, ~10 MB+): this fixes Linux only by growing every platform's bundle. Rejected.
- **Avoid weight 600 wherever CJK can appear**: this contradicts the Duet type scale and can't be enforced. Rejected.
- **Edit the user's fontconfig**: this fixes one machine, not the shipped app. Rejected.
