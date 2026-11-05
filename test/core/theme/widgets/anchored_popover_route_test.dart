import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/core/theme/widgets/anchored_popover_route.dart';

const Key _contentKey = ValueKey<String>('popover-content');

void main() {
  Future<void> push(
    WidgetTester tester,
    AnchoredPopoverRoute<void> route,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(route),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Widget content() => const SizedBox(key: _contentKey, width: 200, height: 100);

  testWidgets('anchors the child to the requested edge with insets', (
    tester,
  ) async {
    await push(
      tester,
      AnchoredPopoverRoute<void>(
        barrierLabel: 'More',
        alignment: Alignment.topRight,
        insets: (context) => const EdgeInsets.only(top: 56, right: 14),
        builder: (context) => content(),
      ),
    );

    expect(find.byKey(_contentKey), findsOneWidget);

    final align = tester.widget<Align>(
      find
          .ancestor(of: find.byKey(_contentKey), matching: find.byType(Align))
          .first,
    );
    expect(align.alignment, Alignment.topRight);

    final padding = tester.widget<Padding>(
      find
          .ancestor(of: find.byKey(_contentKey), matching: find.byType(Padding))
          .first,
    );
    expect(padding.padding, const EdgeInsets.only(top: 56, right: 14));
  });

  testWidgets('dismisses when the barrier is tapped', (tester) async {
    await push(
      tester,
      AnchoredPopoverRoute<void>(
        barrierLabel: 'Subtitles and display',
        builder: (context) => content(),
      ),
    );

    expect(find.byKey(_contentKey), findsOneWidget);

    await tester.tapAt(const Offset(10, 300));
    await tester.pumpAndSettle();
    expect(find.byKey(_contentKey), findsNothing);
  });

  testWidgets('keeps the slide out when no offset is given', (tester) async {
    await push(
      tester,
      AnchoredPopoverRoute<void>(
        barrierLabel: 'More',
        builder: (context) => content(),
      ),
    );

    expect(
      find.ancestor(
        of: find.byKey(_contentKey),
        matching: find.byType(SlideTransition),
      ),
      findsNothing,
    );
    expect(
      find.ancestor(
        of: find.byKey(_contentKey),
        matching: find.byType(FadeTransition),
      ),
      findsOneWidget,
    );
  });

  testWidgets('slides from the given offset', (tester) async {
    await push(
      tester,
      AnchoredPopoverRoute<void>(
        barrierLabel: 'Margin',
        alignment: Alignment.centerRight,
        slideOffset: const Offset(1, 0),
        slideCurve: Curves.easeOutCubic,
        builder: (context) => content(),
      ),
    );

    expect(
      find.ancestor(
        of: find.byKey(_contentKey),
        matching: find.byType(SlideTransition),
      ),
      findsOneWidget,
    );
    expect(
      find.ancestor(
        of: find.byKey(_contentKey),
        matching: find.byType(FadeTransition),
      ),
      findsOneWidget,
    );
  });
}
