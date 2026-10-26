# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- **The landing page deploys through Cloudflare Pages' Git integration only**: `player.enjoy.bot` is served by the Pages project `enjoy-player`, which builds `landing/` from `main` on Cloudflare's side. `.github/workflows/deploy_landing.yml` targeted a project that does not exist (`enjoy-player-landing`) with an invalid token and had never completed a deploy, so it is removed; `landing/wrangler.toml` now names the real project. See [docs/features/landing.md § Deployment](docs/features/landing.md#deployment--cloudflare-pages-git-integration).

## [0.10.1] - 2026-10-23

### Fixed

- **YouTube playback works again on macOS, Windows, iOS, and Android** ([#1038](https://github.com/baizhiheizi/enjoy_player/pull/1038)): v0.10.0 shipped a regression from #972 — the Linux-only frame-stall probe's platform predicate was wired into the WebView **host mount** gate, so the `InAppWebView` never mounted on any platform but Linux. `onWebViewCreated` never fired, the JS channel stayed null, and every play command short-circuited with "youtube play ignored without WebView" (issue #1033). The mount gate is back to availability + mount request, and the probe's platform support now gates the probe alone via an early return, so the Linux-only sampling scope and the 900 ms → 15 s backoff cadence from #972 are unchanged. A new test asserts the host mounts on every playable platform and that the probe starts on Linux only. See [docs/features/youtube.md](docs/features/youtube.md).
- **The relative-day label stays correct across a DST transition** ([#1015](https://github.com/baizhiheizi/enjoy_player/pull/1015)): `relativeDayLabel` measured the gap between two *local* midnights and truncated it to whole days, but on a spring-forward day the two local midnights are only 23 hours apart — `inDays` returned 0, so the previous calendar day rendered as "today" instead of "yesterday". The day count is now measured between UTC midnights, which are always exactly 24 hours apart whatever the local offset is. Time of day is still ignored, future timestamps still fall through to the short-date format, and everything more than a day back is unchanged. See [docs/features/library.md](docs/features/library.md).
- **macOS direct-download builds can use secure storage again** ([#1048](https://github.com/baizhiheizi/enjoy_player/pull/1048)): the Developer ID build signs without a `keychain-access-groups` entitlement, so the macOS **data-protection** keychain — which `ByokSecretStore` used by default — failed every read, write, and delete with `-34018` (`errSecMissingEntitlement`), and a BYOK API key could not be saved at all. Every macOS build now stores its secrets in the legacy keychain through one shared backend, and a delete that reports a missing entitlement is treated as "already absent" instead of the false "secure storage delete failed" warning the cold-start profile cleanup logged on every launch. The issue's proposed fix — adding a keychain access group to the direct build — was measured and rejected: AMFI kills a Developer ID build that carries one (`-413 "No matching profile found"`, launch error 163). See [ADR-0100](docs/decisions/0100-macos-direct-download-keychain.md).
- **Closing a screen mid-action no longer throws a disposed-`WidgetRef` error** ([#1046](https://github.com/baizhiheizi/enjoy_player/pull/1046)): several actions read Riverpod providers *after* an `await`, so closing the screen while a Discover subscribe, a media-language save, a library import, a cloud-library add, or a craft recording was in flight produced `Bad state: Using "ref" when a widget is about to or has been unmounted is unsafe` — the saved row was reported as failed, the library list kept stale data, and the capture was left in a bogus state. Every provider read that used to happen after an await now happens before it, and the provider side effects that must survive the screen closing run through the captured container.
- **Media files whose name contains an apostrophe or a double quote work again on Android, iOS, and macOS** ([#1062](https://github.com/baizhiheizi/enjoy_player/pull/1062)): every FFmpegKit invocation built its command as one shell-style string and escaped the paths with a helper that only quoted on a space or a double quote. FFmpegKit parses that string with its own rules — a single quote opens a quoted section, and a backslash before a double quote is kept verbatim — so a path like `/media/Don't.mp3` reached FFmpeg as `/media/Dont.mp3` with the rest of the command swallowed into the input argument, and the extraction failed silently on exactly the platforms that use FFmpegKit while the Windows/Linux CLI path (which passes an argument list) was unaffected. Every FFmpegKit call now hands the library the same argument list the CLI branch runs, so the two backends receive identical arguments and no escaping is involved. This affects ASR audio extraction, Azure assessment WAV normalization, Echo segment PCM extraction, the Echo loop clip export, and video poster extraction. See [docs/features/asr.md](docs/features/asr.md) and [docs/features/echo-mode.md](docs/features/echo-mode.md).

### Changed

- **The duplicate RIFF/WAVE readers and the duplicated library chrome collapse into one shared implementation** ([#1062](https://github.com/baizhiheizi/enjoy_player/pull/1062)) (no user-visible change): the three hand-rolled RIFF chunk walkers (signal-peak scan, duration, 16 kHz PCM decode) become one `readWavChunks` reader in `core/audio`, the local library shares one empty / search / scroll chrome between its audio list and its video grid, and the cloud catalog shares one infinite-scroll lifecycle and empty-state shell between its list and its grid. Grid sizing and insets are unchanged. One deliberate behavior change rides along: the `fmt ` chunk minimum is now 16 bytes (the duration parser previously accepted 14), so a take recorded with a shorter `fmt ` chunk no longer reports a duration. See [docs/features/shadow-reading.md](docs/features/shadow-reading.md).
- **Data, sync, dictionary, and release internals split into focused modules** (no user-visible change): `media_registry.dart` split into mapping / reads / streams / writes part files with the public API and import path unchanged, the videos and audios DAOs share one single-row write path, the sync upload service shares one entity-upload recovery path, the dictionary sense renderer is shared between lookup and flashcards, `sync_queue_job.dart` split into per-variant part files, and the release scripts share one `release_publish_to_s3` contract plus one Sparkle appcast item emitter. See [docs/features/library.md](docs/features/library.md), [docs/features/sync.md](docs/features/sync.md), [docs/features/dictionary-lookup.md](docs/features/dictionary-lookup.md), and [docs/features/vocabulary.md](docs/features/vocabulary.md).
- **`activeEchoForTranscript` and the auth platform assertions are covered directly** ([#1013](https://github.com/baizhiheizi/enjoy_player/pull/1013)): the pure helper with four call sites gained a focused test pinning the null cases, the index clamping at both ends, and the fast path; the split auth platform assertions are consolidated into the canonical `test/features/auth/domain/auth_platform_support_test.dart` named by `specs/014-linux-platform-support`, with the macOS case split by distribution channel and the Linux case flag-driven.
- **The repo-assist agent prompt reads the Flutter version from one place** ([#1014](https://github.com/baizhiheizi/enjoy_player/pull/1014)): the prompt hardcoded `Flutter 3.44.0` while `mise.toml` pins `3.47.6`, so the number lived in two places and would go stale on the next bump; the prompt now points at the single source of truth.

### Documentation

- **The 2026-10-21 docs-drift review findings are resolved** ([#1023](https://github.com/baizhiheizi/enjoy_player/pull/1023)): every claim re-verified against the tree — the IPA gate's `com.apple.dt.runtime.swiftCompatibilitySpan` exemption is now named in [docs/packaging.md](docs/packaging.md), the macOS minimum target is lifted to 12.0 to match the Podfile and the Xcode project, the release-workflow trigger rows in [docs/ci-self-hosted-runners.md](docs/ci-self-hosted-runners.md) now show that the four platform workflows do trigger on `v*.*.*` tag pushes (that is how v0.10.0 shipped), the Duet `STATUS.md` D5.1 row no longer claims #884 removed `lerp` (still mandatory under the `ThemeExtension` contract), and the echo-mode takes-list section describes the panel that actually ships.

## [0.10.0] - 2026-10-20

### Added

- **The landing page deploys from CI again** — `.github/workflows/deploy_landing.yml` was documented in [docs/features/landing.md](docs/features/landing.md) and [docs/packaging.md](docs/packaging.md) but had never existed (issue #1001), so no change under `landing/**` ever reached `player.enjoy.bot` and edits had to be deployed by hand. The workflow deploys `landing/` to the `enjoy-player-landing` Cloudflare Pages project on pushes to `main`, publishes a `pr-<number>` preview deployment for pull requests (commented on the PR), and can be triggered manually. It uses the existing `CLOUDFLARE_API_TOKEN` / `CLOUDFLARE_ACCOUNT_ID` secrets.

- **Linux YouTube playback via WPE WebKit (spec 047)** ([#847](https://github.com/baizhiheizi/enjoy_player/pull/847)): Linux builds now mount YouTube through a shared WPE `WebViewEnvironment` next to the Windows WebView2 precedent, behind a one-per-process runtime availability probe (5 s bound) with a kill-switch const. The platform switch consults the resolved decision at every player open, so non-Linux targets keep the synchronous behavior. When the runtime is unavailable, the player shows a localized notice with an "open in browser" fallback carrying the canonical watch URL, and the sign-in screen hides the in-app option. Hardware-accelerated decode is software-GL by default; WPE 2.48/2.52 hardware-frame paths are documented as a known caveat. See [ADR-0091](docs/decisions/0091-youtube-linux-playback.md), [ADR-0092](docs/decisions/0092-linux-youtube-host-runtime.md), and [docs/features/youtube.md](docs/features/youtube.md).
- **Norwegian Bokmål (nb-NO) as a learning language** ([#788](https://github.com/baizhiheizi/enjoy_player/pull/788)): Norwegian Bokmål is now selectable as the learning (profile focus), media, and lookup language — the lookup catalog grows from 14 to 15 languages — with dictionary lookup, word-timing forced alignment (vendored eSpeak-NG voice + dictionary), and pronunciation assessment all working for Norwegian. The `no` / `nob` / `nor` tags alias to `nb` as deliberate macrolanguage policy — essentially all Norwegian content in the wild is Bokmål — while genuine Nynorsk (`nn`) stays unsupported rather than being silently reclassified. Known gap: Craft's Azure voice picker has no Norwegian voice yet (it shows the standard "no voices for this language" state; pronunciation assessment is fully supported). See [ADR-0087](docs/decisions/0087-norwegian-bokmal-language-catalog.md) and [docs/features/dictionary-lookup.md](docs/features/dictionary-lookup.md).
- **Duet v30 player chrome and dock** ([#924](https://github.com/baizhiheizi/enjoy_player/pull/924), [#926](https://github.com/baizhiheizi/enjoy_player/pull/926)): the top bar carries Share and Subtitles as 36 px outlined chips plus a desktop-only "More" menu that gathers every existing transcript action (add a subtitle file, embedded subtitles, AI transcript / transcribe again, word timings & IPA, refresh from cloud) into one `watchTranscriptActions` list shared with the phone Subtitles sheet, so nothing becomes unreachable on phones. The redesigned Subtitles & display panel is sized to its content (384 px, was full window height) with flat rows — Primary/Translation lists, a Book / Clean transcript typeface (new `transcript.cleanTypeface` device flag), highlight-spoken-word and IPA-under-words switches, and a progress/retry card while word timings generate (the Hide-text switch left the panel; `H` and the dock still toggle it). The dock gains a two-line `DockReadout` with per-lens copy ("Line 6 of 14 · 3 lines practised", "Looping line 6 · 3.8s"), a Repeat button after Next on desktop Listen cycling `none` ↔ `single` (one tap clears the Echo-loop `segment` mode), and a 54 px mono speed button. See [docs/features/player.md](docs/features/player.md) and [docs/features/transcript.md](docs/features/transcript.md).
- **Dictate lens — Listen · Echo · Dictate are exclusive** ([#925](https://github.com/baizhiheizi/enjoy_player/pull/925)): a third player lens joins Listen and Echo, derived as a single `PlayerLens`; the `E` / `H` hotkeys and the top-bar segmented switch now select exactly one lens (a pre-v30 session saved with both flags reopens in Echo), the dock's Hide pill is replaced by Dictate, and a hint pill over the transcript explains "listen, then hover a line to peek" (press-and-hold on touch). Phones show label-only 36 px segments that scale down rather than overflow at 360 px, and the phone Listen dock now starts with Replay.
- **Echo loop "+ line" edge rows** ([#927](https://github.com/baizhiheizi/enjoy_player/pull/927)): the lines just above and below the active Echo loop render as dashed "+ line" rows — tapping one grows the loop by that line (`[` / `]`), and the 40 px "−" beside it drops the loop's first or last line (`{` / `}`), disabled on a one-line loop. Both route through the existing expand/shrink interactions with no controller change; the rows hide while a take records, and the old Earlier / Later pill handles on the bracket edges are deleted.
- **Docked player side margin and a real takes list** ([#928](https://github.com/baizhiheizi/enjoy_player/pull/928)): word lookup and take assessment open a 360 px paper panel docked beside the expanded player at ≥ 1100 px — the transcript and video reflow around it, and Esc closes it — while below that, and outside the player, one shared `PlayerMarginRoute` drawer replaces the two near-identical lookup and assessment drawers (phone bottom sheet unchanged). The takes chip strip becomes a `ShadowTakeSummaryRow` (play the selected take, `Take 3 · 84` with its level word or "Not scored yet · click to score", `3 takes ›`) opening a `ShadowTakesListPanel` in the margin (bottom sheet on phones): takes newest-first, playing a take selects it, per-take delete with confirm, neutral score chips, and a pitch-contour-on-the-loop toggle (`P`). Takes and assessment panels close when the player leaves Echo, a word lookup stays open, and the margin closes when the media changes.
- **"In this audio" context on the lookup sheet** ([#933](https://github.com/baizhiheizi/enjoy_player/pull/933)): looking up a transcript word now opens with an `In this audio · 0:20` block showing the line the word came from with the looked-up word bolded (`In this video` for videos); non-transcript callers (vocabulary, Craft) pass no context and render no block. The desktop video stage now paints `t.video` on a `ground` transcript rail (was black on `surface`), and the assessment margin heading reads `Take 3 · Assessment` wherever the take number is known.
- **Export the Echo loop as a clip** ([#935](https://github.com/baizhiheizi/enjoy_player/pull/935)): a new Media group in the player's More menu exports the active Echo loop's `[start, end)` range as a standalone MP4 (video) or M4A (audio) file — re-encoded rather than stream-copied so cut points are exact, with the filename derived from the sanitized media title and absolute second range. Desktop hands off through a save dialog (bundled FFmpeg CLI on Windows/Linux, FFmpegKit on macOS); iOS and Android use the system share sheet. The entry is gated on an active loop plus a direct source (local file, security-scoped bookmark, or direct URL), so YouTube rows render dimmed, and a dedicated notice appears when no FFmpeg runtime is found. Closes #922. See [docs/features/echo-mode.md](docs/features/echo-mode.md).
- **Download the transcript as SRT or VTT** ([#936](https://github.com/baizhiheizi/enjoy_player/pull/936)): a "Download transcript…" row in the More menu's Transcript section (and the phone Subtitles sheet) saves the active primary transcript as a SubRip `.srt` or WebVTT `.vtt` file. The serializers are the exact write-side inverse of the existing parsers — pinned by round-trip tests, with blank and zero-duration cues skipped so output always re-parses. Works for local and YouTube media whenever lines exist; save dialog on desktop, share sheet on iOS/Android. Closes #921. See [docs/features/transcript.md](docs/features/transcript.md).
- **Edit media details from the player** ([#937](https://github.com/baizhiheizi/enjoy_player/pull/937)): an "Edit details" row in the More menu's Media group opens a dialog to rename the item and change its content language (reusing the library's language picker). Saving persists through the existing repository with a sync `update` enqueued — renames propagate cross-device — patches the open player session in place so the top-bar title and transcript/lookup language update without reopening, canonicalizes broad tags (`en` → `en-US`), and the lazy YouTube oEmbed refresh no longer overwrites a user-renamed title. Closes #923. See [docs/features/library.md](docs/features/library.md) and [docs/features/player.md](docs/features/player.md).
- **Transcript editor behind "Edit transcript"** ([#938](https://github.com/baizhiheizi/enjoy_player/pull/938)): the first row of the More menu's Transcript section (desktop menu and phone sheet, gated on an existing transcript) opens `/player/:mediaId/edit-transcript` as a child of the player route, so playback keeps running in the dock underneath. The editor lays each cue out as a card with the line text plus Start / Duration-in-seconds fields; invalid timing blocks the save and writes nothing, and a cue's nested word timings survive only while its text is unchanged — once the text moves they are dropped rather than highlighting stale words (karaoke/IPA falls back to line-level display). Saves go through the existing `replaceTimeline` (DAO upsert, cache invalidation, row marked local) and the player's transcript re-emits the edited lines live; scope is deliberately edit-existing-cues only, with add/delete/reorder still future. Closes #920. See [docs/features/transcript.md](docs/features/transcript.md).

### Changed

- **Transcript scrollable list split into four focused modules** ([#1007](https://github.com/baizhiheizi/enjoy_player/pull/1007)): the 693-line `transcript_scrollable_list.dart` is now a composition root over three siblings — `transcript_virtual_items.dart` (a UI-free render-item model), `transcript_auto_scroll_controller.dart` (the auto-follow scroll engine), and `transcript_line_item_builder.dart` (the per-row builder and its scope). The public `TranscriptScrollableList` API is unchanged, and the auto-translate eligibility check stays a top-level function rather than a per-row closure. New unit tests cover `buildTranscriptVirtualItems`, and [docs/features/transcript.md](docs/features/transcript.md) gains a code-layout table. No user-visible change.
- **SRT parsing is ~1.9x faster** ([#1006](https://github.com/baizhiheizi/enjoy_player/pull/1006)): the subtitle import path parses SRT cues on the UI isolate, and three hot spots dominated the profile — two whole-string `replaceAll` passes to normalize line endings on every parse (even the common LF-only case), a regex match for the cue-index line on every block, and a `Duration` allocation per timestamp through `tryParseHmsDuration`. Line endings are now normalized only when a carriage return is present, digit-only cue indexes are detected with a scan, and timestamps are read digit-by-digit. Parsing 5000 cues drops from ~10.3 ms to ~5.5 ms (LF) and from ~13.5 ms to ~6.8 ms (CRLF). Covered by a structural test over the 5000-cue scale fixture (line-ending equivalence plus the accepted timestamp forms) and a local-only microbenchmark. See [docs/features/transcript.md](docs/features/transcript.md).
- **Vocabulary word-list contexts load in one query** ([#1000](https://github.com/baizhiheizi/enjoy_player/pull/1000)): the All Words table resolved the first context sentence of each rendered row through a per-row `FutureProvider` family, so the list issued one Drift query per visible word and re-queried every row that scrolled back into view. It is now a single bulk read over the visible items — a narrow `selectOnly` projection of item id, text and createdAt, chunked at 900 ids per `IN (...)` statement, keeping the earliest context per item. See [docs/features/vocabulary.md](docs/features/vocabulary.md).
- **Codegen toolchain lifted off stale analyzer ceilings** ([#998](https://github.com/baizhiheizi/enjoy_player/pull/998)): `build_runner`, `drift_dev` and `riverpod_generator` were capped because `freezed` pinned analyzer `^12`. Riverpod has since shipped `riverpod_analyzer_utils` 1.0.0-dev.12 on analyzer `^13`, so the caps lift together with `freezed`, which now allows 4.x — freezed 3.2.6-dev.1 → 4.0.3, build_runner 2.15.1 → 2.16.2, drift_dev 2.34.0 → 2.35.1, riverpod_generator 4.0.4 → 4.0.9, analyzer 12.1.0 → 14.5.0. The regenerated output is mechanical: riverpod_generator's 89 outputs are byte-identical, drift_dev only spells out type arguments it previously inferred, and freezed routes `copyWith` through the redirect constructor.
- **Capture stage split into four focused files** ([#964](https://github.com/baizhiheizi/enjoy_player/issues/964)): the 758-line `capture_stage.dart` is now a 346-line entry owning the recorder lifecycle, timers, amplitude ring buffer, and stage dispatch, composing three siblings — `capture_stage_idle_view.dart` (`CaptureIdleView`, the mic prompt with language chips), `capture_stage_recording_view.dart` (`CaptureRecordingView` with the pulse/elapsed readout plus the private `_AmplitudeBarsPainter`), and `capture_stage_text_fallback.dart` (`CaptureTextFallback`). `CaptureStage` keeps its signature and stays the only symbol imported by `express_flow.dart` and the test suite, which passes unchanged — no user-visible change. Extracted widgets carry `Key?` per the public-widget convention.
- **Unified purchase sheet split into focused modules, and the yearly price label fixed** ([#951](https://github.com/baizhiheizi/enjoy_player/issues/951)): the 784-line `auto_renew_plan_sheet.dart` — the largest non-generated file in `lib/` — is now a 48-line entry composing four siblings: `unified_purchase_sheet_body.dart` (`UnifiedPurchaseSheetBody`, which owns the selected path / duration / processor state and dispatches both flows with their error mapping), `payment_path_selector.dart` (`PaymentPath`, `PaymentPathSelector`, `PaymentOptionCard`), `purchase_panels.dart` (`AutoRenewPanel`, `PrepaidPanel`), and `purchase_sheet_helpers.dart` (`ActiveAutoRenewWarning`, `PlansLoadingPlaceholder`, `UnavailablePlansView`). `showAutoRenewPlanSheet` and `showUnifiedPurchaseSheet` keep their signatures and stay the only symbols imported by call sites, so `subscription_screen.dart`, `subscription_status_card.dart`, and both test suites are untouched. Cross-file widgets carry `Key?` per the public-widget convention.

  The extraction surfaced five defects the monolithic file was hiding, all fixed here: **the auto-renew card ignored the plan's interval** and always rendered `subscriptionAutoRenewPriceMonth`, so the yearly plan showed `79.99 USD/month · Yearly`; it now routes through `subscriptionAutoRenewPriceYear` on `plan.isYearly`, with a new widget test pinning both labels (the yearly interval had no coverage at all). `_startAutoRenew` matched `e.toString().contains('missing_pay_url')`, which violates `launchPayUrl`'s documented contract of `StateError(:final message)` matching and silently degraded to a generic failure on any message change — it now uses the same pattern matching as the sibling `_startPrepaidPurchase`. Amounts on one sheet were formatted two ways (`NumberFormat('0.00')` and locale-blind `toStringAsFixed`), so the two cards could disagree on the decimal separator; both now go through `formatUsdAmount` in `purchase_amount_format.dart`. Three never-read members were dropped rather than published as public API: `PaymentOptionCard.path`, `PaymentPathSelector.interval`, and `PaymentPathSelector.plansLoading` (always `false`, because the parent swaps in `PlansLoadingPlaceholder` during loading, which made the option card's skeleton branch unreachable).
- **AI playground screen split into four focused files** ([#940](https://github.com/baizhiheizi/enjoy_player/issues/940)): the 835-line `ai_playground_screen.dart` is now a 557-line entry composing three siblings — `ai_playground_section.dart`, `ai_playground_provider_card.dart` (a new `AiPlaygroundProvidersCard` that owns the header and the five provider rows previously built inline), and `ai_playground_console_panel.dart`. `AiPlaygroundScreen` remains the only symbol the router imports, and the existing `ai_playground_screen_test.dart` suite passes unchanged — no user-visible change.
- **One daily-credits limit provider, one low-credits helper** ([#943](https://github.com/baizhiheizi/enjoy_player/issues/943), [#944](https://github.com/baizhiheizi/enjoy_player/issues/944)): the `status?.dailyCreditsLimit ?? dailyCreditsLimitForTier(tier)` fallback glue was hand-rolled in three surfaces (`LookupCreditsChip`, `ProfileContent`, `AccountSection`) and the "is the daily pool low?" comparison in two (`LookupCreditsChip` as `1 - remaining/limit`, relying on a NaN accident to survive `limit == 0`; `ProfileCreditsCard` as a guarded `used/limit`). Both now have a single home: `dailyCreditsLimitProvider` (subscription, keepAlive, watches `subscriptionStatusProvider` + `currentTierProvider`) and `creditsUsedFraction` / `creditsLow` next to `kLowCreditsUsedFraction` in `credits_thresholds.dart`. Results are unchanged everywhere; the chip's `limit == 0` case is now an explicit guard instead of an IEEE-754 coincidence. New unit tests pin the provider's precedence (live status wins; cached-tier fallback while loading, failed, or signed out) and the helper's boundary cases (`limit == 0`, unknown usage, threshold edges); `docs/features/dictionary-lookup.md` updated to name the provider.
- **Lookup retry controls share one tap-latch state** ([#941](https://github.com/baizhiheizi/enjoy_player/issues/941)): the "busy from tap until the parent reports the retry" `StatefulWidget` boilerplate (`_tapLatched` field, edge-sensitive `didUpdateWidget` reset, busy getter) existed three times — `LookupRefreshIconButton`, `LookupErrorRow`, and `LookupCreditsNotice` — and the newest copy had already drifted to a different reset rule. All three now mix in `LatchedRetryState` (`latched_retry_state.dart`), which owns the latch, the canonical rising/falling-edge reset, `retryBusy`, and `retry(action)`; each widget only maps its own `isRetrying` / `isRefreshing` field onto `parentRetryBusy` / `wasParentRetryBusy`. Widget APIs are unchanged. `LookupCreditsNotice` gains its first dedicated test file, covering render, tap-through, disabled-while-retrying, and the latch reset path no test exercised before; a canonical `latched_retry_state_test.dart` pins the mixin rule (latch persistence across idle rebuilds, rising-edge unlatch, falling-edge re-arm) once for all three widgets. Closes #941.
- **Duet design language** ([#853](https://github.com/baizhiheizi/enjoy_player/pull/853)): the app now reads as one crafted product on every platform through a UI/UX-only ground-up redesign that replaces the unreleased Aurora look. Two voices carry meaning: `original` (blue #4797F5) for the speaker / playback / Listen, and `you` (violet #8B2FE0) for the learner / Echo / takes; the brand gradient (#2563EB → #7C3AED) is Enjoy itself (Play, primary buttons, Pro, the goal ring), and everything else is ink on cool neutrals. The voices are never told apart by hue alone — original is always the translucent layer and you the solid one, with a ~1.9:1 lightness gap in both themes. Type is Literata for content, transcripts, page titles, and big numbers; Geist for the interface; Geist Mono for time, scores, keys, and IDs; Noto Sans for IPA. Every weight in use is bundled under `assets/fonts/google_fonts/`. Modes are lenses: Listen and Echo share one transcript and one screen, Echo grows the loop line in place and fades the rest through the logo's opacity steps, and `[` `]` `{` `}` keep their expand/shrink bindings. Every player control lives in the dock (three variants: Listen, Echo, Recording). Word lookup and take assessment open in a 380 px side margin on the player: docked at ≥ 1100 px, drawer route between 600 and 1100 px, bottom sheet on phones. The player gets a solid top bar instead of the floating frosted collapse control. UI/UX only: features, behavior, hotkeys, and data are frozen; the Echo loop keeps pause-and-rewind at the loop end. See [ADR-0093](docs/decisions/0093-duet-design-language.md), [`docs/design/duet/`](docs/design/duet/README.md), and [docs/features/app-ui.md](docs/features/app-ui.md).
- **Home recents loading placeholder** — the last hand-rolled static skeleton in the app now renders through the shared `Skeleton.box` / `Skeleton.line` primitives, so it shimmers and honors reduced motion like every other loading surface. The whole loading scroll view is wrapped in one `SkeletonTickerHost`, so the grid drives a single shimmer clock instead of 24 per-box tickers. See [docs/features/skeleton-loading.md](docs/features/skeleton-loading.md#shared-shimmer-clock).
- **Record-ring disk now lives in one shared primitive** ([#904](https://github.com/baizhiheizi/enjoy_player/pull/904)): the "you" record disk (color, shadow, inner dot) was being built twice — once in `DockRecordButton` (Echo dock) and once inline in `_RecordingControls`'s Stop button — so they could drift in pixel-for-pixel rendered detail. A new `DockRecordRing({ diskSize, dotShape })` primitive in `player_dock_primitives.dart` selects the inner glyph via `DockRecordDotShape.circle` (Echo) or `stopSquare` (Recording). Rendering is byte-identical at the call sites: same `t.you` fill, same `t.shadowRecordButton`, same 16 px dot, and the Recording stop keeps its 62 px hit target around a 50 px disk. Closes #895.
- **Credits usage screen split into five focused files**: `credits_usage_screen.dart` (842 lines) is now a slim entry composing four focused siblings — `credits_usage_filters.dart` (FiltersGroup + start/end/service pills + `pickCreditsUsageDate` + `hasActiveCreditsUsageFilters` + `kCreditsUsageServiceTypeValues`), `credits_usage_log_views.dart` (`creditsUsageLogsSliverGroup` + UsageTable + UsageLogCard + _UsageBadge + _UsageMetaPill), `credits_usage_states.dart` (PageErrorBody + CreditsUsageLoadingList + UsageLogCardSkeleton + CreditsUsageEmptyState), and `credits_usage_format.dart` (`serviceTypeLabel`, `serviceTypeIcon`, `tierLabel`). `CreditsUsageScreen` remains the only widget imported by the router; the other public symbols are re-exported from the entry to keep `credits_usage_screen_helpers_test.dart` and the package's external users stable. Cross-file widgets carry `Key?` parameters per the public-widget convention; behavior, breakpoint (`720`), sliver tree, and `yyyy-MM-dd` UTC date formatting are byte-identical to the original. The breakpoint-heavy sliver group moved into `credits_usage_log_views.dart` with named parameters (it had six positional ones) and its page-info string now names the `hasMore` total-records suffix instead of burying the conditional inside a nested interpolation. `subscriptionTierLabel` moved out of the `profile_hero_card.dart` widget into `auth/presentation/subscription_tier_label.dart`, so the credits formatter no longer depends on a profile hero-card widget to reach it. `credits_usage_screen_test.dart` gains wide/narrow viewport cases pinning both the table and the card branch — neither was covered before the move. Closes #919.
- **Subtitle track picker sheet split into focused modules** ([#907](https://github.com/baizhiheizi/enjoy_player/pull/907)): the 887-line `subtitle_track_picker_sheet.dart` is now a presentation file (247 lines) with the popover route, action handlers, and body builders extracted into `subtitle_track_picker_popover_route.dart`, `subtitle_track_picker_sheet_action_handlers.dart`, and `subtitle_track_picker_sheet_body.dart`, matching the picker's existing helpers / primitives / tiles / sections / actions convention. Public API (`showSubtitleTrackPicker`, `SubtitleTrackPickerSheet`) unchanged.
- **Local-file subtitle import now has one entrypoint** ([#910](https://github.com/baizhiheizi/enjoy_player/pull/910)): the pick → language hint → language dialog → trim → repository import → success notice flow existed twice — once as `pickAndImportSubtitleFile` in the picker sheet and once as `_TranscriptPanelState._import` in the transcript panel — and the sheet copy had drifted ahead with the `transcriptGeneration*` analytics funnel, so importing from the empty state was invisible to that funnel. The whole flow is now in `import_subtitle_file.dart` with analytics emitted unconditionally rather than behind a per-caller flag, so the two surfaces cannot diverge again. `kSubtitleImportExtensions` is hoisted to the same file, and the no-value pass-throughs `runExtractEmbeddedSubtitles` / `runGenerateTranscript` are replaced by `runEmbeddedSubtitleExtract` / `launchAsrGeneration`.
- **Android SDK bootstrap no longer depends on `dl.google.com`** ([#980](https://github.com/baizhiheizi/enjoy_player/pull/980)): the self-hosted Android runner bootstraps `cmdline-tools` from the Tencent mirror, but the `android-actions/setup-android` fallback ran first and could burn gigabytes of proxied `dl.google.com` egress before the mirror path was tried. The mirror bootstrap now runs first and the Google path is only the last resort, for networks where the mirror is blocked but Google is reachable.
- **Apple smoke CI resilient to network brownouts and stale locks** ([#911](https://github.com/baizhiheizi/enjoy_player/pull/911)): three failure modes hit the self-hosted macOS runner this week — a job cancelled mid-build left the SPM host lock behind and blocked every later Apple job for up to an hour; transient `gh` CLI network errors were treated as fatal; and a missing `curl` retry on the misroute fetch made a single packet loss a 30 s timeout. The lock now records the holder's PID and a stale-lock sweep runs before each job, network errors retry with backoff, and the misroute fetch retries transient HTTP failures.
- **CI caches pub and Gradle over the LAN cache server** ([#912](https://github.com/baizhiheizi/enjoy_player/pull/912), [#913](https://github.com/baizhiheizi/enjoy_player/pull/913)): every job reset `~/.pub-cache` and `~/.gradle` to a pristine state before the run, so both were re-downloaded each time, while the Flutter SDK persisted across jobs (it installs under `RUNNER_TOOL_CACHE`). Both are now cached over the LAN cache server with a public-mirror fallback on miss, so subsequent jobs restore the cache instead of paying the download cost. Cuts ~minutes off every CI run.
- **Cloud library thumbnail URL has one builder** — the `remoteThumbnailForCard(item.thumbnailUrl, youtubeVideoId: provider == 'youtube' ? md5 : null, mediaUrl: mediaUrl)` block was inlined in both the cloud audio row (`_CloudAudioRowState.build`) and the cloud video tile (`_CloudVideoTileState.build`), so the two could drift as the call evolved. The shared expression is now in a private `_thumbUrl(RemoteLibraryItem)` helper next to `_coverSeed`, and both build sites call it, matching on the new `kProviderYoutube` constant rather than a bare literal. The new `test/features/cloud/application/cloud_add_to_library_test.dart` pins the `CloudAddToLibrary` add / `isInLibrary` pair against an in-memory Drift DB (12 cases) — kind dispatch into the independent `videos` / `audios` tables, the server-field mapping on both kinds, and the insert-or-replace write.
- **Architecture deepening wave** (review issues [#748](https://github.com/baizhiheizi/enjoy_player/issues/748), [#764](https://github.com/baizhiheizi/enjoy_player/issues/764), [#794](https://github.com/baizhiheizi/enjoy_player/issues/794)): three passes of module-deepening refactors across the player, sync, settings, transcript, YouTube, and language layers, each pinned by new invariant tests with no intended behavior change. The load-bearing seams: settings became a typed, scope-aware module (a wrong-scope read fails loudly instead of returning null); `PlayerEngine` split into transport / capability / swap layers behind `PlayerEngineIdentity`, the single precedence resolver for test doubles, owned engines, and the lazy default; `YoutubeSession` became the one owner of YouTube playback truth; and one timeline codec now owns decode, memoization, and cue lookup, replacing three independent decoders and two active-cue searches (ADR-0070's "one JSON contract" finally holds end to end). The same window closed the `MediaRegistry` read/write seams, typed sync-queue payloads behind one retry-policy module, moved the YouTube JS protocol behind an app-owned channel adapter, derived every language catalog from one descriptor row, unwound engine-swap supersede through a single path, and closed with a repo-wide zero-comment audit that stripped ~6.2k explanatory `//` lines. See [ADR-0070](docs/decisions/0070-nested-transcript-timeline.md), [ADR-0090](docs/decisions/0090-one-language-descriptor-row.md), and [docs/features/player.md](docs/features/player.md).
- **Main-thread, memory, and startup performance audit** (issue [#810](https://github.com/baizhiheizi/enjoy_player/issues/810); [#811](https://github.com/baizhiheizi/enjoy_player/pull/811), [#812](https://github.com/baizhiheizi/enjoy_player/pull/812), [#813](https://github.com/baizhiheizi/enjoy_player/pull/813), [#814](https://github.com/baizhiheizi/enjoy_player/pull/814), [#815](https://github.com/baizhiheizi/enjoy_player/pull/815), [#816](https://github.com/baizhiheizi/enjoy_player/pull/816), [#817](https://github.com/baizhiheizi/enjoy_player/pull/817), [#818](https://github.com/baizhiheizi/enjoy_player/pull/818), [#819](https://github.com/baizhiheizi/enjoy_player/pull/819)): returning signed-in users no longer flash through the sign-in screen on launch and an expired token no longer gates Home on a network round trip; all UI fonts are bundled, so first paint never downloads from the network, shows fallback fonts offline, or relayouts when fonts arrive; and playback-path jank is gone — multi-MB audio decode/resample, JSON decode, hashing, and peak scans moved off the UI isolate (ASR submit, YouTube caption fetch, discover feed, shadow takes, Azure assessment), the shadow-reading panel stopped rebuilding at 2.5 Hz, and the recording ring animates paint-only. Transcript memory is now bounded (LRU-capped decode memo plus per-media providers that dispose on player exit) and auto-translate no longer rewrites the whole timeline per line (at most one row write per second during continuous scrolling). In the background, the sync queue drain pauses while the app is backgrounded, an idle YouTube webview is evicted after 3 minutes (~80–150 MB reclaimed after browsing Discover), and the paused poll loop backs off to one wakeup per 30 s; the batch also fixes the pre-v6 migration backup that never actually ran before the destructive schema drop. See [docs/features/sync.md](docs/features/sync.md) and [docs/features/youtube.md](docs/features/youtube.md).
- **Performance audit pass 3 — palette, alignment, residual N+1s, schema v20** (issue [#827](https://github.com/baizhiheizi/enjoy_player/issues/827); [#828](https://github.com/baizhiheizi/enjoy_player/pull/828), [#829](https://github.com/baizhiheizi/enjoy_player/pull/829), [#830](https://github.com/baizhiheizi/enjoy_player/pull/830), [#831](https://github.com/baizhiheizi/enjoy_player/pull/831), [#832](https://github.com/baizhiheizi/enjoy_player/pull/832)): artwork palette extraction decodes at 200 px instead of full resolution (~40× fewer pixels) so opening a media item no longer stalls the player-open animation; whole-clip forced alignment drops from ~1.4 GB transient memory and 7.5 s to ~18 MB and 0.5 s on a 90-second clip with identical output (the drift band is capped at ±10 s — alignment unchanged for clips under 50 s); Anki export and vocabulary review start replace per-item context queries with one bulk read, and recording sync pulls upsert per page instead of per row; hot widgets watch just the auth scalar they render instead of the whole auth state, and the vocabulary list's filter/language derivations moved into providers. Ships Drift schema v20: a `sync_queue` `created_at` index so queue drains stop sorting the table, and materialized `ai_cache` source/target language-pair columns with a pair index, replacing the full-table payload `LIKE` scan when the lookup sheet evicts a changed language pair. See [docs/features/sync.md](docs/features/sync.md) and [docs/features/vocabulary.md](docs/features/vocabulary.md).
- **Store uploads and review actions run through fastlane** ([#871](https://github.com/baizhiheizi/enjoy_player/pull/871)): the two bespoke store-upload paths — Google Play (`upload_play_aab.py` plus its venv bootstrapper, both deleted) and TestFlight (`xcrun altool`, macOS-only) — are replaced by fastlane `supply` and `pilot`, with new `ios review_status` / `ios submit_review` lanes for the App Store review cycle (export-compliance and third-party-content questionnaire answered). Builds, signing, notarization, and desktop publishing stay with the existing release scripts, and `release.sh` flags, env-var contracts, workflows, and secrets are unchanged. See [ADR-0094](docs/decisions/0094-fastlane-store-uploads.md) and [docs/packaging.md](docs/packaging.md).
- **Transcript v30 type scale and current-line card** ([#929](https://github.com/baizhiheizi/enjoy_player/pull/929)): transcript lines move to the canvas v30 scale — desktop 17 → 19 px with the current line at 25 (video column 16/20, phone 17/23; phone translation 15 active) — and the active line sits on a paper card with 16 px padding and a lift shadow (10 px plain text before, radius 10 → 16). Overlines shift to 11 px small capitals at 0.09 em across the Subtitles panel, More menu, margin header, and loop labels.
- **Compact phone dock keeps the transcript height** ([#948](https://github.com/baizhiheizi/enjoy_player/pull/948)): the phone Echo dock took about 177 dp plus safe area — close to a quarter of the screen, dominated by a 76 dp record zone with captions underneath — and all of it came out of the transcript being read while practicing. Every phone dock is now the ruler row over one 56 dp controls row (~111 dp total, the same height across Listen, Echo and Recording; Echo takes Listen's shape with Replay and a 1.0× speed slot and no captions), and the recording Cancel / Stop pair shrinks into the sunk group; tooltips and semantics still name every control. Desktop docks are unchanged. See [docs/features/player.md](docs/features/player.md).
- **Playback and library performance pass** (issue [#968](https://github.com/baizhiheizi/enjoy_player/issues/968)): five targeted optimizations ship together. Transcript lines now watch a revision-only projection instead of re-reading the full 1–10 MB row on every ~2 s playback clock flush, and auto-translate no longer pulls two full blobs per cue ([#969](https://github.com/baizhiheizi/enjoy_player/pull/969)) — see [docs/features/transcript.md](docs/features/transcript.md). Library tabs, the Home Continue card, Craft history, and Discover membership read narrow index-backed views (schema v20 → v21 adds `idx_audios_provider`) instead of keeping one whole-catalog watch alive from app start, so Home and library load faster and unrelated writes no longer re-map the entire catalog ([#970](https://github.com/baizhiheizi/enjoy_player/pull/970)) — see [docs/features/library.md](docs/features/library.md). The sentence ruler memoizes its static geometry and moves the playhead to a pixel-quantized paint-only layer, dropping ruler work from up to 38 ms/s (10k lines) to essentially zero for an hour-long video — smoother scrubbing and less jank with drag and haptic-scrub semantics unchanged ([#971](https://github.com/baizhiheizi/enjoy_player/pull/971)) — see [docs/features/player.md](docs/features/player.md). The YouTube frame-stall probe now runs only on Linux (its verdict was never consumed elsewhere) and backs off after healthy sample pairs, cutting ~4,000 GPU texture readbacks (≈712 MiB) per hour at 1080p down ~8× while still catching late stalls ([#972](https://github.com/baizhiheizi/enjoy_player/pull/972)) — see [docs/features/youtube.md](docs/features/youtube.md). The Echo region card decodes the Azure pronunciation-assessment payload once per revision — off the UI isolate above 32 KB — instead of on every rebuild, where a 100-line take cost 6.49 ms per build ([#973](https://github.com/baizhiheizi/enjoy_player/pull/973)).
- **Controller, catalog, and capability splits across features (no user-visible change)**: the 734-line `craft_controller.dart` is now a 173-line composition root assembling stage mixins per pipeline (translate, synthesize, capture, library) over a shared `CraftControllerCore` ([#997](https://github.com/baizhiheizi/enjoy_player/pull/997)) — see [docs/features/craft.md](docs/features/craft.md); the 737-line `tier_catalog.dart` split into focused sibling modules with the hub re-exporting the leaves so the importable API is unchanged ([#989](https://github.com/baizhiheizi/enjoy_player/pull/989)); the duplicated `_resolvePlan` tier lookup was deduped into a shared `resolveCatalogPlan` with `SubscriptionTier.name` as the single source of the tier wire name, protecting the paid card's pricing fallback chain from silent divergence ([#996](https://github.com/baizhiheizi/enjoy_player/pull/996)); the long-form ASR cancellation guard repeated four times now lives in one `_throwIfCancelled` helper ([#988](https://github.com/baizhiheizi/enjoy_player/pull/988)); the three Azure BYOK capabilities share a `ByokAzureSpeechCapability` base class plus a `ttsResultFromAzureOutcome` word-boundary mapper ([#957](https://github.com/baizhiheizi/enjoy_player/pull/957)) — see [docs/features/ai.md](docs/features/ai.md); the assessment no-result fallback duplicated across the result dialog and margin now renders through one shared dialog backed by `primaryNBest` ([#978](https://github.com/baizhiheizi/enjoy_player/pull/978)); and the 762-line `vocabulary_review_session.dart` split into concern mixins (lifecycle, navigation, context, fetches, practice) with its public API importable from the same path ([#979](https://github.com/baizhiheizi/enjoy_player/pull/979)) — see [docs/features/vocabulary.md](docs/features/vocabulary.md).

### Fixed

- **The download page's canonical and social links pointed at a domain that does not exist** — the landing page is served from `https://player.enjoy.bot` (the README badge and the in-app practice-poster QR code already used it), but the page's `canonical`, `og:url`, `og:image` and `twitter:image` meta tags, and the release documentation, named `get.enjoy.bot`. A shared link therefore carried a canonical URL and a social preview image on a dead host. Every reference now names `player.enjoy.bot`; the historical CHANGELOG entry and the archived openspec change records keep their original wording.
- **The Sparkle appcast is well-formed again** — `merge_appcast_xml.sh` printed each merged `<item>` block with `printf '%s'`, so the trailing newline was lost to command substitution and `</item>` was glued to whatever followed it. A Windows-only publish wrote `</item>  </channel>` onto one line; the next merge then carried that stray `</channel>` into the new feed, so the published `appcast.xml` had two `</channel>` elements and no longer parsed — macOS and Windows auto-update could not read the feed. The merge now prints each item with its newline, cuts the closing line at `</item>` so a malformed remote block is repaired on the next publish, and `publish_player_release_to_s3.sh` refuses to upload a feed that is not well-formed XML.
- **The iOS IPA packaging gate no longer rejects Xcode's Swift runtime library** — v0.10.0's `flutter_inappwebview` 6.2.0-beta.3 upgrade moved the plugin to Swift Package Manager, so the iOS build links Swift code and Xcode embeds its own `libswiftCompatibilitySpan.dylib` into `Frameworks/`. `check_ios_ipa.sh` rejected every naked `.dylib` there (a rule written for the older CocoaPods-based plugin, whose `libespeak-ng.dylib` was the original TN2435 offender) and failed the release with "standalone .dylib files in Frameworks/ are not allowed on iOS (TN2435 / ITMS-90426)". TN2435 exempts "the system Swift libraries provided by Xcode", and App Store Connect accepts the upload — `xcrun altool --validate-app` reports "VERIFY SUCCEEDED with no errors" for the v0.10.0 IPA. The gate now exempts the shim on its code-signing identifier (`com.apple.dt.runtime.swiftCompatibilitySpan`), which Xcode preserves when it re-signs the shim with the app's own identity, and still rejects every other naked `.dylib`.
- **Linux and Apple builds no longer die on the `package:sqlite3` download** — the sqlite3 build hook downloads its prebuilt library from GitHub Releases with Dart `HttpClient` (no retries), so a dropped TLS handshake failed the whole build or test run with "Building native assets failed". The Apple CI and Android paths already prefetched the library with curl; the Linux CI path and the Linux / Apple release scripts did not, which left `flutter test`, `flutter build linux`, the Linux AppImage release and the iOS / macOS release each on a single un-retried request. The Linux CI workflow and both release scripts now prefetch the slices they need through `tool/prefetch_sqlite3_libs.sh`.
- **Gradle resolves Google Maven through a mirror on the self-hosted runners** — `dl.google.com` resets the TLS handshake on the runner pool's network, so Gradle artifact resolution failed with "Remote host terminated the handshake" and took the Android smoke build and the Android release down with it. The Aliyun mirrors were configured but disabled on CI, which is the one place that needed them; they are now opt-in through `ENABLE_MAVEN_MIRROR` and enabled for the self-hosted Android workflows, leaving GitHub-hosted runners on the plain `google()` path.
- **The macOS eSpeak bundle test no longer fails on a second synthesis** — eSpeak-NG pins its data directory the first time `espeak_Initialize` runs, so a later synthesis that resolved a different data path still read the pinned one. `bundled_espeak_test.dart` deleted the temp directory it had pinned, so the next synthesis failed with `espeak_SetVoiceByName(en-us) failed` — a deterministic macOS-only failure that CI never saw (the path-package suite runs on Linux, where the test skips). The bundled-app synthesis now lives in `bundled_espeak_synth_test.dart`, which runs in its own process and therefore pins the bundled data path it asserts on.
- **Download page links point at the current repository** — the landing page's GitHub links and the JS-disabled releases fallback still used the pre-rename `an-lee/enjoy_player` path. GitHub redirects it, but the links now name `baizhiheizi/enjoy_player` directly.
- **Transcript editor no longer opens under the video texture** ([#960](https://github.com/baizhiheizi/enjoy_player/pull/960)): the permanent `PlayerSurfaceHost` sits above the shell `Stack`, so pushing `/player/:mediaId/edit-transcript` left the still-mounted player page's stage painting over the editor — the same class of bug as the `/youtube/login` WebView route. `RootShell` now sets `forcePark` for any `/player/` sub-route, so the surface parks while the editor is on top and returns when the player does. The `forcePark` contract in [ADR-0065](docs/decisions/0065-enjoy-modals-root-navigator.md) / [ADR-0066](docs/decisions/0066-park-player-surface-for-overlays.md), the `PlayerSurfaceHost` dartdoc, and [docs/features/player.md](docs/features/player.md) now name both triggers (competing platform view, and Flutter sub-routes the surface would cover).
- **Local CI gate scripts now run on a stock macOS bash 3.2**: `check_no_new_path_deps.sh` and the `--changed-only` path of `validate_ci_gates.sh` used bash 4's `mapfile`, which does not exist on macOS `/bin/bash` — the path-deps script exited 127 and, because `validate_ci_gates.sh` runs it eagerly, the documented `bash .github/scripts/validate_ci_gates.sh` aborted before any real gate ran. Both now use a `while IFS= read` loop, matching the bash-3.2-compatible style the release scripts already follow.
- **Apple builds survive the `package:sqlite3` prebuilt-library download**: the native-assets build hook fetches `libsqlite3.<arch>.<os>` from `github.com` with Dart `HttpClient` (no retries), so a dropped TLS handshake failed the whole macOS/iOS build with "Building native assets failed". `tool/prefetch_sqlite3_libs.sh` now reads the release tag and every expected SHA256 from the installed `package:sqlite3` itself, so a sqlite3 bump can no longer leave it pointing at a stale release (the 3.5.0 → 3.7.0 bump had silently disabled the Android prefetch, whose hand-copied hashes no longer matched), and it covers every platform — including both macOS arches for the universal app. `build_macos_ci.sh` and `build_ios_ci.sh` run the matching prefetch before their builds (best-effort), matching `release_android.sh`.
- **Discover feed card meta row no longer overflows the tile** ([#838](https://github.com/baizhiheizi/enjoy_player/pull/838)): `MediaCardTile` now declares a `metaHeight` budget (the shared `mediaCardTileMetaHeight`) and wraps the meta slot in a `ConstrainedBox` at that height, so content taller than the budget — a platform fallback for `·` / `—`, a larger platform text scale — grows the tile instead of painting the striped "BOTTOM OVERFLOWED BY 2.0 PIXELS" bar under the published line. `mediaCardTileGridAspectRatioForWidth` takes the same budget so the grid's column width and tile height stay in step.
- **Volume popover no longer fills the window on hover** ([#839](https://github.com/baizhiheizi/enjoy_player/pull/839)): Flutter 3.44's `_RenderDeferredLayoutBox.performLayout` passes tight constraints to a non-positioned overlay child, so `CompositedTransformFollower` with no enclosing `Stack` blew the 44×152 slider popover up to the whole window. The hover path now wraps the follower in the same `Stack` the pinned (click) path already used, so the popover keeps its intrinsic size and only the tap-away behavior is gated.
- **Linux transport capsule no longer covered by the video surface** ([#843](https://github.com/baizhiheizi/enjoy_player/pull/843)): the floating-transport redesign gave the shell scaffold `extendBody`, so the side-by-side video column ran to the window bottom while `PlayerSurfaceHost` painted above the whole shell — the video texture and its tap overlay hid the capsule's video-side half and swallowed its taps. The capsule strip is now reserved in the video column via `MediaQuery.padding.bottom`, so the surface target ends above the capsule while the black backdrop still runs to the window edge.
- **Linux embedded subtitle extraction routes through CLI `ffmpeg`** ([#843](https://github.com/baizhiheizi/enjoy_player/pull/843)): when the bundled libav libraries can't be loaded at runtime, the embedded-subtitle extractor falls back to invoking the system `ffmpeg` CLI so MKV/MP4-internal subtitle tracks stay accessible without a vendored native build.
- **YouTube preferred-language caption tracks now match macrolanguage aliases** ([#848](https://github.com/baizhiheizi/enjoy_player/pull/848)): the InnerTube caption-track matcher compared track `languageCode` / `vssId` to the preferred language with exact equality, so Norwegian captions returned as the macrolanguage code `no` were never preferred on `nb-NO` media even though `kLanguageTagAliases` already resolved `no` → `nb`. Both the `_isBetterMatch` comparator and the `preferredLang`-first result sort now match by primary subtag (via `primaryLanguageSubtag`), so any known alias of the preferred language still counts as preferred. The fallback to Tier-2 discovery is unchanged, so reachability is preserved; only preference ordering widens. Closes the residual YouTube caption-code gap from #786.
- **Vocabulary items and contexts now sync across devices** ([#909](https://github.com/baizhiheizi/enjoy_player/pull/909)): three client-side defects were silently dropping every server row on pull — Rails emits `explanation` as a JSON object (not a string), but the parsers did `json['explanation'] as String?`, which raised per row and was swallowed; uploads sent `explanation` as a raw JSON string, which Rails' `permit(explanation: {})` discards; and an off-by-one in the pull cursor poisoned subsequent pages after the first. Parsers now use `jsonTextFromWire` (matching the existing locator handling), uploads re-encode `explanation` as an object before serialization, and the pull cursor advances correctly through paginated responses.
- **YouTube worker transcript uploads now actually retry** ([#726](https://github.com/baizhiheizi/enjoy_player/pull/726)): the durable retry for YouTube worker transcript uploads never had a consumer — the queue drain resolved `video` rows by database UUID while retry rows carry `videoId/language` keys, so every retry row was silently dropped on its first drain pass, and the exact failure the retry was built for (a transient worker blip during a Windows fetch, leaving other devices unable to serve that transcript from cache) stayed live. The drain now dispatches `youtube_upload` payloads straight to the re-upload (failures re-enter the existing 5-strike exponential-backoff machinery; malformed payloads drop without crashing the drain), and repeated failures refresh a single queue row instead of stacking duplicate full-timeline payloads. Fixes [#717](https://github.com/baizhiheizi/enjoy_player/issues/717). See [ADR-0049](docs/decisions/0049-youtube-language-aware-captions.md) and [docs/features/sync.md](docs/features/sync.md).
- **Shadow reading panel no longer errors after reopening** ([#791](https://github.com/baizhiheizi/enjoy_player/pull/791)): cached `distinctBy` streams were single-subscription, so remounting the echo shadow-reading panel — or any second listener on the same stream — threw "Bad state: Stream has already been listened to" and rendered a red error box in the player. Each listener now opens its own upstream subscription with per-subscriber dedupe; no call sites changed.
- **Readable cloud library rows** ([#873](https://github.com/baizhiheizi/enjoy_player/pull/873)): cloud list titles were truncated to 4–6 characters ("Her cu…"); `MediaCardRow` titles now wrap to two lines, matching the PhLibrary board and shared by local rows. Rows with no known language no longer show the raw internal "UND" badge, zero-second durations no longer render a bogus "0:00" (the server hadn't supplied one), and on phone-width cloud lists the refresh button joins the title row instead of folding onto its own line beneath the header.
- **Account routes highlight the Profile tab** ([#874](https://github.com/baizhiheizi/enjoy_player/pull/874)): `/subscription` and `/credits` fell through the bottom-nav path matcher and highlighted Home; both now highlight Profile, matching the account cluster they belong to.
- **Profile tier badge hugs its content and the credits meter gains a low state** ([#875](https://github.com/baizhiheizi/enjoy_player/pull/875)): the "Free" pill stretched across the whole row like a disabled input field; it now sits inline beside the name, brand-tinted for paid tiers. At ≥ 90% of the daily pool the meter switches from the logo gradient to a solid danger bar with "today's credits are almost gone" copy, and free accounts gain a compact upgrade CTA beside the usage link (paid accounts don't). The practice card shows a guidance line when all three stats are zero.
- **Echo dock labels, localized loop captions, and the loop range on the ruler** ([#876](https://github.com/baizhiheizi/enjoy_player/pull/876)): the `E` keycap chip no longer renders on touch devices; phone Echo controls drop the shared sunk capsule and put `Original` / `Record` labels under their own buttons per the PEcho board (desktop unchanged); the hardcoded `LOOP · LINES 3–5 · 7.6 S` and `RECORDING TAKE n` captions are now localized (zh: 「循环 · 第 3–5 句 · 7.6 秒」); and the sentence ruler tints the loop's span with the translucent violet "you" voice instead of only drawing the brackets above it.
- **Lookup sheet shows today's remaining credits** ([#885](https://github.com/baizhiheizi/enjoy_player/pull/885)): a new `LookupCreditsChip` between the language row and the sections reads the existing credits summary ("990 left today", Geist Mono, signed-in only, silent while loading or failed) and flips to the danger tone with "Almost out" copy that taps through to `/subscription` at the same ≥ 90% threshold as the profile meter; the neutral state taps through to `/credits`. After a 402 the summary is invalidated so the chip and the sheet banner never disagree. See [docs/features/dictionary-lookup.md](docs/features/dictionary-lookup.md).
- **Player typography: real weights, sans CJK on Linux, board-matched transcript layout, compact phone profile** ([#898](https://github.com/baizhiheizi/enjoy_player/pull/898)): `google_fonts` pins each style to the one variant it was created with, so the ~135 `copyWith(fontWeight: …)` call sites never changed face — w600 labels rendered Geist Medium and the active transcript line rendered Literata Regular; Geist / GeistMono / Literata / NotoSans are now declared as multi-weight families in `pubspec.yaml`, so every weight in use is the real face. On Linux the engine ignores system-family names in `fontFamilyFallback`, so CJK glyphs at weight 600 fell through to fontconfig's weight-ranked pick — Noto Serif CJK SemiBold for 聆听 / 回声 / the loop caption; the runner now sets a bundled `FONTCONFIG_FILE` that prefers CJK sans faces, skipped when the user has set their own. The transcript layout matches the `Main` board: gutter timestamps share the first line's baseline (original-ink on the active line), the practiced dot no longer changes row height, IPA labels left-align under each word, and Echo lens rows drop the IPA overlay; Craft's capture idle stage scrolls instead of overflowing. On phones the profile hero compacts to a 64 px avatar beside a Literata 26 name with equal-width Edit / Upgrade buttons (~40% of the old stacked height), and practice figures scale down to fit instead of truncating to `1h 48…`. See [ADR-0095](docs/decisions/0095-declared-font-families-and-linux-cjk-fallback.md) and [docs/features/app-ui.md](docs/features/app-ui.md).
- **Linux YouTube stalls from missing GStreamer codecs are diagnosed** ([#899](https://github.com/baizhiheizi/enjoy_player/pull/899)): hosts without the GStreamer demuxer/decoder plugins (common for source builds using the host GStreamer rather than the AppImage's bundled set) stalled YouTube playback silently — the availability probe only checked that WPE could load a page, so the watch page loaded but the `<video>` stayed at `readyState 0` through the stall-recovery cycle. The probe now evaluates `MediaSource.isTypeSupported` in the headless WebView for one YouTube video codec (H.264 / VP9 / AV1) and one audio codec (AAC / Opus), and a miss maps to a new localized notice naming the packages to install (`gst-plugins-good`, `gst-plugins-bad`, `gst-libav`) beside the existing "Open in browser" fallback. See [docs/features/linux-platform.md](docs/features/linux-platform.md) and [docs/features/youtube.md](docs/features/youtube.md).
- **Duet UI/UX audit pass against the design boards** ([#900](https://github.com/baizhiheizi/enjoy_player/pull/900)): every gallery scene was re-captured and compared side by side with `tool/duet_compare.sh` (44 compares), closing the gaps that hurt usability, consistency, or polish while keeping app behavior where a board would have changed a feature. Most user-relevant in the player: top-bar meta shows language names in their own language (`Audio · 0:55 · English · 中文`, was `en · Chinese (Simplified, China)`), speed reads `1.0×` everywhere, phone transcripts use the full width with the practiced dot in the margin, phone takes wrap into rows with an icon-only Pitch button (Take 1 was cut off behind a horizontal scroll), and the wide-window assessment margin shows the full result body — replay, re-assess, per-word phoneme analysis — it had silently dropped; scores carry no hue anywhere. Beyond the player: Craft is rebuilt to its board (Express / Advanced header, Capture → Rewrite → Audio stepper, language chips, violet recording view), desktop sign-in gets its brand panel beside the form, subscription tiers show as three columns at hub width, Settings gets an inline System / Light / Dark control, and all twelve yes/no dialogs go through a shared `showEnjoyConfirmDialog`. See [docs/design/duet/STATUS.md](docs/design/duet/STATUS.md).
- **Window title reads "Enjoy Player" on Linux and macOS** ([#958](https://github.com/baizhiheizi/enjoy_player/pull/958)): Linux hardcoded the internal binary name `enjoy_player` in both GTK title paths and the macOS nib still carried Flutter's stock `APP_NAME` placeholder (nothing substitutes it at build time), so both desktops showed the internal name in the header/title bar and app menu. Both now show the product name; Windows, Android, and iOS were audited and already matched.
- **Linux YouTube black-video recovery now works across launches** ([#959](https://github.com/baizhiheizi/enjoy_player/pull/959)): the previous watchdog recovery set `LIBGL_ALWAYS_SOFTWARE` mid-session and rebuilt the WebView, but Mesa only consults that flag at GL context creation, so the rebuilt view still exported zero frames. The stall verdict now persists a marker file and the Linux runner reads it before engine init, relaunching the whole process tree with software GL — the only known-good configuration — while repeat verdicts are logged instead of silently swallowed and a user-set value of the variable always wins. Field-verified on the reporting machine: the session after a stall renders YouTube video normally. See [ADR-0098](docs/decisions/0098-linux-youtube-software-gl-recovery.md) and [docs/features/linux-platform.md](docs/features/linux-platform.md).
- **Bare-`c` Craft shortcut no longer fires while typing in the YouTube login webview** ([#961](https://github.com/baizhiheizi/enjoy_player/pull/961)): the login form lives in an `InAppWebView` that never becomes Flutter's primary focus, so pressing `c` while entering an email navigated to `/craft` and aborted the sign-in. The global Craft hotkey now gates on webview-owned routes (`/player/*`, `/youtube/*`) in both `canExecute` and `execute`. See [docs/features/craft.md](docs/features/craft.md).

### Documentation

- **Stale references corrected across feature docs and spec artifacts** ([#1003](https://github.com/baizhiheizi/enjoy_player/pull/1003)): 32 files under `docs/features/` and `specs/**/{checklists,contracts}/` pointed at renamed files, stale symbol names, or behavior descriptions that had since changed. Pure documentation correction — no behavior change.

- **Drift schema note bumped to v20** ([#844](https://github.com/baizhiheizi/enjoy_player/pull/844)): the schema-version history in [docs/architecture.md](docs/architecture.md) now lists the v18 → v20 rows and the migrations they shipped (`sync_queue` `created_at` index, `ai_cache` pair columns), so the architecture doc stays in step with the persisted DB.
- **Docs drift fixes for the Duet / Linux-YouTube window**: [app-ui.md](docs/features/app-ui.md) now points at `duet_design_language_test.dart`, maps the screen registry to the Duet boards, and drops descriptions of code #853 deleted (`AuroraGlow`, `PlayerAmbientBackdrop`, `GlassSurface`, the dynamic-color module); [ai.md](docs/features/ai.md), [hotkeys.md](docs/features/hotkeys.md), [craft.md](docs/features/craft.md), [credits-usage.md](docs/features/credits-usage.md), [tech-stack.md](docs/tech-stack.md), and [skeleton-loading.md](docs/features/skeleton-loading.md) cite ADR-0093 instead of the superseded Aurora look (credits-usage also loses the removed meter ring and describes the real filter-pill / `Table` layout); [packaging.md](docs/packaging.md) documents the AppImage GStreamer bundling, AppRun env wiring, host-GL exclusion, software-GL default + frame watchdog, and per-release recording that #847 shipped; [dictionary-lookup.md](docs/features/dictionary-lookup.md) describes the single sheet-level credits banner from #872; [youtube.md](docs/features/youtube.md) and ADR-0087 record the alias-aware caption-track ranking from #848; the ADR index and ADR-0048/0083 carry supersession pointers; [testing.md](docs/testing.md) and AGENTS document `validate_ci_gates.sh --changed-only` from #860; AGENTS / Duet STATUS no longer describe the redesign as in flight on `design-duet`.

## [0.9.0] - 2026-09-07

### Added

- **PostHog product analytics** ([#694](https://github.com/baizhiheizi/enjoy_player/pull/694)) with a device-global opt-out switch in Settings → About. Events cover practice, transcripts, lookup/translation, Craft, vocabulary review, subscriptions, and credits; init is manual and token-gated via `--dart-define` so tokenless builds are structurally inert, and Windows/Linux builds stay fully inert (no vendor SDK). See [ADR-0086](docs/decisions/0086-posthog-product-analytics.md) and [docs/features/analytics.md](docs/features/analytics.md).
- **Friendly credits-exhausted errors** ([#648](https://github.com/baizhiheizi/enjoy_player/pull/648)): Enjoy-hosted AI rejections no longer leak "HTTP 402" — every AI surface (lookup, pronounce, auto-translate, ASR, shadow-reading assessment, Craft tools, vocabulary review, purchase paths) renders one shared, localized message with the required/limit/reset details and a one-tap recovery CTA. BYOK provider 402s never show the Enjoy upsell, and repeated failures no longer stack snackbars.
- **Craft preferences are remembered** ([#670](https://github.com/baizhiheizi/enjoy_player/pull/670)): screen mode, translation style per mode, custom prompt, and voice per base language persist across sessions, and the language pair seeds from the learner's profile so the Express idle pill no longer shows "—". See [docs/features/craft.md](docs/features/craft.md).
- **Crafted audio cloud sync** ([#587](https://github.com/baizhiheizi/enjoy_player/pull/587)): Craft-generated audio binaries upload with the sync payload so they play on every signed-in device, not only the one that created them. See [ADR-0081](docs/decisions/0081-crafted-audio-cloud-sync.md).
- **Continue practicing** ([#609](https://github.com/baizhiheizi/enjoy_player/pull/609), [#714](https://github.com/baizhiheizi/enjoy_player/pull/714)): a compact sidebar rail card on desktop resumes the latest echo session (thumbnail, title, progress) and shrinks away when there is nothing to resume. Leaving the player now stops live playback instead of collapsing into a global mini player. See [ADR-0082](docs/decisions/0082-home-continue-no-mini-player.md).
- **Paper & Graphite themes** ([#616](https://github.com/baizhiheizi/enjoy_player/pull/616)): new light and dark themes with a System/Light/Dark preference, a shared chrome SVG icon sprite, and prototype design tokens for radii, assessment colors, and typography across shell, transport, and buttons. See [ADR-0083](docs/decisions/0083-paper-graphite-light-dark.md).

### Changed

- **Redesigned shell and player chrome**: the bottom navigation floats as a frosted-glass capsule, the global transport floats as an inset glass capsule with blur/hide moved into the CC sheet (the phone bar stays play, echo, CC, speed), the audio expanded player swaps its reserved toolbar strip for a floating collapse control, and vocabulary flashcards restyle toward the study-card design with rating buttons in a post-flip footer. The download landing page aligns with the redesigned prototype.
- **YouTube in-page efficiency** ([#662](https://github.com/baizhiheizi/enjoy_player/issues/662)): the watch-inject style pass runs once per DOM shape behind a MutationObserver instead of re-applying ~40 inline properties every 300 ms, poster gating is observer-driven, and the poll backs off while paused.
- **Player rebuild scope and open latency** ([#663](https://github.com/baizhiheizi/enjoy_player/issues/663), [#661](https://github.com/baizhiheizi/enjoy_player/issues/661)): the loading-stage thumbnail resolves and decodes off the UI thread with memoization, the transport progress strip no longer allocates per paint, the buffering overlay and expanded-player chrome builder keep stable identities so parked overlays stop rebuilding the shell, and the echo-session read overlaps `engine.open` instead of serializing behind it.
- **Credits usage records** show a "Used before" column alongside Required/Used ([#690](https://github.com/baizhiheizi/enjoy_player/pull/690)).
- **Dead-code audit** (issue [#704](https://github.com/baizhiheizi/enjoy_player/issues/704)): removed unused widgets, tokens, purchase flows, and API scaffolding across core, data, AI, and feature layers, and dropped the unused `cupertino_icons` and `skeletonizer` dependencies. Internal seams extracted in the same window: `MediaRegistry`, `ShadowTakeStore`, `CraftLibraryRepository`, `EnrichmentBackend`, `CompletionLoop`, one playback-highlight provider, one engine-swap mechanic, and the transcript repository split into focused part files.

### Fixed

- **YouTube play-then-pause**: playback no longer re-pauses itself right after starting. Root causes addressed across the saga ([#589](https://github.com/baizhiheizi/enjoy_player/pull/589), [#620](https://github.com/baizhiheizi/enjoy_player/pull/620), [#650](https://github.com/baizhiheizi/enjoy_player/pull/650)): transport commands route through the page player API and never force muted starts (Chromium's gesture lock turned muted starts + programmatic unmute into a pause), overlay parking keeps the live stage size instead of shrinking the WebView across YouTube's compact-player breakpoint (which flushed ABR), the immediate-pause auto-retry is data-gated and escalates to a second retry for the echo-mode wedge without ever auto-resuming a deliberate pause, and pause-context telemetry explains remaining cases. See [docs/features/youtube.md](docs/features/youtube.md#limitations).
- **Linux platform fixes** ([#643](https://github.com/baizhiheizi/enjoy_player/pull/643), [#644](https://github.com/baizhiheizi/enjoy_player/pull/644), [#647](https://github.com/baizhiheizi/enjoy_player/pull/647), [#619](https://github.com/baizhiheizi/enjoy_player/pull/619)): secure-storage session loss fixed with a vendored patched `flutter_secure_storage_linux` plus serialized keyring ops (sign-in no longer bounces to signed-out when the token exchange succeeded); opening YouTube no longer wedges every later audio open (the ADR-0048 opt-out gates every engine mount path, shows the "coming soon" notice, and never swaps away the live mpv engine); native Google sign-in is disabled and web-PKCE callbacks are delivered to the running instance via D-Bus single-instance forwarding. See [ADR-0084](docs/decisions/0084-linux-google-signin-off-and-pkce-deeplink.md) and [docs/features/linux-platform.md](docs/features/linux-platform.md#what-is-not-yet-available).
- **Assessment word timelines keep source orthography** (issue [#621](https://github.com/baizhiheizi/enjoy_player/issues/621)): eSpeak word events no longer drop, duplicate, or shift displayed words (reduced function words, hyphen compounds, numeral expansions); the app's tokenizer spans are the authoritative orthography and events only contribute timing/phones, with mapping hardened for typographic apostrophes, combining marks, and non-BMP character offsets.
- **Echo mode robustness** (issue [#659](https://github.com/baizhiheizi/enjoy_player/issues/659), [#678](https://github.com/baizhiheizi/enjoy_player/pull/678), [#673](https://github.com/baizhiheizi/enjoy_player/pull/673)): expand/shrink validate persisted line indices after a re-import re-segments the transcript, the lines cache is keyed on the transcript (not the media) so stale cues are never served, poster capture is skipped when an open restores to position 0 with echo active (it fought the enforcer and paused playback), too-narrow windows widen instead of looping seek→pause→seek, and a reset no longer seeks a stale echo target on the new engine — the clamp wait is bounded so one wedged seek can't silently disable enforcement for the session.
- **Player stability**: tapping a tile no longer fire-and-forget-disposes the live engine mid-playback (which wedged media_kit's native event pump and held later opens on the loading skeleton) ([#675](https://github.com/baizhiheizi/enjoy_player/pull/675)); every post-open engine command is bounded so a wedged pump can't hold the loading screen ([#651](https://github.com/baizhiheizi/enjoy_player/pull/651)); the launch pipeline guards against stale open generations so audio no longer keeps playing after leaving the player ([#671](https://github.com/baizhiheizi/enjoy_player/pull/671)); the previous session's debounced write flushes before a new open, so restored echo windows and blur flags no longer leak across media ([#669](https://github.com/baizhiheizi/enjoy_player/pull/669)); completion-loop replay and other engine async paths survive engine errors instead of silently killing repeat/segment-loop for the stint (issue [#658](https://github.com/baizhiheizi/enjoy_player/issues/658), [#674](https://github.com/baizhiheizi/enjoy_player/pull/674)).
- **Transport scrubber** holds the optimistic seek fraction until the engine confirms, so the thumb no longer visibly snaps back on YouTube's ~250 ms command latency ([#679](https://github.com/baizhiheizi/enjoy_player/pull/679)).
- **YouTube metadata refresh** no longer trips Riverpod's "provider cannot depend on itself" assertion when opening from a placeholder row (issue [#676](https://github.com/baizhiheizi/enjoy_player/issues/676), [#680](https://github.com/baizhiheizi/enjoy_player/pull/680)).
- **Overlapping YouTube poll ticks** no longer apply stale DOM snapshots out of order, so the transport no longer shows playing after the video has ended (issue [#655](https://github.com/baizhiheizi/enjoy_player/issues/655), [#672](https://github.com/baizhiheizi/enjoy_player/pull/672)).
- **Player exit**: back navigation pops the route before teardown so the loading placeholder is no longer stranded on screen, and notice rendering no longer aborts snackbar layout mid-pop ([#645](https://github.com/baizhiheizi/enjoy_player/pull/645)).
- **Notices**: snackbar messages keep full width when an action is present (long zh CTAs no longer squeeze the copy into a narrow column on phones), and dismiss affordances match the SDK's 48 dp tap-target geometry ([#691](https://github.com/baizhiheizi/enjoy_player/pull/691)).
- **Subscription pricing**: the yearly savings badge shows only on the yearly tab ([#715](https://github.com/baizhiheizi/enjoy_player/pull/715)).

## [0.8.5] - 2026-08-19

### Fixed

- **iOS TestFlight** packages eSpeak-NG as `eSpeakNG.xcframework` instead of a naked `libespeak-ng.dylib` in `Runner.app/Frameworks/`. App Store Connect treats standalone `.dylib` files as Swift stdlibs (TN2435) and rejects the IPA with ITMS-90426 ("SwiftSupport folder is missing"). Exported IPAs are now checked for the framework, no standalone `.dylib` files, `MinimumOSVersion` 15.0, and strict signing.

## [0.8.4] - 2026-08-19

### Fixed

- **iOS TestFlight packaging** now leaves Xcode's Embed Frameworks phase as the sole owner of copying and signing `libespeak-ng.dylib`. The custom eSpeak script no longer mutates or re-signs nested code after that phase, removes Xcode's empty iOS `Contents/Resources/` container before final signing, and prevents archive export from invalidating the app seal; exported IPAs are now checked for the eSpeak dylib, populated `SwiftSupport/iphoneos/` runtime libraries, strict signing, and `MinimumOSVersion` 15.0.

## [0.8.2] - 2026-08-18

## [0.8.1] - 2026-08-12

### Added

- **Assessment take replay** with karaoke-highlight transcript and word-clip playback for reviewing recorded takes.
- **Post-sign-in onboarding tips** highlight Craft, Import, and other key surfaces via showcaseview.
- **iOS TestFlight public beta invite** on the landing page.

### Changed

- **Whitespace normalization** shared across transcript and onboarding flows via a single helper.
- **Image network cache** swaps remaining `Image.network` for `CachedNetworkImageProvider` for steadier scrolling.

### Fixed

- **Azure TTS usage** reports `usage.tts.textLength` instead of `durationSeconds` so usage metering matches character volume (issue #544).
- **Word-clip playback** starts at the word offset instead of zero so replayed clips match the on-screen word.
- **Onboarding tips** persist the Home tip when Craft/Import is tapped from the showcase prompt.

## [0.8.0] - 2026-08-05

### Added

- **Lite and Pro subscription tiers** with a unified tier catalog, credit balances, purchase flow, and paid-feature gating.
- **Immersive vocabulary flashcard review** with automatic dictionary loading for focused study sessions.
- **Practice poster sharing** from the shadow-reading recording toolbar.

### Changed

- **Transcript and echo layouts** use a more compact mobile density while preserving comfortable 16px line padding.
- **Dictionary lookup actions** are ordered Pronounce → Collect → Copy → Close for a more natural learning flow.
- **Subscription cards** use equal-height layouts and credit-first copy across the tier catalog.

### Fixed

- **YouTube playback** no longer gets stuck in repeated play-then-pause transport retries.
- **iOS App Store builds** include the camera and photo-library usage descriptions required by file-picker integrations.
- **Windows release builds** avoid MAX_PATH failures by staging builds in a short workspace path.

## [0.7.3] - 2026-07-31

### Added

- **Craft history remove**: clearing a Craft history record now keeps the library audio and transcript (it clears Craft provenance instead of deleting). See [ADR-0062](docs/decisions/0062-craft-history-remove-keeps-audio.md) and [docs/features/craft.md](docs/features/craft.md#craft-history-crafthistory).
- **Craft Voice-Express dual-mode** redesign: a voice-first Express mode (speak → ASR → AI rewrite → TTS) is now the default, alongside the existing Advanced translate/synthesize tools. See [ADR-0060](docs/decisions/0060-craft-voice-express-dual-mode.md) and [docs/features/craft.md](docs/features/craft.md).
- **Word pronunciation** with shared playback control and locale resolution.
- **Craft shadow-friendly transcript cues** with Apple word-boundary timing.

### Changed

- **Community activity card** split into focused part files (`avatars`, `bodies`, `metrics`, `stats`) sharing one library scope.
- **Global transport bar** extracts `_LineNavButton` as the shared prev/next/replay control.
- **Media card** split into focused modules.
- **Craft** extracts shared `CraftLoadingView` and `CraftFailureCard`.

### Fixed

- **Enjoy modals** present above `PlayerSurfaceHost`.
- **YouTube mount** no longer notifies during build; Windows pronounce `BytesSource` path fixed.
- **Craft** merges standalone clause punctuation onto the prior word.

## [0.7.2] - 2026-07-22

### Added

- **Auto-renew subscription** with credits packages and membership tiers.
- **Logging test infrastructure** with `TestLoggingScope` helper for asserting log output.

### Changed

- **Transcript repository** split into focused part files (auto-translate, subtitle import, YouTube fetch, worker cache).
- **NavItemPill** extracted as shared widget between sidebar and settings rail.
- **Bearer auth** acquisition centralized into `_ensureAuthenticated`.

### Fixed

- **YouTube login** no longer crashes by parking the surface host.
- **Tablet orientation** no longer mis-locked to portrait at bootstrap.
- **Android TLS** and **macOS SwiftPM** build failures resolved.

## [0.7.1] - 2026-07-21

### Changed

- **Phone orientation and player layout** lock phones to portrait and switch video/transcript between stacked and side-by-side from window aspect instead of a fixed width breakpoint.
- **Library** bumps recency on every open, sorts by recent activity, and defaults to the Video tab.

### Fixed

- **YouTube player overlays** pass host chrome hits through so embedded controls remain clickable.
- **Expired Pro subscriptions** correctly use the free daily credits limit.
- **Android release builds** clear stale plugin caches that could break AGP 9 packaging.

## [0.7.0] - 2026-07-19

### Added

- **Long-form AI transcripts** now use resumable Deepgram jobs for media at least 15 minutes long, with upload progress, persisted in-flight attempts, and clearer processing feedback.

### Changed

- **Vocabulary review and echo practice** have more focused study controls and polished practice layouts.
- **Vocabulary on mobile** now prioritizes the word list, moves statistics into Review details, and collapses filters behind the toolbar.
- **Transcript empty states** use clearer AI transcript wording and actions tailored to local and remote media.

### Fixed

- **Local media reopening and sync** no longer hang after a video is deleted and imported again.
- **Player overlays**, including dictionary lookup, remain correctly positioned above video.
- **Android release builds** support current `share_plus` versions under Android Gradle Plugin 9.

## [0.6.2] - 2026-07-18

### Added

- **Update availability badge** on Settings when a newer app version is ready.

### Changed

- **Android update prompts** now show download progress.

### Fixed

- **Transcript subtitle selection** once again offers the Auto translate option.

## [0.6.1] - 2026-07-18

### Added

- **Vocabulary learning workflow** with transcript lookup actions, AI-enriched review cards, persisted review sessions, cloud sync, media actions, and Pro Anki CSV export.
- **Profile editing** with avatar upload and Enjoy ID support.

### Changed

- **Adaptive layouts and UI polish** across vocabulary, profile, and hotkey screens, using shared page families and gutters.
- **Vocabulary context selection** now prefers complete sentences with a bounded fallback for unpunctuated transcripts.
- **API timezone handling** now uses the device timezone reported by `flutter_timezone`.

### Fixed

- **Sync recovery** now handles duplicate catalog rows during video upload and refetches vocabulary when create responses omit `updatedAt`.
- **Keyboard navigation** dismisses shell sheets before popping routes and returns cleanly from vocabulary review on Escape.
- **Windows Azure assessment** now supports media paths containing non-ASCII characters.

## [0.6.0] - 2026-07-16

### Changed

- **Path-linked local media** — link durable source paths when lasting access exists, fall back to app-managed copies otherwise, and delete shared media only when unreferenced across per-user databases.

### Fixed

- **Practice poster export crash in release mode** — `RenderObject.debugNeedsPaint` throws `LateInitializationError` in release when implemented with `late`+`assert`; export waits for a settled frame, retries rasterization when needed, and resets exporting state in `finally`. See [docs/features/share-poster.md](docs/features/share-poster.md).

## [0.5.2] - 2026-07-16

### Added

- **Shared `LoadingIcon` widget** for inline busy affordances ([#338](https://github.com/baizhiheizi/enjoy_player/issues/338), [#341](https://github.com/baizhiheizi/enjoy_player/pull/341)). A compact 18×18 `CircularProgressIndicator` (`size`, `strokeWidth`, `color`) replaces 30+ duplicated `SizedBox` + `CircularProgressIndicator` patterns across 20 files (auth sidebar chip, profile preferences, settings hub, sync status, transcript busy action, subtitle track picker, lookup refresh/error rows, cloud library body, craft translate/synthesize tools, BYOK forms, discover subscribe sheet / screen / channel filter, share poster preview, locate media, shadow-reading assessment button). Documented in [docs/features/app-ui.md § Widgets reference](docs/features/app-ui.md#widgets-reference).
- **Shared `SectionLabel` widget** for in-card section headers ([#337](https://github.com/baizhiheizi/enjoy_player/issues/337), [#341](https://github.com/baizhiheizi/enjoy_player/pull/341)). Replaces the duplicate `_FormSectionLabel` / `_SpeechSectionLabel` private classes in the BYOK forms with a single public widget (`Icon` + `EnjoyThemeTokens.space8` + bold `labelLarge` text using the active `ColorScheme`). Documented in [docs/features/app-ui.md § Widgets reference](docs/features/app-ui.md#widgets-reference).

### Changed

- **Discover channel refresh uses InnerTube `browse` as primary data source** ([ADR-0047](docs/decisions/0047-youtube-discover-innertube.md)). The per-channel refresh path now tries InnerTube's anonymous `browse` endpoint first (`POST youtubei.googleapis.com/youtubei/v1/browse`) and falls back to the Atom RSS endpoint on failure. InnerTube returns richer metadata (`lengthText`, `viewCountText`, `publishedTimeText`) and is materially less likely to be blocked by YouTube's bot detection. The legacy watch-page HTML duration enrichment is skipped for InnerTube-sourced rows. Client profile rotation (`WEB` → `MWEB`) and continuation pagination (cap 5 pages ≈ 150 entries) match the caption fetcher's posture. See [docs/features/discover.md](docs/features/discover.md). *(Later superseded for feed fetch by [ADR-0051](docs/decisions/0051-youtube-worker-discovery.md) — server-side RSSHub proxy; ADR-0047 remains accurate for that slice of history.)*
- **Discover avatar URL cache rides the shared `L1Store<K, V>` primitive** ([#335](https://github.com/baizhiheizi/enjoy_player/pull/335)). `DiscoverRepository` no longer carries a hand-rolled `LinkedHashMap` LRU for channel avatars; the cache is now a 256-entry, 6-hour-TTL instance of the same [`L1Store`](lib/core/cache/lru_store.dart) that backs the AI result cache hierarchy ([ADR-0045](docs/decisions/0045-ai-result-cache-hierarchy.md)) and `LookupSheetResultCache`. The 6 h TTL is a strict relaxation of the previous infinite lifetime — avatar URLs change only a few times per year, so the window is far longer than realistic re-fetch cadence while bounding memory of long-running sessions that touch thousands of distinct channels. New cache call sites should use `L1Store` instead of re-implementing LRU bookkeeping; see [docs/conventions.md § Caching](docs/conventions.md#caching) for the behavior contract and current call sites.
- **`SyncDownloadService` uses a generic `_downloadEntityInternal<E>` helper** ([#336](https://github.com/baizhiheizi/enjoy_player/issues/336), [#341](https://github.com/baizhiheizi/enjoy_player/pull/341)). The three per-entity download paths (audio, video, recording) now share one ~75-line pagination + merge loop instead of duplicating ~200 lines of triplicated cursor-paging logic. Public `downloadAudios` / `downloadVideos` / `downloadRecordings` / `downloadAllEntitiesFresh` entry points and `SyncResult` shape are unchanged — see [docs/features/sync.md](docs/features/sync.md).
- **Discover feed entry upserts run in a single Drift batch transaction per source** for lower write amplification on large channel refreshes — one `watchTimeline` emission for non-empty upserts; empty responses are a no-op. See [docs/features/discover.md § Cache semantics](docs/features/discover.md#cache-semantics-append-only).

### Fixed

- **Intermittent Windows YouTube play-then-pause startup**: WebView2 ignores `mediaPlaybackRequiresUserGesture`, while the player previously force-unmuted on HTML5's optimistic `play` event. Playback now stays muted until the authoritative `playing` event settles, transport state no longer treats `play` as proof that frames are advancing, and rejected `play()` promises plus command/event/poll transitions are captured by the `YouTube*` diagnostic loggers. The WebView logger names were also corrected from `Youtube*` to the allowlisted, case-sensitive `YouTube*` prefix, fixing pre-existing silent loss of FINE records. See [docs/features/youtube.md](docs/features/youtube.md#limitations).
- **YouTube InnerTube caption profile ladder hardening** so client-profile rotation and worker cache-only transcript fetches fail closed instead of returning empty or mismatched tracks.
- **Shadow-reading assessment restored for unknown media language** — unknown / denylisted media tags (`und`, empty) fall back to the learner's `effectiveLearningLanguage` via `resolveAzureAssessmentLocaleForPractice` / `isAzurePronunciationAssessmentSupportedForPractice` instead of disabling Assess while play / take-menu still worked. Genuinely unsupported primaries still disable the control with a tooltip (no silent `en-US` coercion). See [docs/features/shadow-reading.md](docs/features/shadow-reading.md#pronunciation-assessment-azure) and [docs/features/echo-mode.md](docs/features/echo-mode.md).
- **Discover migration v13 `feed_url` backfill** uses the SQL column name `channel_id` (not the Drift accessor `channelId`), so pre-existing subscriptions get a worker feed URL instead of failing the migration step.
- **Worker YouTube `client-profiles` wire shape parsing** aligned with the actual response body.

## [0.5.0] - 2026-07-13

### Added

- **Linux platform support (AppImage)**. Linux is now a first-class supported desktop platform. ([ADR-0048](docs/decisions/0048-linux-platform-support.md))
  - `linux/` Flutter desktop scaffold, `.github/workflows/build_linux.yml` CI, `release_linux.sh`, AppImage packager
  - Centralized `lib/core/platform/linux_platform_availability.dart` predicates
  - Landing page `#card-linux` with localized strings (en + zh)
  - YouTube engine gracefully opts out on Linux (WebViewGTK not ready for v1)
  - Constitution amendment 1.1.0 → 1.2.0 (Linux added to supported targets)
  - New `docs/features/linux-platform.md`, `docs/decisions/0048-linux-platform-support.md`
  - `AGENTS.md` and `README.md` updated for Linux first-class support

- **Echo enforcement coordinator (`EchoEnforcer`)**: the reactive per-tick
  echo correction and the proactive seek clamp are now serialized through one
  single-flight coordinator, so concurrent seeks can't interleave into an
  audible stutter at segment edges. Enforcement runs on every position event,
  so pause-and-rewind fires within ~50 ms of the segment end (previously up to
  ~360 ms late, sampled on a 400 ms grid). The in-memory session + DB write
  stay on the 400 ms grid so the recorded clip window still lines up. Covered
  by boundary-timing and single-flight serialization tests. See
  [docs/features/echo-mode.md](docs/features/echo-mode.md) and issue #280.

### Changed

- **Position is now durably written mid-playback**: `PlaybackSessionPersister`
  coalesces updates on a 450 ms debounce but forces a flush once pending data
  is older than ~2 s. The 400 ms emit cadence previously re-armed the 450 ms
  debounce forever, so a crash/kill lost all progress since the last pause; the
  max-age bound makes loss rate-independent (works at 1× and 2×). Background
  flush errors are now caught + logged instead of surfacing as uncaught async
  exceptions.
- **Echo window source of truth**: enforcement re-derives start/end seconds
  from the line indices + current transcript at enforcement time (falling back
  to the cached value), so a re-segmented transcript yields fresh boundaries
  instead of stale ones. Echo-path magic numbers and s/ms conversions were
  extracted to named constants/helpers.
- **Guarded mpv teardown**: `PlayerController` disposal is now reentrancy-guarded
  and its teardown future is captured/observable, reducing the latent double-mpv
  race on a future `ref.invalidate` (Riverpod still does not await `onDispose`).

### Added

- **ASR transcript generation**: local audio and video can generate,
  re-generate, and auto-select a time-aligned `source: ai` transcript through
  the existing Enjoy, Azure BYOK, or OpenAI-compatible Whisper capability
  paths. Generated tracks upsert deterministically, propagate a detected
  language, and use localized failure feedback.
- **YouTube bilingual transcripts**: when the learner's native language differs
  from the source, the worker fetch sends a single multi-language
  `pollTranscripts({ languages: [source, native], waitMs })` request instead of
  two sequential calls. The original caption is stored as the primary track and
  the native translation as the secondary; a `partial` response logs the missing
  languages without inventing a primary from a non-existent row. See
  [ADR-0036](docs/decisions/0036-youtube-bilingual-transcripts.md) and
  [docs/features/transcript.md](docs/features/transcript.md#youtube-worker).
- Local CI gate scripts under `.github/scripts/` so contributors and agents
  can mirror the cheapest CI failures before pushing:
  - `validate_ci_gates.sh` — runs `check_dart_format` + `check_codegen_drift`
    (and optionally `flutter analyze` / `flutter test` via `--analyze`,
    `--test`, or `--all`); `--fix` auto-formats and regenerates codegen.
  - `check_dart_format.sh` — fails when `dart format` would change a file in
    `lib`, `test`, or any path package's `lib`/`test`. `--fix` writes the
    formatting.
  - `check_codegen_drift.sh` — runs `build_runner` in the root and any path
    package that declares it, then fails if generated `*.g.dart` /
    `*.freezed.dart` files drift from `HEAD`. `--fix` regenerates and leaves
    the diff to commit.
- `.githooks/pre-push` — blocks pushes that would fail CI `Dart format` and
  (when Dart/lib/package sources are in the push range) `Codegen drift`.
  Install once per clone with `git config core.hooksPath .githooks`; bypass
  with `git push --no-verify`.

### Fixed

- **YouTube transcript upload payload now passes worker validation (#318)**.
  `YoutubeTranscriptsApi.uploadTranscript()` now sends the full
  worker-required body: `format: "enjoy"`, the worker-side
  `caption_fetch` derived from `source` (`official` → `official`, anything
  else → `auto`), and a `generatedAt` ISO 8601 UTC timestamp. Without these
  fields the worker's `parseTranscriptUpload()` rejects every upload, so
  client-side fetch results never populated the R2 cache. See
  [docs/features/transcript.md](docs/features/transcript.md) and
  [specs/013-client-yt-transcripts/contracts/worker-cache-api.md](specs/013-client-yt-transcripts/contracts/worker-cache-api.md).
- **`fetchClientProfiles()` now reads the worker's `profiles` envelope (#319)**.
  The client previously called `getJsonList()`, which threw on any
  non-array body; the worker actually returns `{"version", "profiles"}`.
  The client now calls `getJson()` and extracts the `profiles` list
  defensively, so `YoutubeCaptionFetcher` reaches the published client
  profiles instead of always falling back to built-in defaults.
- **Removed the dead poll-based YouTube transcript client API and the
  outdated spec 008 worker contract (#320)**. The worker has retired
  `POST /youtube/transcripts` as a poll/generate endpoint in favor of a
  cache-only contract; the legacy `pollTranscript` / `pollTranscripts`
  methods on `YoutubeTranscriptsClient` were never called by any
  production code (`TranscriptRepository` only uses `getCachedTranscript`
  and `uploadTranscript`) and are now deleted along with their unit
  tests. The 008 contract doc
  (`specs/008-youtube-bilingual-captions/contracts/youtube-transcripts-api.md`)
  is removed; in-tree references are updated to
  [`specs/013-client-yt-transcripts/contracts/worker-cache-api.md`](specs/013-client-yt-transcripts/contracts/worker-cache-api.md)
  and the same contract is now documented as the source of truth in
  [ADR-0036](docs/decisions/0036-youtube-bilingual-transcripts.md).
  `docs/features/transcript.md` is updated to describe the supported
  cache + profile endpoints rather than the retired poll path.

- **Lookup source precedence is now chrome-first**: transcript dictionary
  lookup resolves the source language from the video (chrome) language first,
  falling back to the active track language, and only then to the learning
  language — replacing the old "first sibling transcript track" heuristic. The
  pure helper `resolveLookupSourceLanguage({chromeLanguage, activeTrackLanguage})`
  is covered by 6 unit tests. See
  [ADR-0019](docs/decisions/0019-transcript-dictionary-lookup.md),
  [ADR-0042](docs/decisions/0042-multi-language-lookup-catalog.md), and
  [docs/features/dictionary-lookup.md](docs/features/dictionary-lookup.md#default-source).
- **Auto-translate keyed by primary text, not time match**: AI auto-translate
  tracks are now aligned via an index overlay plus a `sourceKey` content
  fingerprint (`normalize(plain(primary.text)) | workerLang(src) | workerLang(tgt)`),
  so a neighbor cue is no longer attached when timings are tight, and an edited
  cue no longer keeps a stale translation. See
  [ADR-0039](docs/decisions/0039-auto-translate-primary-text-keyed-overlay.md)
  and [docs/features/transcript.md](docs/features/transcript.md#auto-translate).
- **i18n: localize remaining hardcoded user-facing strings**: removed
  hidden-English hotkey fallbacks, localized shadow-reading captions and the
  file-not-found reason, replaced raw `Text('$error')` dumps with
  `errorGenericLoadFailed`, added the `authOtpInputSemantics` OTP a11y label,
  filled the missing `subtitlesRegenerate` zh translation. See
  [docs/features/auth.md](docs/features/auth.md),
  [docs/features/transcript.md](docs/features/transcript.md),
  [docs/features/shadow-reading.md](docs/features/shadow-reading.md),
  [docs/features/hotkeys.md](docs/features/hotkeys.md), and
  [docs/conventions.md](docs/conventions.md).

## [0.4.0] - 2026-07-09

### Added

- Wiki documentation template at `.github/agentic-wiki/PAGES.md` consumed by the
  `agentic-wiki-writer` workflow. Includes page outlines for Home, Getting
  Started, Architecture, Player, Transcripts, Library, Sync, Auth, Settings,
  Release & CI, Local Packages, and an index page for AI coding agents.
- Google Sign-In configuration files (`google-services.json` /
  `GoogleService-Info.plist`) flipped from `REPLACE_WITH_*` placeholders to
  shipped defaults; the Web application client ID is referenced from
  `kGoogleWebClientId` in `lib/features/auth/domain/google_auth_config.dart`.
- `macos/Runner/ReleaseDirect.entitlements` — separate entitlements file for
  Developer ID direct-download builds (sandbox + network + app keychain
  group, **without** `com.apple.developer.applesignin`, which is unsupported
  on Developer ID distribution).
- Dicebear SVG avatar URLs are rewritten to PNG before being handed to
  Flutter image decoders, fixing black/missing avatars in the community
  activity card, account hero, and profile sidebar.

### Changed

- Database is now strictly sign-in gated — guest rekey imports and the
  signed-out library fallback were removed in `35a2a57`. `guestAppDatabaseProvider`
  was renamed to `deviceGlobalAppDatabaseProvider` so `enjoy_player.sqlite` is
  clearly device-global settings (not a guest library). See
  [ADR-0012](docs/decisions/0012-per-user-sqlite-isolation.md) and
  [ADR-0031](docs/decisions/0031-login-only-access.md).
- macOS local/Xcode builds no longer reference `com.apple.developer.applesignin`
  (the capability is unsupported on Developer ID distribution and breaks
  provisioning on macOS). iOS still ships with the entitlement on all
  Runner configurations; macOS Direct builds use `ReleaseDirect.entitlements`
  via `notarize_release.sh`.
- `release.ps1` `--notarize` is now auto-enabled when `--publish` builds a
  macOS zip, so direct-download publish flows no longer need to pass it
  explicitly.
- `--norsrc` was added to the macOS zip `ditto` invocation in the Apple
  release CI to omit AppleDouble entries that broke framework seals when
  unzipping downstream.

### Fixed

- **Landing page store buttons**: iOS TestFlight and Android Play beta cards now stay visible when their URLs are unset in `landing/config.js`, rendering a disabled "Coming soon" button (`btn--disabled`, `aria-disabled="true"`) instead of dropping the cards or shipping a broken link. See [docs/packaging.md](docs/packaging.md#updating-store-links) and [ADR-0024](docs/decisions/0024-download-landing-page.md).
- **macOS keychain cold-start (`-34018`)**: `keychain-access-groups` was
  empty, which broke `flutter_secure_storage` in local debug builds and
  trapped the app in an auth retry loop. The app's own keychain group
  (`$(AppIdentifierPrefix)$(CFBundleIdentifier)`) is now set on Debug,
  Profile, Release, and ReleaseDirect entitlements. See
  [docs/features/auth.md](docs/features/auth.md).
- **macOS Developer ID direct-download launch (`error 163`)**: Sign in with
  Apple entitlements are unsupported on Developer ID builds; switching to
  `ReleaseDirect.entitlements` and repacking from a stapled app before
  publish unblocks notarized direct downloads on macOS 26.
- **Apple Sign-In entitlements** on iOS and macOS: `ios/Runner/Runner.entitlements`
  now ships `com.apple.developer.applesignin` referenced from all Runner
  build configurations (`CODE_SIGN_ENTITLEMENTS`) so physical devices no
  longer surface `AuthorizationError error 1000` before the API call.
- **Auth cold-start resilience**: keychain and transient network failures
  during startup are now treated as signed-out (`AuthSignedOut`) instead
  of fatal errors. `AuthCtrl.handleAuthCallbackUri` also catches any
  non-`AuthFailure` error from the token exchange and resets state, so
  the sign-in hub is no longer trapped on the "waiting for browser" pane.
- **Apple release test gate**: macOS Info.plist and Runner entitlements are
  now consistent across local Xcode and notarized release flows, so the
  release Apple workflow no longer gets blocked on missing plist keys.
- **Apple CI on self-hosted mac runners**: `.github/actions/setup-flutter`
  now installs CocoaPods and the iOS toolchain on the self-hosted mac
  runner so `build_apple.yml` and `release_apple.yml` can run end-to-end
  without manual `pod install`.
- **Skipped-frame skeleton crash**: skeleton list placeholders no longer
  crash inside nested scroll views when the parent scroll view computes
  a negative scroll offset during initial layout.
- **Drift `ADD COLUMN` migrations are now idempotent**: `_addColumnIfMissing`
  short-circuits when the column already exists, so downgrading and
  re-upgrading the schema no longer hangs the database open.
- **Blank-window hang after a failed migration**: combined with the
  idempotent ADD COLUMN fix above, the database opens even when the on-disk
  schema includes columns added by a newer build.
- **Local DB recovery paths**: `RecoverySurface` and `performRecoveryReset`
  now point at the correct per-user / device-global database files and
  the in-place reset flow is wired into the recovery UI for the user that
  needs it (with a downgrade-safe migration test). See
  [docs/features/local-database-recovery.md](docs/features/local-database-recovery.md).
- **`TranscriptRepository.watchTracks` re-emissions**: identical watch
  emissions are now deduped with `Stream.distinctBy(_listEqualsTranscriptTrack)`
  so the always-mounted transport bar stops rebuilding on no-op Drift
  ticks (#208). Mirrors the same fix already applied to `watchLines`.
- **Apple Info.plist placeholder URL scheme** is now a valid reversed host
  format (`com.googleusercontent.apps.REPLACE_WITH_CLIENT_ID`) so iOS
  bundle validation stops rejecting the binary before Google Sign-In
  configuration can be completed.

### Security

- Sign in with Apple entitlement is no longer included in the macOS
  ReleaseDirect entitlements (unsupported on Developer ID distribution);
  this narrows the entitlement set for direct-download macOS builds.

## [0.3.1] - 2026-07-03

### Added

- `findSliverIndexByPrefixedId<T>` in `lib/core/utils/sliver_key_index.dart` — shared `findChildIndexCallback` lookup for sliver grids/lists keyed by a `"$prefix${id}"` `ValueKey<String>`.
- `ArtworkPalette` now has value-equality on its four `Color` fields so `Map<ArtworkPalette, ...>` use sites and `==` checks behave like data classes. `@visibleForTesting` cache seams on `lib/core/theme/dynamic_color/artwork_palette.dart`: `debugResetArtworkPaletteCache`, `debugArtworkPaletteCacheSize`, `debugArtworkPaletteCacheContainsPath`, `debugLookupArtworkPalette`, `debugPutArtworkPalette`. 12 tests in `test/core/theme/artwork_palette_test.dart` cover the new invalidation contract.

### Changed

- Home recents grid, discover merged feed grid, and channel feed grid use stable per-row `ValueKey`s + `findChildIndexCallback` so a Drift re-emit or RSS refresh no longer rebuilds every visible tile.
- **Artwork palette LRU cache key**: switched from thumbnail path alone to `(path, size, mtime)`. The in-process LRU in `extractArtworkPalette` re-`stat`s the file on every lookup and evicts any prior entry for the same path whose `(size, mtime)` no longer matches the live stat. LRU cap stays at 32 entries. ADR-0007 updated to describe the new key shape and invalidation contract.

### Fixed

- Documented the `POST /youtube/transcripts` polling contract (request body, attempt/delay budget, `forceRefresh` semantics, and outcome handling) — no behavior change, closes a docs gap between `YoutubeTranscriptsApi` and `docs/features/transcript.md`.
- **Artwork palette stale-cache leak**: re-thumbnailing or rewriting the local artwork file in place used to return the cached palette for the previous bytes because the LRU key was the path string only. Keyed by `(path, size, mtime)` so a regenerate-then-reopen cycle extracts a fresh palette.
- **Windows deep links**: PKCE sign-in callbacks no longer spawn a stray second window. The installer-registered `enjoyplayer://` protocol previously launched a fresh `enjoy_player.exe` per click; that process had no in-memory PKCE state, so the original window was stuck waiting and a second window was left open. `windows/runner/main.cpp` now detects an already-running instance via `FindWindow(L"FLUTTER_RUNNER_WIN32_WINDOW", L"Enjoy Player")`, forwards the URI to it through `app_links`'s `SendAppLink` (`WM_COPYDATA`), restores/foregrounds that window, and exits. See [docs/features/auth.md](docs/features/auth.md#deep-links-pkce-callback).

## [0.3.0] - 2026-07-01

### Added

- NotFoundScreen fallback route for unknown go_router locations (en/zh/zh-CN localized).
- GitHub issue templates (`bug`, `feature`, `chore`) and a PR template at `.github/`.
- `PlayerEngine.supportsSubtitleDisabling` to skip the no-op `disableRenderedSubtitles` await on YouTube opens.
- `kPositionBucketSessionEmitMs`, `kPositionBucketDisplayMs`, `kPositionBucketScrubberMs` constants in `lib/features/player/application/position_buckets.dart` consolidating three previously inline quantization values.
- `SyncMissingUpdatedAtError` thrown by `SyncUploadService` when the server omits `updatedAt`, preserving local `serverUpdatedAt` instead of silently bumping it to `DateTime.now()`.
- Redesigned **Settings** hub with search, a two-pane layout, and default-collapsed sections; inline Account profile card in the two-pane layout.
- Developer contact bottom sheet from the About section.

### Changed

- `lib/main.dart` wraps the entire bootstrap in `runZonedGuarded` and installs `FlutterError.onError` + `PlatformDispatcher.instance.onError` so framework errors are routed through the diagnostic log pipeline instead of crashing silently.
- `PlayerController.openMedia` catches exceptions from `engine.open` and downstream awaits so a failed open no longer leaves `state` pointing at a phantom session.
- `PlayerController.clear()` flushes the pending `PlaybackSessionPersister` write before cancelling, so swipe-to-dismiss no longer loses the last 450 ms of position updates.
- `YoutubePlayerEngine._emitBuffering(false)` only bumps `mountTick` on the first buffering→false transition per open, reducing ad-reload flicker.
- `_userSessionDatabases` in `app_database_provider.dart` is a bounded `LinkedHashMap` (cap = 2) — oldest entry is closed before inserting a new one.
- `SecureTokenStore` now pins `AndroidOptions()` (v10 RSA-OAEP / AES-GCM with auto-migration from legacy ciphers) and `IOSOptions(accessibility: KeychainAccessibility.first_unlock)`.
- `EmailEntryScreen` BackButton always calls `cancelSignIn()` (it was previously gated on `AuthAwaitingOtp`).
- `_EnjoyAppState.build` uses `ref.listen` to mirror `appPreferencesCtrlProvider` into `_lastResolvedPrefs` via `setState` instead of writing the field as a build-time side effect.

### Fixed

- `VideoPosterCaptureService` seek-zero restore failures now log at warning level (was a nested empty `catch` that swallowed real errors).
- Drift `transcript_fetch_states` missing index — see follow-up.
- Auth deep-link stream subscription now stored + cancelled in `dispose()`; `getInitialLink()` has an `onError` handler.
- `YoutubePlayerEngine.idleAfterClear()` removed a dead branch where `_videoId.isNotEmpty` was checked after `_videoId = ''`.
- Two `kIsWeb` branches removed from `log_file_sink.dart` and `practice_poster_export.dart` per AGENTS.md hard rule.
- Library empty state now shows insight cards alongside the empty-state illustration on the home screen.

### Security

- ADR-0028 accepted: agentic workflows route inference through the MiniMax proxy with CI egress allow-list checks; zero-retention posture pending annual re-verification (medium risk).

## [0.2.3] - 2026-06-24

### Fixed

- YouTube player WebView: unblock Windows release playback (CDN subresource navigation policy).
- YouTube player WebView: harden cross-platform playback recovery after renderer crashes and stalls.

## [0.2.2] - 2026-06-23

### Added

- Local production diagnostics logging and zip export.

### Changed

- YouTube player: poster overlay and warm WebView on init.

### Fixed

- Echo-mode transcript autoscroll crashes without losing scroll accuracy.
- YouTube player WebView: block Google sign-in navigations that interrupt playback.
- Windows debug: silence `accessibility_bridge` AXTree console spam.

## [0.2.1] - 2026-06-16

### Added

- Public download landing page at [get.enjoy.bot](https://get.enjoy.bot) with platform detection, i18n, and feature showcase.
- Cloudflare Pages deploy workflow for the landing site.
- Discover UI tests (horizontal drag scroll, subscription actions).

### Changed

- Discover subscribe sheet: keyboard handling, state management, and layout improvements.
- Discover: horizontal drag scroll behavior; clearer subscription error handling.
- Android: flavor handling docs and build config; JNI merge cache workaround.

### Fixed

- Release publish pipeline: pubspec-versioned artifacts, per-platform `latest.json` overwrites, and macOS release fixes.

## [0.2.0] - 2026-06-10

### Added

- **Discover** tab: browse recommended YouTube channels, subscribe locally, and import videos from a merged upload feed.
- **Unified Library** navigation: Local and Cloud media in one shell tab (`/library?source=cloud`).
- **OTA updates**: in-app update prompts with platform feeds on `dl.enjoy.bot` (Android, iOS, macOS Sparkle, Windows WinSparkle).
- Transcript **recording counts** per line; hotkey **settings** screen and global focus policy.
- **Mobile transport** line navigation for narrow player layouts.
- Signed-in **Home**: today's practice goal and community activity cards.

### Changed

- Library search with `/` hotkey; improved media card thumbnails and YouTube artwork handling.
- Release tooling: shared local/CI scripts, R2 publish pipeline, and local-first packaging docs.

## [0.1.0] - 2026-05-22

First public beta.

### Added

- Initial MVP scaffold: feature-first layout, Drift schema, media_kit player, Riverpod providers, go_router shell with mini player, transcript import (SRT/VTT), echo mode parity with web `echo-utils`.
- Documentation system: AGENTS.md, ADRs, feature specs, Cursor rules.
