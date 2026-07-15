<hash>size:3896</hash>

# `lib/features/transcript/application/transcript_lines_provider.dart`

- Builds primary and secondary line streams from active echo-session references.
- Watches session and transcript changes but fetches only the selected transcript row.
- Applies element-wise `TranscriptLine` list dedupe before Riverpod emits.
- Exposes a cheap transcript-exists provider without timeline decode.
