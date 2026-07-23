/// Top-level screen mode for the Craft route.
///
/// `express` — voice-first linear flow (default): capture → rewrite → audio.
/// `advanced` — two-tool panel layout (Translate + Synthesize).
library;

/// Which UI layout the Craft screen shows.
enum CraftScreenMode {
  /// Voice-first linear flow (default).
  express,

  /// Two-tool panel layout for prepared text.
  advanced,
}
