/// Linear stages of the Craft Express flow.
///
/// The controller tracks [CraftJobState.stage] to drive which widget
/// the `ExpressFlow` orchestrator shows.
library;

/// Current position in the Express capture → rewrite → audio pipeline.
enum CraftStage {
  /// Mic button / text entry — the user records their thought.
  capture,

  /// Raw transcript + editable target-language text + style chip.
  rewrite,

  /// Preview player + voice chip + save / loop / practice actions.
  audio,

  /// Transient state after save (before reset or navigate).
  done,
}
