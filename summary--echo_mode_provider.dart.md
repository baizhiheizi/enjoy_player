<size>3797</size>

# `lib/features/player/application/echo_mode_provider.dart`

- Provider glue for the **shadow reading** flow.
- Gates recording on the active transcript cue window (start/end timestamps).
- Coordinates with `record` for PCM capture and writes results to `recordings` + `echo_sessions`.
- Surfaces alignment feedback to the cue card UI in `lib/features/shadow_reading/`.
