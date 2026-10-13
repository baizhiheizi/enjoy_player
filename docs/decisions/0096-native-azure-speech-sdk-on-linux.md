# ADR-0096: Native Azure Speech SDK on Linux

**Status**: Accepted (2026-10-13)

## Context

`packages/azure_speech` wraps the Microsoft Speech SDK through native plugins on Android, iOS, macOS and Windows ([ADR-0017](0017-azure-pronunciation-assessment.md)). Linux had no native plugin: `synthesize` went over the REST TTS endpoint (without word boundaries), and `assess` / `transcribe` threw `unsupported_platform`, so pronunciation assessment never worked on Linux.

The NuGet package the Windows build already pins (`Microsoft.CognitiveServices.Speech` 1.49.0) ships `runtimes/linux-x64/native` and `runtimes/linux-arm64/native` libraries plus the C/C++ headers.

## Decision

1. **Add a native Linux plugin** (`packages/azure_speech/linux/`, `pluginClass: AzureSpeechPlugin`) that implements `assess`, `transcribe` and `synthesize` with the Speech SDK C++ API. It does the same work as the Windows plugin. SDK calls run on a worker thread, and replies go back to the GLib main loop through `g_idle_add`.
2. **Same SDK source as Windows.** CMake downloads the pinned NuGet package at configure time. It picks `linux-x64` or `linux-arm64` from `CMAKE_SYSTEM_PROCESSOR`, copies `libMicrosoft.CognitiveServices.Speech.core.so` and the two OpenSSL platform shims (`libpal_azure_c_shared*.so`) next to the plugin library, and exports them as `azure_speech_bundled_libraries`. The runner installs them into `bundle/lib`, and the plugin's RUNPATH is only `$ORIGIN`. The keyword-spotting, GStreamer codec and ALSA audio-device extensions are not bundled, because WAV-file input and in-memory output don't use them.
3. **No REST fallbacks.** The Dart `AzureSpeech` class sends every call through the method channel on every platform. The REST synthesizer and the interim REST assessor are deleted.

## Consequences

- Pronunciation assessment, recognition and synthesis on Linux return the same SDK JSON as other platforms. Synthesis on Linux now reports word boundaries, and an explicit voice is no longer required.
- The first Linux configure needs network access to nuget.org, as on Windows. The download is cached in the plugin build directory.
- The SDK loads the host's OpenSSL (3.x, or 1.1) at runtime. The supported AppImage baseline distributions all ship it.
- The AppImage picks up the libraries through its existing `bundle/lib` copy and dependency walk. No packaging change was needed.
