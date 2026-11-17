/// The refresh policy of the lookup sheet sections.
///
/// A retry must be a fresh attempt, not a replay of the cached payload: the
/// cached AI result for the section's key is dropped and the section's
/// provider is invalidated, so the next read re-runs the loader.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/features/ai/application/ai_result_cache.dart';
import 'package:enjoy_player/features/ai/domain/ai_kind.dart';

void forceRefreshLookupSection<T extends Object>({
  required WidgetRef ref,
  required AiResultCache<T> cache,
  required AiKind kind,
  required String key,
  required VoidCallback invalidateProvider,
}) {
  unawaited(cache.invalidate(kind: kind, key: key));
  invalidateProvider();
}
