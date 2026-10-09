# ADR-0087: Norwegian Bokmål (nb-NO) as a learning / media / lookup language

## Status

Accepted

## Context

`#786` proposed adding Norwegian to Enjoy Player; `#787` recorded the code
audit and the concrete change list. The player ships three independent language
catalogs in [`lib/core/application/app_language_catalog.dart`](../../lib/core/application/app_language_catalog.dart) —
focus (learning), media (content), and lookup (source/target) — plus three
downstream mirrors that must stay consistent or a language silently half-works:

| Surface | Consequence of a missing entry |
|---|---|
| `kSupportedFocusLanguageTags` / `kSupportedMediaLanguageTags` | No Norwegian in the settings pickers; library badges fall back to the raw tag |
| `kSupportedLookupLanguageTags` | No Norwegian source/target in the dictionary sheet |
| `kPronounceSupportedLocales` (mirrors the worker allowlist) | Pronounce control stays disabled in the lookup sheet, flashcards, and assessment results |
| `packages/forced_alignment` alignment catalog (pinned `==` to focus) | Fail-closed: karaoke word highlighting and word-level practice unavailable |
| `kAzureDefaultLocaleByPrimary` | Bare `nb` tracks fail to resolve an assessment locale |

Two cross-repo dependencies gate the client side:

