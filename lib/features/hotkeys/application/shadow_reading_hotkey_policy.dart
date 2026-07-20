/// When global shortcuts may pulse [ShadowReadingHotkeyBus].
library;

/// Shadow-reading record / play / pitch / assess hotkeys.
///
/// Enabled during an active player session (expanded / mini player echo) or
/// vocabulary review echo practice, which is recorder-only and has no
/// [PlayerController] session.
bool shadowReadingBusHotkeysEnabled({
  required bool hasPlayerSession,
  required bool vocabularyEchoPracticeOpen,
}) {
  return hasPlayerSession || vocabularyEchoPracticeOpen;
}
