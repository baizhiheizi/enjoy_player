/// Small helpers for [AsyncValue] (Riverpod 3 omits older convenience getters).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

extension AsyncValueValueOrNullX<T> on AsyncValue<T> {
  T? get valueOrNull => maybeWhen(data: (v) => v, orElse: () => null);
}