1. **Worker `/pronounce`** must allowlist `nb-NO` — [baizhiheizi/enjoy#1313](https://github.com/baizhiheizi/enjoy/issues/1313) (shipped). The client mirrors this allowlist, so the **worker must deploy first**; a player release ahead of it would send `nb-NO` and receive a 400.
2. **Worker `/translations`** — m2m100 knows `no` but not `nb`, so the worker maps `nb` → `no` internally (same issue).

Rails (`enjoy_web`) needs no change: `User.learning_language` has no allowlist
and `PATCH /api/v1/profile` stores `nb-NO` verbatim. The web settings picker
being hardcoded to English is a separate parity gap
([enjoy_web#323](https://github.com/baizhiheizi/enjoy_web/issues/323)).

The `no` → `nb` decision is a **policy** choice, not a neutral alias, and is
what this ADR records.

## Decision

1. **`nb-NO` joins all three player catalogs.** Focus + media
   (`kSupportedMediaLanguageTags` derives from focus) and lookup
   (`kSupportedLookupLanguageTags`, 14 → 15 tags), with
   `kLookupLanguageLabels['nb-NO'] = 'Norsk (bokmål)'` in the endonym
   convention the other lookup labels use.
2. **`no` / `nob` / `nor` alias to `nb`** in `kLanguageTagAliases`, and
   `kAzureDefaultLocaleByPrimary['nb'] = 'nb-NO'` resolves the Azure
   pronunciation-assessment locale. Every Norwegian alias shape —
   `no`, `no-NO`, `nb`, `nb-NO`, `nob`, `nor` — therefore canonicalizes to
   `nb-NO` for focus, media, and Azure, and yields `workerLanguageBase` → `nb`.
3. **The `no` → `nb` alias is deliberate policy.** `no` is an ISO 639-1
   *macrolanguage* tag covering both written standards. Essentially all
   Norwegian content in the wild is Bokmål, so treating every bare `no` as
   Bokmål is right far more often than it is wrong.
4. **Nynorsk (`nn` / `nn-NO`) stays unsupported and is explicitly out of scope.**
   It is deliberately *not* aliased, so it survives as an unsupported tag
   rather than being silently classified as Bokmål.
5. **`focusLanguageLabel` falls back by primary subtag *after* alias
   normalization, never through `canonicalFocusLanguageTag`.** The latter
   defaults unknown primaries to `en-US`, which would mislabel a Nynorsk `nn`
   media item as "English" in the library content-language badge. Tags whose
   primary matches nothing supported keep showing the raw tag, which is the
   pre-existing behavior.
6. **Norwegian is not a native or display language.** `nn-NO` stays out of
   `kSupportedNativeLanguageTags` and `kAppDisplayLocales`.
7. **Alignment parity is a hard requirement, not optional.** The forced-alignment
   catalog is pinned `==` to the focus catalog by
   `forced_alignment_language_catalog_test.dart`, so omitting Norwegian would
   fail that test — and relaxing the pin instead would silently drop
   karaoke/word-level practice for Norwegian learners.

## eSpeak-NG vendoring (non-obvious detail)

`packages/forced_alignment/native/espeak-ng-data/` is a **trimmed** tree from
eSpeak-NG 1.52.0. Two findings from building the upstream 1.52.0 tag to
produce the missing files:

- **`phondata` / `phonindex` / `phontab` / `intonations` in the vendored tree are byte-identical to a full upstream 1.52.0 build.** They already carry every language's phoneme table, so adding a language needs **no** recompilation of the compiled tables — only the per-voice and per-dictionary files.
- **The Norwegian Bokmål dictionary is `no_dict`, not `nb_dict`.** eSpeak-NG names the *voice* `nb` but keeps the Norwegian phoneme table and dictionary under the `no` macrolanguage: the generated voice file `lang/gmq/nb` declares `phonemes no` / `dictionary no` (and `language nb` / `language no`, which is why `--voices` lists `(no 5)` under `nb`). `#787` assumed `nb_dict`; there is no such file.

The vendored tree flattens upstream's grouped layout — upstream's
`lang/gmw/en-US` becomes the vendored `lang/en-us`, so `lang/gmq/nb` was
vendored flat as `lang/nb`. `kEspeakVoiceByLanguageTag['nb-NO'] = 'nb'`; the
`voices=()` list in `.github/scripts/check_bundled_espeak_data.sh` gained `nb`
to keep the CI packaging gate in sync.

Verified by phonemizing through the vendored `libespeak-ng`:
`hei verden hvordan går det` → `hˈaɪ vˈardən vˈɔrdan ɡˈoːr dˈeː`, guarded by
the unconditional FFI test `nb-NO spoken reference can be built`.

## Consequences

- **Positive**: Norwegian learners get learning/media/lookup pickers, Azure assessment, worker pronunciation, contextual translation, and karaoke word alignment.
- **Positive**: `no`-tagged media (common from file metadata and manual imports) now classifies as Bokmål instead of displaying a raw `no` tag.
- **Negative**: Genuine Nynorsk media is classified as Bokmål. Accepted trade-off per decision 3; `nn` remains unsupported.
- **Risk (resolved 2026-10-08)**: **YouTube caption codes use `no`**, not `nb`. Post-alias the Tier-1 `preferredLang` hint sends `nb` and could miss Bokmål tracks. Resolved by the InnerTube caption-track matcher ranking exact tag first, then primary-subtag alias — so a `no` track still counts as preferred for `nb-NO` — then everything else ([`youtube_caption_fetcher.dart`](../../lib/features/transcript/data/youtube_caption_fetcher.dart), #848); this closed the #786 residual. Tier 2 still discovers all tracks regardless.
- **Negative**: ~4 KB `no_dict` + 87 B `lang/nb` added to every platform bundle (the trimmed tree is duplicated per app bundle).
- **Known gap**: `kAzureVoices` (Craft TTS) has no Norwegian entry, so Craft's voice picker shows the existing `craftNoVoicesForLanguage` state for a Norwegian target. This degrades gracefully — `_voiceMatchingLanguage` returns null rather than throwing — and is the same state as any other catalog-absent language. Out of scope here: inventing Azure voice ids without a verified provider-side name would risk 400s from TTS. Azure *pronunciation assessment* (a different surface) is fully supported.
- **Ordering constraint**: worker `#1313` must be deployed before any player release carrying this catalog.
- **Follow-up**: Nynorsk (`nn-NO`) remains a candidate for a later wave; adding it needs its own `lang/nn` voice file decision and a re-read of decision 3.

## Alternatives considered

- *Alias `nn` → `nb` as well* — rejected; that would classify Nynorsk as Bokmål silently with no way for the user to tell. Keeping `nn` unsupported surfaces the raw tag, which is honest.
- *Leave `nb-NO` out of the alignment catalog and relax the `==` pin* — rejected; alignment is a user-visible hot path (karaoke highlight, word-level practice), and the pin is what forces the two catalogs to stay in lockstep.
- *Add `nn-NO` at the same time* — rejected per `#786` scope; it doubles the eSpeak vendoring and Azure/TTS surface for a much smaller audience.
- *Coerce `no` → `en-US` instead of `nb-NO`* — rejected; it would give Norwegian learners the wrong assessment locale and wrong pronunciation.

## Artifacts

- [#787](https://github.com/baizhiheizi/enjoy_player/issues/787) — audit + implementation plan
- [baizhiheizi/enjoy#1313](https://github.com/baizhiheizi/enjoy/issues/1313) — worker `/pronounce` allowlist + m2m100 `nb` → `no`
- [baizhiheizi/enjoy_web#323](https://github.com/baizhiheizi/enjoy_web/issues/323) — web settings picker parity (separate)
- [ADR-0042](0042-multi-language-lookup-catalog.md) — lookup catalog separation this extends
- [ADR-0072](0072-spoken-alignment-reference.md) — eSpeak-NG spoken alignment reference
