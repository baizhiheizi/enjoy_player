import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:enjoy_player/core/webview/webview_environment_gate.dart';

class _FakeWebViewEnvironment implements WebViewEnvironment {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  testWidgets('builds nothing until the environment future resolves', (
    tester,
  ) async {
    final completer = Completer<WebViewEnvironment?>();
    var builderCalls = 0;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: WebViewEnvironmentGate(
          environmentFuture: completer.future,
          builder: (context, environment) {
            builderCalls++;
            return Text('built environment=${environment == null}');
          },
        ),
      ),
    );

    expect(find.byType(SizedBox), findsOneWidget);
    expect(builderCalls, 0);

    completer.complete(null);
    await tester.pumpAndSettle();

    expect(builderCalls, 1);
    expect(find.text('built environment=true'), findsOneWidget);
  });

  testWidgets(
    'shows the supplied placeholder while the environment future is pending',
    (tester) async {
      final completer = Completer<WebViewEnvironment?>();
      var builderCalls = 0;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: WebViewEnvironmentGate(
            environmentFuture: completer.future,
            placeholder: const Text('pending'),
            builder: (context, environment) {
              builderCalls++;
              return const Text('ready');
            },
          ),
        ),
      );

      expect(find.text('pending'), findsOneWidget);
      expect(builderCalls, 0);

      completer.complete(null);
      await tester.pumpAndSettle();

      expect(find.text('ready'), findsOneWidget);
      expect(find.text('pending'), findsNothing);
    },
  );

  testWidgets('hands the resolved environment to the builder', (tester) async {
    final environment = _FakeWebViewEnvironment();
    final completer = Completer<WebViewEnvironment?>();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: WebViewEnvironmentGate(
          environmentFuture: completer.future,
          builder: (context, resolved) =>
              Text('same=${identical(resolved, environment)}'),
        ),
      ),
    );

    completer.complete(environment);
    await tester.pumpAndSettle();

    expect(find.text('same=true'), findsOneWidget);
  });

  testWidgets(
    'builds with a null environment when creation failed (fallback parity)',
    (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: WebViewEnvironmentGate(
            environmentFuture: Future<WebViewEnvironment?>.value(null),
            builder: (context, environment) =>
                Text('fallback=${environment == null}'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('fallback=true'), findsOneWidget);
    },
  );

  testWidgets(
    'default future resolves to null off Windows without stalling the gate',
    (tester) async {
      final previous = PathProviderPlatform.instance;
      PathProviderPlatform.instance = _ThrowingPathProviderPlatform();
      addTearDown(() => PathProviderPlatform.instance = previous);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: WebViewEnvironmentGate(
            builder: (context, environment) =>
                Text('resolved=${environment == null}'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('resolved=true'), findsOneWidget);
    },
  );
}

class _ThrowingPathProviderPlatform extends PathProviderPlatform {
  @override
  Future<String?> getApplicationSupportPath() async {
    throw StateError('test seam: no support directory in widget tests');
  }
}
