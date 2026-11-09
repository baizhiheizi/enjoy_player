import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enjoy_player/core/presentation/loading_icon.dart';
import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/features/craft/presentation/widgets/craft_busy_label.dart';
import 'package:enjoy_player/features/craft/presentation/widgets/craft_paste_text_field.dart';
import 'package:enjoy_player/l10n/app_localizations.dart';

Widget _harness(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CraftPasteTextField', () {
    testWidgets('renders label, hint, and paste button', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _harness(
          CraftPasteTextField(
            controller: controller,
            labelText: 'Label',
            hintText: 'Hint',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Label'), findsOneWidget);
      expect(find.text('Hint'), findsOneWidget);
      expect(find.byIcon(EnjoyIcons.paste), findsOneWidget);
    });

    testWidgets('pastes clipboard text and notifies onChanged', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.getData') {
            return const <String, dynamic>{'text': 'pasted content'};
          }
          return null;
        },
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        );
      });

      String? changedText;
      await tester.pumpWidget(
        _harness(
          CraftPasteTextField(
            controller: controller,
            labelText: 'Label',
            onChanged: (val) => changedText = val,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(EnjoyIcons.paste));
      await tester.pumpAndSettle();

      expect(controller.text, 'pasted content');
      expect(changedText, 'pasted content');
    });

    testWidgets('safely handles unmount during pending paste', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      final completer = Completer<Map<String, dynamic>>();
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.getData') {
            return completer.future;
          }
          return null;
        },
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        );
      });

      var changed = false;
      await tester.pumpWidget(
        _harness(
          CraftPasteTextField(
            controller: controller,
            labelText: 'Label',
            onChanged: (_) => changed = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(EnjoyIcons.paste));
      await tester.pump();

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      completer.complete(const <String, dynamic>{'text': 'delayed'});
      await tester.pumpAndSettle();

      expect(changed, isFalse);
      expect(controller.text, isEmpty);
    });
  });

  group('CraftBusyLabel', () {
    testWidgets('renders LoadingIcon and label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: CraftBusyLabel(label: 'Loading…')),
        ),
      );
      await tester.pump();

      expect(find.byType(LoadingIcon), findsOneWidget);
      expect(find.text('Loading…'), findsOneWidget);
    });
  });
}
