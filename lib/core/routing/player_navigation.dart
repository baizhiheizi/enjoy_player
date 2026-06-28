/// Helpers for opening the expanded player without stacking player platform views.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Opens the expanded player for [mediaId].
///
/// When the user is already on `/player/:id`, [GoRouter.replace] swaps the
/// route in place so only one player platform view exists (critical for
/// Windows YouTube WebView — see ADR-0015 and [ExpandedPlayerScreen] page key).
///
/// From shell tabs (Discover, Library, …) we [GoRouter.push] so back returns
/// to the originating screen. Bottom navigation uses [GoRouter.go] elsewhere,
/// which resets the stack to a single shell route — that path never stacks
/// player routes.
void openPlayerRoute(BuildContext context, String mediaId) {
  final location = '/player/$mediaId';
  final currentPath = GoRouterState.of(context).uri.path;
  if (currentPath.startsWith('/player/')) {
    context.replace(location);
  } else {
    unawaited(context.push(location));
  }
}

/// [Hero] tag for library/transport artwork continuity into the player shell.
String mediaArtworkHeroTag(String mediaId) => 'media-art-$mediaId';
