/// Player video + transcript arrangement predicate (aspect-based).
///
/// See ADR-0059 and
/// `specs/026-orientation-layout-polish/contracts/player-content-layout.md`.
library;

/// Whether the player should show video and transcript **side-by-side**.
///
/// Landscape (`width > height`) → side-by-side. Portrait and square
/// (`height >= width`) → stacked. Callers MUST pass live layout constraints
/// (e.g. from a LayoutBuilder), not a fixed width breakpoint.
bool usePlayerSideBySideLayout({
  required double width,
  required double height,
}) {
  return width > height;
}
