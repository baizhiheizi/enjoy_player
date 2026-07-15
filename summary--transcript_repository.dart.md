<hash>size:39985</hash>

# `lib/features/transcript/data/transcript_repository.dart`

- `watchTracks` maps and source-sorts Drift rows, then deduplicates value-equal track lists.
- `linesForRow` memoizes timeline decoding by transcript ID and timeline hash.
- YouTube resolution uses Worker cache first when language is known, then direct InnerTube discovery of all tracks and Worker cache upload.
- Primary selection preserves user choice, then prefers video language, learning language, and source priority.
