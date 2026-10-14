/// Route paths navigated from presentation code outside the router — use
/// these instead of string literals so a rename stays a one-line change.
library;

const kCreditsRoutePath = '/credits';
const kSubscriptionRoutePath = '/subscription';

/// Push route for the transcript editor nested under the player route, so
/// playback keeps running while the learner edits (leave-player teardown
/// only fires when no `/player/` route remains).
String playerEditTranscriptRoutePath(String mediaId) =>
    '/player/$mediaId/edit-transcript';
