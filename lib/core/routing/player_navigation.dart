/// Helpers for opening the expanded player without stacking player platform views.
library;

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

void openPlayerRoute(BuildContext context, String mediaId) {
  final location = '/player/$mediaId';
  final currentPath = GoRouterState.of(context).uri.path;
  if (currentPath.startsWith('/player/')) {
    context.replace(location);
  } else {
    context.push(location);
  }
}
