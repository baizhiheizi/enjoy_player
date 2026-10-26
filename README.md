<p align="right">
  <b>English</b> · <a href="README.zh-CN.md">简体中文</a>
</p>

<h1 align="center">
  <img src="landing/logo.svg" alt="" width="64" height="64"><br>
  Enjoy Player
</h1>

<p align="center">
  <strong>Practice languages with media you love.</strong>
  <br>
  Open your own videos and audio, or paste a YouTube link. Follow every line, say it back, get scored — and keep the words you looked up.
</p>

<p align="center">
  <a href="https://player.enjoy.bot"><img alt="Download" src="https://img.shields.io/badge/Download-player.enjoy.bot-4F46E5?style=for-the-badge"></a>
  <a href="https://github.com/baizhiheizi/enjoy_player/releases/latest"><img alt="Latest release" src="https://img.shields.io/github/v/release/baizhiheizi/enjoy_player?style=for-the-badge&color=7C3AED"></a>
  <a href="LICENSE"><img alt="License" src="https://img.shields.io/badge/license-AGPL--3.0-12141A?style=for-the-badge"></a>
</p>

<p align="center">
  <a href="https://player.enjoy.bot"><img src="assets/readme/showcase.png" alt="Enjoy Player on desktop and phone: the looped line with IPA and translation, a pronunciation score of 84, and the vocabulary book" width="900"></a>
</p>

<p align="center">
  <a href="landing/videos/enjoy-player-film.en.mp4"><b>▶ Watch the 15-second film</b></a> · <a href="https://player.enjoy.bot">player.enjoy.bot</a>
</p>

---

## The practice loop

Every line of your media, three ways through it. Switch any time — the line stays where you are.

| | |
| --- | --- |
| 🔵 **Listen** | Every line in time with your media. Tap to seek, loop a line, slow it down, and read the translation and IPA when you need them. |
| 🟣 **Echo** | Shadow one line at a time. Record over the original, replay both, compare the pitch, and get a score for every take. |
| 🟣 **Dictate** | Hide the text. Words turn into shapes, so you listen first — then hover or hold a line to peek and check yourself. |

## See it in action

<table>
  <tr>
    <td align="center" width="25%"><img src="assets/store/android_phone_screenshot_1.jpg" alt="Home: continue practising, today's goal and the community" width="220"></td>
    <td align="center" width="25%"><img src="assets/store/android_phone_screenshot_2.jpg" alt="Echo: the looped line with its translation and your latest take" width="220"></td>
    <td align="center" width="25%"><img src="assets/store/android_phone_screenshot_3.jpg" alt="Pronunciation assessment: overall 84 with accuracy, completeness, fluency and prosody" width="220"></td>
    <td align="center" width="25%"><img src="assets/store/android_phone_screenshot_4.jpg" alt="Vocabulary: words due today, progress by status and every saved word with its context" width="220"></td>
  </tr>
  <tr>
    <td align="center"><b>Pick up where you left off</b><br><sub>Today's goal · Community</sub></td>
    <td align="center"><b>Say it back</b><br><sub>Loop · Record · Compare</sub></td>
    <td align="center"><b>Feedback down to the sound</b><br><sub>Four dimensions · Every word</sub></td>
    <td align="center"><b>Keep the words</b><br><sub>Context · Spaced review</sub></td>
  </tr>
</table>

<p align="center">
  <img src="assets/store/macos_player_screenshot.png" alt="Enjoy Player on macOS: Echo on the looped line, with IPA over every word and the Chinese translation underneath" width="900">
</p>

<p align="center"><sub><b>One library, every device you own.</b> Native on Windows, macOS, Linux, iPhone, iPad and Android.</sub></p>

---

## Features

