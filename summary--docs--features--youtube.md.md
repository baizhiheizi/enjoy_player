<hash>size:11863</hash>

# `docs/features/youtube.md`

- YouTube playback uses the mobile watch page in `flutter_inappwebview`, not `media_kit`.
- Metadata is imported via oEmbed and completed lazily.
- Captions use Worker cache, direct InnerTube all-track discovery, and Worker cache upload.
- Documents login separation, navigation policy, platform behavior, and buffering safeguards.
