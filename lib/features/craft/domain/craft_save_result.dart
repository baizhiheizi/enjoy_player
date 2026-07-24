/// Outcome of a successful Craft [saveToLibrary] call.
library;

import 'package:flutter/foundation.dart';

@immutable
class CraftSaveResult {
  const CraftSaveResult({
    required this.mediaId,
    required this.wroteSolidTranscript,
    this.wasDedupe = false,
  });

  /// Library media id (new, updated, or existing on dedupe).
  final String mediaId;

  /// True when this save persisted a solid AI timeline (not blank, not dedupe).
  final bool wroteSolidTranscript;

  /// True when save short-circuited to an existing identical Craft item.
  final bool wasDedupe;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CraftSaveResult &&
        other.mediaId == mediaId &&
        other.wroteSolidTranscript == wroteSolidTranscript &&
        other.wasDedupe == wasDedupe;
  }

  @override
  int get hashCode => Object.hash(mediaId, wroteSolidTranscript, wasDedupe);
}
