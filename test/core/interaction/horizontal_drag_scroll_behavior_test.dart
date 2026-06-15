import 'package:enjoy_player/core/interaction/horizontal_drag_scroll_behavior.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HorizontalDragScrollBehavior', () {
    test('enables drag scrolling for touch, mouse, trackpad, and stylus', () {
      const behavior = HorizontalDragScrollBehavior();

      expect(
        behavior.dragDevices,
        equals(const {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
          PointerDeviceKind.stylus,
        }),
      );
    });
  });
}