- **Interactive transcripts** — `.srt` / `.vtt` imports, YouTube captions, or AI transcription aligned line by line. Tap a line to seek; select a word to look it up. Per-line translations and IPA when you want them.
- **Echo (shadow reading)** — Line-bounded loops that pause and rewind at the end of the line, so you can drill it without breaking flow. Every take is kept.
- **Pronunciation assessment** — Azure speech scoring per take: overall, accuracy, completeness, fluency and prosody, with per-word detail and your pitch contour laid over the original's.
- **Dictate** — Every line's text becomes shape bars (`H`); listen first, then hover or press-and-hold a line to peek.
- **Lookup in context** — Translation, a dictionary entry, and an AI explanation of what the phrase means in this scene, in 15 lookup languages.
- **Spaced-repetition vocabulary** — Three-button flashcards on an SM-2 schedule, several contexts per word, Anki CSV export on paid plans.
- **Craft** — Say or type something in your own language; Craft rewrites it the way a native speaker would, reads it aloud, and sends it to the player to shadow.
- **YouTube** — Paste a link and play, with captions fetched and rendered as an interactive transcript.
- **Practice poster** — Turn a take into a 9:16 poster (cover frame, the line, your score) and share it.
- **Sync** — Library, progress, recordings, vocabulary and settings follow your Enjoy account across devices.

---

## Get it

The download page puts the right installer for your device first: **[player.enjoy.bot](https://player.enjoy.bot)**

| Platform | Requirements | Get it |
| --- | --- | --- |
| **Windows** | Windows 10 / 11 · x64 | [Installer (.exe)](https://player.enjoy.bot/#download) |
| **macOS** | macOS 12+ · Apple silicon & Intel · notarized | [Disk image (.dmg)](https://player.enjoy.bot/#download) |
| **Linux** | Ubuntu 22.04+ · x86_64 | [AppImage](https://player.enjoy.bot/#download) |
| **Android** | Android 8.0+ · phone & tablet | [APK](https://player.enjoy.bot/#download) |
| **iPhone & iPad** | iOS 15+ | [TestFlight beta](https://testflight.apple.com/join/6x7kkr3e) |

The player and every practice mode are free; paid plans add more daily Enjoy AI credits. Flutter web is intentionally not supported.

Releases and changelog: **[github.com/baizhiheizi/enjoy_player/releases](https://github.com/baizhiheizi/enjoy_player/releases)**

---

## Built with

- **Player** — [media_kit](https://pub.dev/packages/media_kit) on a single shared engine ([ADR-0003](docs/decisions/0003-player-core-media-kit.md))
- **State** — [Riverpod 3](https://pub.dev/packages/flutter_riverpod) + `riverpod_annotation`
- **Storage** — [Drift](https://pub.dev/packages/drift) (SQLite) for every persisted byte
- **Speech** — Azure pronunciation assessment + native FFmpeg pitch analysis
- **Design** — the Duet design language ([ADR-0093](docs/decisions/0093-duet-design-language.md), [docs/design/duet/](docs/design/duet/README.md))
- **Architecture** — [docs/architecture.md](docs/architecture.md); decisions in [docs/decisions/](docs/decisions/)

---

## Build from source

```bash
flutter pub get
dart run build_runner build   # after Drift / Riverpod annotation changes
flutter run
```

Platform toolchain notes: macOS needs Xcode + CocoaPods + `brew bundle install --file=macos/Brewfile`; Windows needs the NuGet CLI on `PATH` for `flutter_inappwebview`; Linux needs `clang cmake ninja-build libgtk-3-dev libsqlite3-dev ffmpeg` plus the WPE WebKit dev packages for the YouTube playback plugin (`libwpewebkit-2.0-dev libwpe-1.0-1 libwpebackend-fdo-1.0-dev` on Ubuntu, `wpewebkit libwpe wpebackend-fdo` on Arch — see [docs/features/linux-platform.md](docs/features/linux-platform.md)). Full release prerequisites: [docs/packaging.md](docs/packaging.md). CI gates and agent rules: [AGENTS.md](AGENTS.md).

The screenshots above and in `assets/store/` are rendered from the app itself — see [docs/features/landing.md § Screenshots and film](docs/features/landing.md#screenshots-and-film).

---

## License

Released under the [GNU Affero General Public License v3.0](LICENSE) (AGPL-3.0). You can read it, fork it, build on it, and even run a modified copy — as long as anyone you serve over the network gets the corresponding source. See [LICENSE](LICENSE) for the full text.
