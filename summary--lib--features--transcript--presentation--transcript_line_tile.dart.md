<hash>size:13447</hash>

# `lib/features/transcript/presentation/transcript_line_tile.dart`

- Exports `TranscriptLineTile`, a `ConsumerStatefulWidget` for one timed cue.
- Supports ordinary seek taps, selectable active/echo cues, dictionary selection callbacks, recording badges, and inline secondary-track refresh.
- Reads transcript blur and reveal providers; hover or a timed tap reveal unmasks cue text while blur practice is active.
- Uses `TranscriptDensity` for vertical spacing and `EnjoyThemeTokens.transcriptLinePadding` for horizontal padding.
- Renders active/echo background states, an optional 3 px active rail, localized semantics, and bordered secondary text.
