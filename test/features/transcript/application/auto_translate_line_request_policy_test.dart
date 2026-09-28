// Tests for the shared auto-translate line-request policy (issue #764
// candidate 4). Before this module the two transcript item builders each owned
// a copy of "should this cue be translated now"; these cases pin the one
// definition so the copies cannot drift again.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/features/transcript/application/auto_translate_line_request_policy.dart';
import 'package:enjoy_player/features/transcript/domain/auto_translate.dart';

void main() {
  group('shouldRequestAutoTranslateLine', () {
    bool viewport({
      int lineIndex = 100,
      int anchor = 100,
      bool active = true,
      bool hasSecondary = false,
      bool failed = false,
    }) => shouldRequestAutoTranslateLine(
      lineIndex: lineIndex,
      anchorLineIndex: anchor,
      scope: AutoTranslateRequestScope.viewport,
      isAutoTranslateActive: active,
      hasSecondaryText: hasSecondary,
      isLineFailed: failed,
    );

    test('requests a cue at the anchor', () {
      expect(viewport(), isTrue);
    });

    test('requests a cue inside the viewport window', () {
      expect(viewport(lineIndex: 100 + kAutoTranslateViewportWindow), isTrue);
      expect(viewport(lineIndex: 100 - kAutoTranslateViewportWindow), isTrue);
    });

    test('skips a cue beyond the viewport window', () {
      expect(
        viewport(lineIndex: 100 + kAutoTranslateViewportWindow + 1),
        isFalse,
      );
      expect(
        viewport(lineIndex: 100 - kAutoTranslateViewportWindow - 1),
        isFalse,
      );
    });

    // The old inline check collapsed a "nothing is playing yet" highlight (-1)
    // to line 0 rather than treating the distance as 101 cues.
    test('collapses a negative anchor to line 0', () {
      expect(viewport(lineIndex: 5, anchor: -1), isTrue);
      expect(
        viewport(lineIndex: kAutoTranslateViewportWindow, anchor: -1),
        isTrue,
      );
      expect(
        viewport(lineIndex: kAutoTranslateViewportWindow + 1, anchor: -1),
        isFalse,
      );
    });

    test('honours an explicit narrower window', () {
      expect(
        shouldRequestAutoTranslateLine(
          lineIndex: 10,
          anchorLineIndex: 0,
          scope: AutoTranslateRequestScope.viewport,
          viewportWindow: 2,
          isAutoTranslateActive: true,
          hasSecondaryText: false,
          isLineFailed: false,
        ),
        isFalse,
      );
    });

    test(
      'skips when auto-translate is off, the cue is translated, or it failed',
      () {
        expect(viewport(active: false), isFalse);
        expect(viewport(hasSecondary: true), isFalse);
        expect(viewport(failed: true), isFalse);
      },
    );

    test('blank secondary text counts as untranslated', () {
      expect(viewport(hasSecondary: false), isTrue);
    });

    // The echo card's block is its own viewport: every cue in it qualifies,
    // which is why it passes scope `block` rather than widening the window.
    test('block scope ignores the anchor entirely', () {
      for (final lineIndex in [0, 50, 100000]) {
        expect(
          shouldRequestAutoTranslateLine(
            lineIndex: lineIndex,
            anchorLineIndex: -1,
            scope: AutoTranslateRequestScope.block,
            isAutoTranslateActive: true,
            hasSecondaryText: false,
            isLineFailed: false,
          ),
          isTrue,
          reason: 'line $lineIndex',
        );
      }
    });

    // Hot path: the scrollable list's builder calls this for every row, and
    // resolving the alternate anchor means reading the ScrollController. An
    // ineligible row must not pay for it.
    test('does not resolve the alternate anchor for an ineligible row', () {
      var resolved = 0;
      int resolve() {
        resolved++;
        return 0;
      }

      for (final ineligible in [
        (active: false, secondary: false, failed: false),
        (active: true, secondary: true, failed: false),
        (active: true, secondary: false, failed: true),
      ]) {
        resolved = 0;
        expect(
          shouldRequestAutoTranslateLine(
            lineIndex: 999,
            anchorLineIndex: 0,
            alternateAnchorLineIndex: resolve,
            scope: AutoTranslateRequestScope.viewport,
            isAutoTranslateActive: ineligible.active,
            hasSecondaryText: ineligible.secondary,
            isLineFailed: ineligible.failed,
          ),
          isFalse,
        );
        expect(resolved, 0, reason: 'eligibility must short-circuit');
      }
    });

    test('either anchor qualifies', () {
      var callCount = 0;
      int scrollFocus() {
        callCount++;
        return 25;
      }

      // Line 30 is 30 cues from the primary anchor (window is 24, so it misses)
      // but only 5 from the scroll focus, so the alternate qualifies.
      expect(
        shouldRequestAutoTranslateLine(
          lineIndex: 30,
          anchorLineIndex: 0,
          alternateAnchorLineIndex: scrollFocus,
          scope: AutoTranslateRequestScope.viewport,
          isAutoTranslateActive: true,
          hasSecondaryText: false,
          isLineFailed: false,
        ),
        isTrue,
      );
      expect(callCount, 1);

      // Same line with a distant scroll focus: neither anchor qualifies.
      expect(
        shouldRequestAutoTranslateLine(
          lineIndex: 30,
          anchorLineIndex: 0,
          alternateAnchorLineIndex: () => 500,
          scope: AutoTranslateRequestScope.viewport,
          isAutoTranslateActive: true,
          hasSecondaryText: false,
          isLineFailed: false,
        ),
        isFalse,
      );
    });

    test('resolves the alternate anchor only after the primary misses', () {
      var callCount = 0;
      int near() {
        callCount++;
        return 0;
      }

      expect(
        shouldRequestAutoTranslateLine(
          lineIndex: 1,
          anchorLineIndex: 0,
          alternateAnchorLineIndex: near,
          scope: AutoTranslateRequestScope.viewport,
          isAutoTranslateActive: true,
          hasSecondaryText: false,
          isLineFailed: false,
        ),
        isTrue,
      );
      expect(callCount, 0, reason: 'primary anchor already qualified');
    });

    test('block scope still respects translated / failed / inactive cues', () {
      bool block({
        bool active = true,
        bool hasSecondary = false,
        bool failed = false,
      }) => shouldRequestAutoTranslateLine(
        lineIndex: 7,
        anchorLineIndex: 0,
        scope: AutoTranslateRequestScope.block,
        isAutoTranslateActive: active,
        hasSecondaryText: hasSecondary,
        isLineFailed: failed,
      );
      expect(block(active: false), isFalse);
      expect(block(hasSecondary: true), isFalse);
      expect(block(failed: true), isFalse);
    });
  });

  // `AutomatedTestWidgetsFlutterBinding.pump` only draws a frame when something
  // is dirty, so a bare `pump()` would leave the post-frame callback queued and
  // make the "drops stale" cases below pass vacuously.
  group('scheduleAutoTranslateLineRequest', () {
    testWidgets('fires the request after the frame', (tester) async {
      var requested = 0;
      await tester.pumpWidget(const SizedBox());
      scheduleAutoTranslateLineRequest(
        isMounted: () => true,
        shouldRequest: () => true,
        request: () => requested++,
      );
      expect(requested, 0, reason: 'must not fire synchronously');
      tester.binding.scheduleFrame();
      await tester.pump();
      expect(requested, 1);
    });

    // The drift this module exists to prevent: the echo card used to fire with
    // no re-check, so a cue that left the window during the frame still got a
    // request.
    testWidgets('re-checks and drops a request that went stale', (
      tester,
    ) async {
      var requested = 0;
      var stillWanted = true;
      await tester.pumpWidget(const SizedBox());
      scheduleAutoTranslateLineRequest(
        isMounted: () => true,
        shouldRequest: () => stillWanted,
        request: () => requested++,
      );
      stillWanted = false;
      tester.binding.scheduleFrame();
      await tester.pump();
      expect(requested, 0);
    });

    // A surface that is its own viewport (the echo block) has nothing to
    // re-check, so it omits the parameter rather than passing a tautology.
    testWidgets('omitting shouldRequest always fires', (tester) async {
      var requested = 0;
      await tester.pumpWidget(const SizedBox());
      scheduleAutoTranslateLineRequest(
        isMounted: () => true,
        request: () => requested++,
      );
      tester.binding.scheduleFrame();
      await tester.pump();
      expect(requested, 1);
    });

    testWidgets('does nothing when the element is torn down mid-frame', (
      tester,
    ) async {
      var mounted = true;
      var requested = 0;
      await tester.pumpWidget(const SizedBox());
      scheduleAutoTranslateLineRequest(
        isMounted: () => mounted,
        shouldRequest: () => true,
        request: () => requested++,
      );
      mounted = false;
      tester.binding.scheduleFrame();
      await tester.pump();
      expect(requested, 0);
    });
  });
}
