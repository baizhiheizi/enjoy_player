/// The native checkout client tag shared by every checkout request.
library;

/// Marks a checkout request as coming from the native app.
///
/// The backend turns this tag into a Stripe return URL that lands on the
/// public `enjoy.bot/checkout/return` page, which hands the user back to the
/// app through `enjoyplayer://checkout/return` — see
/// `docs/features/subscription.md`.
const String kNativeCheckoutClientTag = 'enjoy_player';
