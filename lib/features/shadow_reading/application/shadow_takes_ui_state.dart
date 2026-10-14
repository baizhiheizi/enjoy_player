/// Presentation state shared by the takes row under the Echo loop and the
/// takes list (margin on desktop, sheet on phones): which take is selected
/// and whether the loop's pitch contour is shown.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'shadow_takes_ui_state.g.dart';

/// The selected take's id; null means "the latest take".
@Riverpod(keepAlive: true)
class SelectedTake extends _$SelectedTake {
  @override
  String? build() => null;

  void select(String? id) {
    if (state != id) state = id;
  }
}

@Riverpod(keepAlive: true)
class LoopPitchVisible extends _$LoopPitchVisible {
  @override
  bool build() => false;

  void toggle() => state = !state;

  void hide() {
    if (state) state = false;
  }
}
