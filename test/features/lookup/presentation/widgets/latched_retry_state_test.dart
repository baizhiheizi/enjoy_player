import 'package:enjoy_player/features/lookup/presentation/widgets/latched_retry_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Harness extends StatefulWidget {
  const _Harness({required this.onRetry, this.isRetrying = false});

  final VoidCallback onRetry;
  final bool isRetrying;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> with LatchedRetryState<_Harness> {
  @override
  bool get parentRetryBusy => widget.isRetrying;

  @override
  bool wasParentRetryBusy(covariant _Harness oldWidget) => oldWidget.isRetrying;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: retryBusy ? null : () => retry(widget.onRetry),
      child: Text(retryBusy ? 'busy' : 'idle'),
    );
  }
}

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(_wrap(child));
  await tester.pump();
}

void main() {
  testWidgets('a tap latches busy until the parent reports the retry', (
    tester,
  ) async {
    var taps = 0;
    await _pump(tester, _Harness(onRetry: () => taps++));

    expect(find.text('idle'), findsOneWidget);
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
    expect(taps, 1);
    expect(find.text('busy'), findsOneWidget);
  });

  testWidgets('latch persists while the parent stays idle across rebuilds', (
    tester,
  ) async {
    var taps = 0;
    Widget build() => _Harness(onRetry: () => taps++);
    await tester.pumpWidget(_wrap(build()));
    await tester.pump();
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    await tester.pumpWidget(_wrap(build()));
    await tester.pump();
    expect(find.text('busy'), findsOneWidget);

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('rising parent busy unlatches and keeps the control disabled', (
    tester,
  ) async {
    var taps = 0;
    var retrying = false;
    Widget build() => _Harness(onRetry: () => taps++, isRetrying: retrying);
    await tester.pumpWidget(_wrap(build()));
    await tester.pump();
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    retrying = true;
    await tester.pumpWidget(_wrap(build()));
    await tester.pump();
    expect(find.text('busy'), findsOneWidget);

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('falling parent busy unlatches and re-arms the control', (
    tester,
  ) async {
    var taps = 0;
    var retrying = false;
    Widget build() => _Harness(onRetry: () => taps++, isRetrying: retrying);
    await tester.pumpWidget(_wrap(build()));
    await tester.pump();
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    retrying = true;
    await tester.pumpWidget(_wrap(build()));
    await tester.pump();
    retrying = false;
    await tester.pumpWidget(_wrap(build()));
    await tester.pump();
    expect(find.text('idle'), findsOneWidget);

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
    expect(taps, 2);
  });
}
