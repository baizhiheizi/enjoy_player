/// Route guards and focus orchestration for library search (`/` hotkey).
library;

import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:enjoy_player/core/routing/app_router.dart';
import 'package:enjoy_player/core/routing/library_source.dart';
import 'library_search_focus_provider.dart';

/// Whether [library.search] (`/`) should be handled on [path].
///
/// Enabled on RootShell browse routes; disabled on player and auth-only flows.
bool librarySearchHotkeyEnabledForPath(String path) {
  if (path.startsWith('/player/')) return false;
  if (path.startsWith('/sign-in')) return false;
  if (path.startsWith('/youtube/login')) return false;
  return true;
}

/// Navigates to Library when search is activated from another shell route.
void ensureLibraryRouteForSearch(GoRouter router) {
  final uri = router.state.uri;
  if (!uri.path.startsWith('/library') ||
      librarySourceFromUri(uri) == LibrarySource.cloud) {
    router.go(libraryRouteForSource(LibrarySource.local));
  }
}

/// Hotkey handler: go to Library (if needed), then pulse focus request.
void requestLibrarySearchFocus(WidgetRef ref) {
  final router = ref.read(appRouterProvider);
  final path = router.state.uri.path;
  if (!librarySearchHotkeyEnabledForPath(path)) return;

  ensureLibraryRouteForSearch(router);

  SchedulerBinding.instance.scheduleFrameCallback((_) {
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      ref.read(librarySearchFocusRequestProvider.notifier).pulse();
    });
  });
}
