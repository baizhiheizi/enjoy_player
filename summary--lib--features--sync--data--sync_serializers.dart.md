<hash>size:9969</hash>

# `lib/features/sync/data/sync_serializers.dart`

- Converts local audio, video, recording, and YouTube subscription rows to wire maps.
- Parses server entities and ISO dates.
- Last-write-wins merge keeps local URI/path fields and lets server timestamps win ties.
- Recording time fields are normalized as milliseconds.
