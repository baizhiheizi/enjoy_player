// Site configuration — update store/TestFlight URLs here before each release.
// This is the only file you need to edit for link maintenance.
window.ENJOY_CONFIG = {
  bundleId: 'ai.enjoy.player',

  // Public TestFlight invitation link — set when a public beta invite is available.
  // When null, the landing page hides the iOS TestFlight card (no broken 404 link).
  testFlightUrl: null,

  // Google Play open beta test track opt-in.
  playBetaUrl: 'https://play.google.com/apps/testing/ai.enjoy.player',

  // Same-origin manifest proxy (served by the Pages Function).
  manifestUrl: '/api/latest',

  // GitHub releases page — used as JS-disabled fallback for direct downloads.
  releasesUrl: 'https://github.com/an-lee/enjoy_player/releases/latest',

  githubUrl: 'https://github.com/an-lee/enjoy_player',
};
