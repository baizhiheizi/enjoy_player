/// Off-UI-thread existence check for a media item's local thumbnail.
library;

import 'dart:io' show File;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/utils/local_thumbnail.dart';
import 'package:enjoy_player/core/utils/remote_thumbnail_url.dart';

/// Resolves the thumbnail file for a stored thumbnail path.
///
/// Accepts any stored path — remote `http(s)` artwork URLs resolve to `null`
/// without a stat. Keyed on the path (one path per media item) so a stage
/// that rebuilds — the player loading stage rebuilds on every open resolve,
/// library / home cards rebuild on every scroll — stats the filesystem once
/// instead of on every build, and does it off the UI thread
/// ([resolveLocalThumbnailFile], issue #663; grid-tile call sites, #810 E3).
///
/// Auto-dispose on purpose: a poster can be captured *after* an open that
/// found none ([VideoPosterCaptureService]), so a negative answer must not
/// outlive the screen that asked for it.
final localThumbnailFileProvider = FutureProvider.autoDispose
    .family<File?, String?>((ref, path) {
      return resolveLocalThumbnailFile(localThumbnailPathForCard(path));
    });
