/// Phone/tablet platform predicate — mirrors [isDesktop] in
/// `lib/core/window/desktop_window.dart`.
library;

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

/// Whether the current platform is a phone/tablet form factor (iOS or
/// Android), as opposed to desktop or web.
///
/// Also used as the "does this device support [HapticFeedback]?" check —
/// today the two questions have the same answer on every supported platform.
bool get isMobilePlatform =>
    defaultTargetPlatform == TargetPlatform.iOS ||
    defaultTargetPlatform == TargetPlatform.android;
